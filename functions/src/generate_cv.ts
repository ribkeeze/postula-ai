import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { getTodayKey } from "./utils/date";
import { sanitizeJobText } from "./utils/sanitize";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
const CV_PROMPT = fs.readFileSync(path.join(__dirname, "../modes/cv_es.md"), "utf-8");
const FREE_CV_LIMIT = 1;

function detectLanguage(text: string): "es" | "en" {
  const englishWords = ["experience", "required", "skills", "responsibilities", "requirements", "position", "role", "team", "company", "job"];
  const lowerText = text.toLowerCase();
  const englishCount = englishWords.filter((w) => lowerText.includes(w)).length;
  return englishCount >= 3 ? "en" : "es";
}

export const generateCv = onCall(
  { region: "southamerica-east1", invoker: "public", timeoutSeconds: 60, memory: "256MiB" },
  async (request) => {
    try {
    if (!request.auth) throw new HttpsError("unauthenticated", "Se requiere autenticación.");

    const { evaluationId } = request.data as { evaluationId: string };
    const userId = request.auth.uid;
    const db = admin.firestore();

    // Verificar plan y uso
    const subDoc = await db.collection("subscriptions").doc(userId).get();
    const isPremium = subDoc.data()?.plan === "premium" && subDoc.data()?.expiresAt?.toDate() > new Date();

    if (!isPremium) {
      const todayKey = getTodayKey();
      const usageDoc = await db.collection("usage").doc(userId).collection("daily").doc(todayKey).get();
      const cvCount = usageDoc.data()?.cvGenerated || 0;
      if (cvCount >= FREE_CV_LIMIT) {
        throw new HttpsError("resource-exhausted", "Límite diario de CV alcanzado.");
      }
    }

    // Obtener evaluación y perfil
    const [evalDoc, profileDoc] = await Promise.all([
      db.collection("evaluations").doc(evaluationId).get(),
      db.collection("profiles").doc(userId).get(),
    ]);

    if (!evalDoc.exists) throw new HttpsError("not-found", "Evaluación no encontrada.");
    if (!profileDoc.exists) throw new HttpsError("not-found", "Perfil no encontrado.");

    const evalData = evalDoc.data()!;
    const profile = profileDoc.data()!;

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      systemInstruction: CV_PROMPT,
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 3000,
        responseMimeType: "application/json",
        // @ts-ignore — thinkingConfig no está en los tipos del SDK aún
        thinkingConfig: { thinkingBudget: 0 },
      },
    });

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

    const sanitizedJobText = sanitizeJobText(evalData.rawJobText || "");
    const jobLanguage = detectLanguage(sanitizedJobText);
    const languageInstruction = jobLanguage === "en"
      ? "IMPORTANT: The job offer is in English. Generate the entire CV in English — summary, bullets, section content, skills. Do not mix languages."
      : "IMPORTANTE: La oferta está en español. Generá el CV completo en español. No mezcles idiomas.";

    const userPrompt = `${languageInstruction}

## PERFIL DEL CANDIDATO
Nombre: ${pi.fullName}
Ubicación: ${formatLocation(pi)}
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

## EVALUACION DE LA OFERTA
Puesto: ${evalData.jobTitle}
Empresa: ${evalData.company}
Keywords identificadas: ${(evalData.keywords || []).join(", ")}
Oferta original: ${sanitizedJobText.substring(0, 2000)}

Genera el CV personalizado en el formato JSON especificado.
`;

    let responseText: string;
    try {
      const result = await model.generateContent(userPrompt);
      responseText = result.response.text();
    } catch (e: any) {
      const is429 = e?.status === 429 || e?.message?.includes("429");
      if (is429) throw new HttpsError("resource-exhausted", "El servicio de IA está ocupado. Esperá unos segundos y volvé a intentar.");
      console.error("Gemini error (generateCv):", e);
      throw new HttpsError("internal", "Error al generar el CV con IA.");
    }

    let cvData: any;
    try {
      cvData = JSON.parse(responseText);
    } catch {
      console.error("JSON parse error (generateCv). Length:", responseText?.length);
      throw new HttpsError("internal", "Error al procesar la respuesta de IA. Intentá de nuevo.");
    }

    // Incrementar contador de uso
    const todayKey = getTodayKey();
    const usageRef = db.collection("usage").doc(userId).collection("daily").doc(todayKey);
    try {
      await db.runTransaction(async (t) => {
        const usageDoc = await t.get(usageRef);
        const current = usageDoc.data() || {};
        t.set(usageRef, { ...current, date: todayKey, cvGenerated: (current.cvGenerated || 0) + 1 });
      });
    } catch (e: any) {
      console.error("Firestore transaction error (generateCv):", e);
      throw new HttpsError("internal", "Error al registrar el uso. Intentá de nuevo.");
    }

    // Save to Firestore cache so the app can load it without regenerating
    try {
      await db.collection('cvs').doc(evaluationId).set({
        ...cvData,
        evaluationId,
        userId,
        language: jobLanguage,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e: any) {
      console.error("Firestore set error (generateCv):", e);
      throw new HttpsError("internal", "Error al guardar el CV. Intentá de nuevo.");
    }

    return cvData;
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    console.error("Unhandled error (generateCv):", error);
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
    const refs = e.references?.length
      ? `\n  Referencias: ${e.references.map((r: any) =>
          `${r.name} (${r.position} en ${r.company})${r.phone ? " - " + r.phone : ""}${r.email ? " - " + r.email : ""}`
        ).join("; ")}`
      : "";
    return `- ${e.position} en ${e.company} (${period})${desc}${refs}`;
  }).join("\n");
}

function formatEducation(education: any[]): string {
  if (!education?.length) return "Sin educación registrada";
  return education.map((e: any) => {
    const period = `${e.startYear} - ${e.isOngoing ? "En curso" : e.endYear}`;
    const hasValidField = e.field &&
      e.field.trim() !== "" &&
      e.field.toLowerCase() !== e.degree.toLowerCase() &&
      !e.degree.toLowerCase().includes(e.field.toLowerCase());
    const fieldStr = hasValidField ? ` (${e.field})` : "";
    return `- ${e.degree}${fieldStr} — ${e.institution} (${period})`;
  }).join("\n");
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

