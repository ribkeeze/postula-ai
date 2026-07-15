---
name: functions-postulai
description: Firebase Cloud Functions development for PostulaAI. Use when modifying TypeScript Cloud Functions, updating AI prompts in modes/ folder, fixing function errors, deploying functions, updating Gemini model config, or working with evaluate.ts, generate_cv.ts, coach.ts files.
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, MultiEdit
model: inherit
---

# PostulaAI Cloud Functions Skill

## Project Context
Cloud Functions in TypeScript at functions/src/.
Region: southamerica-east1
AI Model: gemini-3.1-flash-lite
AI Prompts: modes/*.md files (never hardcode prompts in .ts files)

## Functions
- evaluate.ts → evaluateJob — evaluates job fit
- generate_cv.ts → generateCv — generates CV, caches in cvs/{evaluationId}
- coach.ts → prepareCoach — interview prep, caches in coachSessions/{evaluationId}
- index.ts → exports all + cleanupOldUsage scheduled function

## Error Handling Pattern (ALL functions must follow)
```typescript
} catch (error: any) {
  if (error instanceof HttpsError) throw error;
  const is429 = error?.status === 429 || error?.message?.includes('429');
  if (is429) throw new HttpsError('unavailable', 'AI_BUSY');
  console.error('Unhandled error:', error);
  throw new HttpsError('internal', error?.message || 'Error inesperado.');
}
```

## Gemini Model Config (ALL functions)
```typescript
const model = genAI.getGenerativeModel({
  model: "gemini-3.1-flash-lite",
  systemInstruction: PROMPT,
  generationConfig: {
    temperature: 0.3,
    maxOutputTokens: 3000,
    responseMimeType: "application/json",
  },
});
```

## After Any Change
```bash
cd functions && npm run build && firebase deploy --only functions
```

## Firestore Collections
- evaluations/ applications/ cvs/ coachSessions/ profiles/ subscriptions/ usage/

## Free Tier Limits
- evaluations: 3/day, cvGenerated: 1/day, coachSessions: 3/day
- Check before calling Gemini, increment after in transaction
- Premium users skip limit check
