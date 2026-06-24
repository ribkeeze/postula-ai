import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { getTodayKey } from "./utils/date";
import { sanitizeJobText } from "./utils/sanitize";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
const COACH_PROMPT = fs.readFileSync(path.join(__dirname, "../modes/coach_es.md"), "utf-8");
const FREE_COACH_LIMIT = 3;

export const prepareCoach = onCall(
  { region: "southamerica-east1", invoker: "public", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    try {
    if (!request.auth) throw new HttpsError("unauthenticated", "Se requiere autenticación.");

    const { evaluationId } = request.data as { evaluationId: string };
    const userId = request.auth.uid;
    const db = admin.firestore();

    const subDoc = await db.collection("subscriptions").doc(userId).get();
    const isPremium = subDoc.data()?.plan === "premium" && subDoc.data()?.expiresAt?.toDate() > new Date();

    if (!isPremium) {
      const todayKey = getTodayKey();
      const usageDoc = await db.collection("usage").doc(userId).collection("daily").doc(todayKey).get();
      const coachCount = usageDoc.data()?.coachSessions || 0;
      if (coachCount >= FREE_COACH_LIMIT) {
        throw new HttpsError("resource-exhausted", "Límite diario de sesiones de coach alcanzado.");
      }
    }

    const [evalDoc, profileDoc] = await Promise.all([
      db.collection("evaluations").doc(evaluationId).get(),
      db.collection("profiles").doc(userId).get(),
    ]);

    if (!evalDoc.exists) throw new HttpsError("not-found", "Evaluación no encontrada.");

    const evalData = evalDoc.data()!;
    const profile = profileDoc.data() || {};

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      systemInstruction: COACH_PROMPT,
      generationConfig: {
        temperature: 0.5,
        maxOutputTokens: 2000,
        responseMimeType: "application/json",
        // @ts-ignore — thinkingConfig no está en los tipos del SDK aún
        thinkingConfig: { thinkingBudget: 0 },
      },
    });

    const sanitizedJobText = sanitizeJobText(evalData.rawJobText || "");

    const pi = profile.personalInfo || {};
    const modalities = (pi.preferredModalities || []).join(", ") || "No especificado";
    const salary = pi.expectedSalaryAmount
      ? `${pi.expectedSalaryAmount} ${pi.expectedSalaryCurrency}${pi.salaryNegotiable ? " (negociable)" : ""}`
      : "No especificado";
    const links = [
      pi.linkedInUrl ? `LinkedIn: ${pi.linkedInUrl}` : "",
      pi.githubUrl ? `GitHub: ${pi.githubUrl}` : "",
      pi.portfolioUrl ? `Portfolio: ${pi.portfolioUrl}` : "",
    ].filter(Boolean).join("\n");

    const userPrompt = `
## PERFIL DEL CANDIDATO
Nombre: ${pi.fullName}
Ubicacion: ${formatLocation(pi)}
Email: ${pi.email}
${pi.phone ? `Telefono: ${pi.phone}` : ""}
${links ? `\n${links}` : ""}

### Experiencia Laboral
${formatExperience(profile.workExperience)}

### Educacion
${formatEducation(profile.education)}

### Habilidades
${(profile.skills || []).join(", ")}

### Idiomas
${formatLanguages(profile.languages)}

### Certificaciones
${formatCertifications(profile.certifications)}

### Proyectos Destacados
${formatProjects(profile.projects)}

### Preferencias Laborales
Modalidades preferidas: ${modalities}
Pretension salarial: ${salary}
${pi.excludedIndustries?.length ? `Industrias a evitar: ${pi.excludedIndustries.join(", ")}` : ""}
${pi.excludedCompanies?.length ? `Empresas a evitar: ${pi.excludedCompanies.join(", ")}` : ""}

## OFERTA A LA QUE APLICA
Puesto: ${evalData.jobTitle}
Empresa: ${evalData.company}
Texto: ${sanitizedJobText.substring(0, 2000)}

## EVALUACION (contexto)
Score: ${evalData.score}/5
Fortalezas: ${(evalData.strengths || []).join(", ")}
Brechas: ${(evalData.gaps || []).join(", ")}

Genera la preparacion para la entrevista en el formato JSON especificado.
`;

    let responseText: string;
    try {
      const result = await model.generateContent(userPrompt);
      responseText = result.response.text();
    } catch (e: any) {
      const is429 = e?.status === 429 || e?.message?.includes("429");
      if (is429) throw new HttpsError("resource-exhausted", "El servicio de IA está ocupado. Esperá unos segundos y volvé a intentar.");
      console.error("Gemini error (prepareCoach):", e);
      throw new HttpsError("internal", "Error al preparar el coach con IA.");
    }

    let coachData: any;
    try {
      coachData = JSON.parse(responseText);
    } catch {
      console.error("JSON parse error (prepareCoach). Length:", responseText?.length);
      throw new HttpsError("internal", "Error al procesar la respuesta de IA. Intentá de nuevo.");
    }

    // Guardar en Firestore para cache
    try {
      await db.collection('coachSessions').doc(evaluationId).set({
        userId,
        evaluationId,
        ...coachData,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e: any) {
      console.error("Firestore set error (prepareCoach):", e);
      throw new HttpsError("internal", "Error al guardar la sesión. Intentá de nuevo.");
    }

    // Incrementar contador
    const todayKey = getTodayKey();
    const usageRef = db.collection("usage").doc(userId).collection("daily").doc(todayKey);
    try {
      await db.runTransaction(async (t) => {
        const usageDoc = await t.get(usageRef);
        const current = usageDoc.data() || {};
        t.set(usageRef, { ...current, date: todayKey, coachSessions: (current.coachSessions || 0) + 1 });
      });
    } catch (e: any) {
      console.error("Firestore transaction error (prepareCoach):", e);
      throw new HttpsError("internal", "Error al registrar el uso. Intentá de nuevo.");
    }

    return coachData;
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    console.error("Unhandled error (prepareCoach):", error);
    throw new HttpsError("internal", error?.message || "Error inesperado.");
  }
});

function formatCertifications(certifications: any[]): string {
  if (!certifications?.length) return "Ninguna";
  return certifications.map((c: any) => {
    const url = c.url ? ` - ${c.url}` : "";
    return `- ${c.name} (${c.issuer}, ${c.year})${url}`;
  }).join("\n");
}

function formatProjects(projects: any[]): string {
  if (!projects?.length) return "Ninguno";
  return projects.map((p: any) => {
    const period = p.period ? ` (${p.period})` : (p.startDate ? ` (${p.startDate}${p.isCurrent ? " - Actualidad" : p.endDate ? " - " + p.endDate : ""})` : "");
    const context = p.context ? ` [${p.context}]` : "";
    const techs = p.technologies?.length ? `\n  Tecnologias: ${p.technologies.join(", ")}` : "";
    const url = p.url ? `\n  URL: ${p.url}` : "";
    const desc = p.description ? `\n  ${p.description}` : "";
    return `- ${p.name}${context}${period}${desc}${techs}${url}`;
  }).join("\n");
}

function formatExperience(experiences: any[]): string {
  if (!experiences?.length) return "Sin experiencia registrada";
  return experiences.map((e: any) => {
    const period = `${e.startDate} - ${e.isCurrent ? "Actualidad" : e.endDate}`;
    const desc = e.description ? `\n  Descripcion: ${e.description}` : "";
    return `- ${e.position} en ${e.company} (${period})${desc}`;
  }).join("\n");
}

function formatEducation(education: any[]): string {
  if (!education?.length) return "Sin educación registrada";
  return education
    .map(
      (e: any) =>
        `- ${e.degree} en ${e.field} — ${e.institution} (${e.startYear} - ${
          e.isOngoing ? "En curso" : e.endYear
        })`
    )
    .join("\n");
}

function formatLanguages(languages: any[]): string {
  if (!languages?.length) return "No especificado";
  return languages.map((l: any) => `${l.name} (${l.level})`).join(", ");
}

function formatLocation(personalInfo: any): string {
  if (!personalInfo) return "No especificado";
  const parts: string[] = [];
  if (personalInfo.city) parts.push(personalInfo.city);
  if (personalInfo.provincia) {
    if (personalInfo.postalCode) {
      parts.push(`${personalInfo.provincia} CP ${personalInfo.postalCode}`);
    } else {
      parts.push(personalInfo.provincia);
    }
  }
  if (personalInfo.country) parts.push(personalInfo.country);
  return parts.length > 0 ? parts.join(", ") : "No especificado";
}

