import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { getTodayKey } from "./utils/date";
import { sanitizeJobText } from "./utils/sanitize";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

const EVALUATE_PROMPT = fs.readFileSync(
  path.join(__dirname, "../modes/evaluate_es.md"),
  "utf-8"
);

const FREE_LIMITS = {
  evaluations: 3,
  cvGenerated: 1,
  coachSessions: 3,
};

interface EvaluateRequest {
  jobText: string;
}

interface EvaluationResult {
  jobTitle: string;
  company: string;
  score: number;
  recommendation: "apply" | "consider" | "skip";
  strengths: string[];
  gaps: string[];
  summary: string;
  keywords: string[];
}

async function callGeminiWithRetry(
  model: any,
  prompt: string,
  retries = 3
): Promise<string> {
  for (let i = 0; i < retries; i++) {
    try {
      const result = await model.generateContent(prompt);
      return result.response.text();
    } catch (e: any) {
      const is429 = e?.status === 429 || e?.message?.includes("429");
      if (is429 && i < retries - 1) {
        const wait = (i + 1) * 15000; // 15s luego 30s
        console.log(`Gemini 429 — esperando ${wait / 1000}s antes de reintentar...`);
        await new Promise((res) => setTimeout(res, wait));
        continue;
      }
      throw e;
    }
  }
  throw new Error("Max retries reached");
}

export const evaluateJob = onCall(
  {
    region: "southamerica-east1",
    invoker: "public",
    timeoutSeconds: 60, // aumentado para dar tiempo a los retries
    memory: "256MiB",
  },
  async (request) => {
    try {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Se requiere autenticación.");
    }

    const { jobText: rawJobText } = request.data as EvaluateRequest;

    if (!rawJobText || rawJobText.trim().length < 100) {
      throw new HttpsError(
        "invalid-argument",
        "El texto de la oferta es muy corto."
      );
    }

    const jobText = sanitizeJobText(rawJobText);

    const userId = request.auth.uid;
    const db = admin.firestore();

    // ── 1. Verificar plan y uso ──────────────────────────────────────────────
    const subDoc = await db.collection("subscriptions").doc(userId).get();
    const subData = subDoc.data();
    const isPremium =
      subData?.plan === "premium" &&
      subData?.expiresAt?.toDate() > new Date();

    if (!isPremium) {
      const todayKey = getTodayKey();
      const usageRef = db
        .collection("usage")
        .doc(userId)
        .collection("daily")
        .doc(todayKey);

      const usageDoc = await usageRef.get();
      const usageData = usageDoc.data() || { evaluations: 0 };
      const currentCount = usageData.evaluations || 0;

      console.log(`Usage check — userId: ${userId}, todayKey: ${todayKey}, currentCount: ${currentCount}, exists: ${usageDoc.exists}`);

      if (currentCount >= FREE_LIMITS.evaluations) {
        throw new HttpsError(
          "resource-exhausted",
          `Límite diario alcanzado. Tenés ${FREE_LIMITS.evaluations} evaluaciones gratuitas por día. Activá Premium para continuar.`
        );
      }
    }

    // ── 2. Obtener perfil ────────────────────────────────────────────────────
    const profileDoc = await db.collection("profiles").doc(userId).get();

    if (!profileDoc.exists) {
      throw new HttpsError(
        "not-found",
        "Perfil no encontrado. Completá tu perfil primero."
      );
    }

    const profile = profileDoc.data();

    // ── 3. Llamar a Gemini con retry ─────────────────────────────────────────
    // const model = genAI.getGenerativeModel({
    //   model: "gemini-2.5-flash", // gemini-2.0-flash no disponible en free tier southamerica
    //   systemInstruction: EVALUATE_PROMPT,
    //   generationConfig: {
    //     temperature: 0.3,
    //     maxOutputTokens: 3000,
    //     responseMimeType: "application/json",
    //   },
    // });
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
      systemInstruction: EVALUATE_PROMPT,
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens: 3000,
        responseMimeType: "application/json",
        // @ts-ignore — thinkingConfig no está en los tipos del SDK aún
        thinkingConfig: { thinkingBudget: 0 },
      },
    });

    const userPrompt = buildUserPrompt(profile, jobText);

    let responseText: string;
    try {
      responseText = await callGeminiWithRetry(model, userPrompt);
    } catch (e: any) {
      const is429 = e?.status === 429 || e?.message?.includes("429");
      if (is429) {
        throw new HttpsError(
          "resource-exhausted",
          "El servicio de IA está ocupado. Esperá unos segundos y volvé a intentar."
        );
      }
      console.error("Gemini error:", e);
      throw new HttpsError("internal", "Error al procesar la oferta con IA.");
    }

    let evaluation: EvaluationResult;
    try {
      // Limpiar backticks de markdown que Gemini a veces agrega
      const clean = responseText
        .replace(/^```json\s*/i, '')
        .replace(/^```\s*/i, '')
        .replace(/```\s*$/i, '')
        .trim();
      evaluation = JSON.parse(clean);
    } catch {
      console.error("JSON parse error (evaluateJob). Length:", responseText?.length);
      throw new HttpsError("internal", "Error al procesar la respuesta de IA. Intentá de nuevo.");
    }

    // ── 4. Transacción: incrementar uso + guardar resultado ──────────────────
    const evaluationId = db.collection("evaluations").doc().id;
    const todayKey = getTodayKey();

    try {
      await db.runTransaction(async (transaction) => {
        const usageRef = db
          .collection("usage")
          .doc(userId)
          .collection("daily")
          .doc(todayKey);

        const usageDoc = await transaction.get(usageRef);
        const currentUsage = usageDoc.data() || { evaluations: 0 };

        transaction.set(usageRef, {
          date: todayKey,
          evaluations: (currentUsage.evaluations || 0) + 1,
          cvGenerated: currentUsage.cvGenerated || 0,
          coachSessions: currentUsage.coachSessions || 0,
        });

        transaction.set(db.collection("evaluations").doc(evaluationId), {
          id: evaluationId,
          userId,
          rawJobText: jobText,
          ...evaluation,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.set(db.collection("applications").doc(evaluationId), {
          id: evaluationId,
          userId,
          evaluationId,
          jobTitle: evaluation.jobTitle,
          company: evaluation.company,
          score: evaluation.score,
          status: "interested",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    } catch (e: any) {
      console.error("Firestore transaction error (evaluateJob):", e);
      throw new HttpsError("internal", "Error al guardar la evaluación. Intentá de nuevo.");
    }

    return { evaluationId, ...evaluation };
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    console.error("Unhandled error (evaluateJob):", error);
    throw new HttpsError("internal", error?.message || "Error inesperado.");
  }
  }
);


function buildUserPrompt(profile: any, jobText: string): string {
  const pi = profile.personalInfo || {};
  const location = formatLocation(pi);
  const modalities = (pi.preferredModalities || []).join(", ") || "No especificado";
  const salary = pi.expectedSalaryAmount
    ? `${pi.expectedSalaryAmount} ${pi.expectedSalaryCurrency}${pi.salaryNegotiable ? " (negociable)" : ""}`
    : "No especificado";
  const links = [
    pi.linkedInUrl ? `LinkedIn: ${pi.linkedInUrl}` : "",
    pi.githubUrl ? `GitHub: ${pi.githubUrl}` : "",
    pi.portfolioUrl ? `Portfolio: ${pi.portfolioUrl}` : "",
  ].filter(Boolean).join("\n");

  return `
## PERFIL DEL CANDIDATO

Nombre: ${pi.fullName}
Ubicación: ${location}
${links ? `\n${links}` : ""}

### Experiencia Laboral
${formatExperience(profile.workExperience)}

### Educación
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
Pretensión salarial: ${salary}
${pi.excludedIndustries?.length ? `Industrias a evitar: ${pi.excludedIndustries.join(", ")}` : ""}
${pi.excludedCompanies?.length ? `Empresas a evitar: ${pi.excludedCompanies.join(", ")}` : ""}
${(() => {
  const excluded = [...(pi.excludedIndustries || []), ...(pi.excludedCompanies || [])];
  return excluded.length > 0
    ? `⚠️ IMPORTANTE: El candidato NO quiere trabajar en: ${excluded.join(", ")}. Si la oferta corresponde a alguna de estas categorías, marcarlo como incompatibilidad en gaps.`
    : "";
})()}

---

## OFERTA A EVALUAR

${jobText}

---

Evaluá el fit de este candidato con esta oferta y respondé en el formato JSON especificado.
`;
}

function formatCertifications(certifications: any[]): string {
  if (!certifications?.length) return "Ninguna";
  return certifications.map((c: any) => {
    const url = c.url ? ` — ${c.url}` : "";
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