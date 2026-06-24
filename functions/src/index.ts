import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getTodayKey } from "./utils/date";

// Inicializar Firebase Admin una sola vez
admin.initializeApp();

// Exportar todas las Cloud Functions
export { evaluateJob } from "./evaluate";
export { generateCv } from "./generate_cv";
export { prepareCoach } from "./coach";

export const cleanupOldUsage = onSchedule(
  { schedule: "0 9 * * *", region: "southamerica-east1" },
  async () => {
    const db = admin.firestore();
    const today = getTodayKey();

    const usageDocs = await db
      .collectionGroup("daily")
      .where("date", "<", today)
      .get();

    const batch = db.batch();
    usageDocs.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    console.log(`Deleted ${usageDocs.size} old usage documents`);
  }
);
