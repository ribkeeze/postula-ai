# Decisiones de Arquitectura — PostulaAI

## ADR-001: Firebase como backend

**Decisión:** Usar Firebase (Auth + Firestore + Functions + Storage) como backend completo.

**Por qué:**
- Cero costo inicial con el free tier (Spark plan → Blaze pay-as-you-go cuando escale)
- Sin servidor que mantener — crítico para un dev solo
- Firestore tiene SDK Flutter de primera clase con streams reactivos
- Cloud Functions permiten centralizar las API keys de IA server-side
- Firebase Auth resuelve login Google/email en horas, no días

**Tradeoffs aceptados:**
- Vendor lock-in con Google. Aceptado para MVP — si la app escala, migrar a Supabase o backend propio es posible pero requiere trabajo.
- Cold starts en Cloud Functions (2-5 segundos). Mitigado usando `southamerica-east1` (región más cercana) y minimum instances = 0 (costo cero cuando no se usa).

---

## ADR-002: Gemini Flash como modelo de IA por defecto

**Decisión:** Usar `gemini-1.5-flash` (o `gemini-2.0-flash` cuando esté disponible) para todas las llamadas de IA.

**Por qué:**
- Free tier: 1500 requests/día en Google AI Studio
- 1M tokens de contexto — suficiente para perfil + oferta + instrucciones
- Latencia aceptable para la UX (~10-15 segundos por evaluación)
- Fácil de cambiar a Claude o DeepSeek con un cambio de variable en Cloud Functions

**Tradeoffs aceptados:**
- No es el modelo más potente. Para evaluaciones y generación de CV, Flash es suficiente.
- Dependencia de Google AI Studio para el free tier. Si Google cambia los límites, se puede mover a Vertex AI o cambiar de modelo.

**Nota para cambiar de modelo:** Solo modificar `evaluate.ts` / `generate_cv.ts` / `coach.ts`. Los prompts en `modes/` son agnósticos al modelo.

---

## ADR-003: Prompts en archivos Markdown separados

**Decisión:** Los system prompts de IA viven en `modes/*.md`, leídos por Cloud Functions en deploy time.

**Por qué (idéntico a career-ops):**
- Los prompts son fáciles de editar sin tocar código TypeScript
- Se pueden versionar, revisar y mejorar independientemente del código
- Claude Code / OpenCode / Gemini CLI pueden editar los prompts como parte del workflow de dev
- Cualquier modelo puede leerlos y actuar sobre ellos

**Importante:** Las funciones leen los archivos con `fs.readFileSync` al inicializar el módulo (no por request). Esto significa que un cambio en `modes/` requiere redeploy de las funciones.

---

## ADR-004: Feature-first en lugar de layer-first

**Decisión:** `lib/features/profile/`, `lib/features/evaluation/`, etc. — no `lib/data/`, `lib/domain/`, `lib/presentation/`.

**Por qué:**
- Un feature es una unidad de trabajo completa. Es más fácil trabajar en "evaluation" como unidad que saltar entre 3 carpetas.
- Los agentes de IA navegan mejor: "implementá el feature de evaluación" → el agente va a `lib/features/evaluation/` y encuentra todo.
- Escala mejor: agregar un feature nuevo no requiere tocar múltiples carpetas raíz.

---

## ADR-005: Riverpod para estado global

**Decisión:** Riverpod con code generation (`@riverpod`) para todo el estado de la app.

**Por qué:**
- Type-safe, sin strings mágicos
- Compatible con Clean Architecture (los providers son la capa de presentación)
- `AsyncNotifier` maneja loading/error/data naturalmente con `AsyncValue`
- Testeable con `ProviderContainer` sin Flutter

**Convención:** Todos los providers usan `@riverpod` annotation. Los providers de larga vida (perfil del usuario) usan `@Riverpod(keepAlive: true)`.

---

## ADR-006: PDF generado en Flutter, no en el servidor

**Decisión:** El PDF del CV se genera client-side con el paquete `pdf` de Flutter.

**Por qué:**
- Evita el costo y complejidad de generar PDFs en Cloud Functions (puppeteer/playwright en serverless es caro y lento)
- El paquete `pdf` de Flutter es maduro y produce PDFs de calidad
- El template del CV se puede diseñar y mantener en Dart

**Tradeoff:** El diseño del CV está en el cliente. Si se quiere cambiar el template, hay que actualizar la app. Aceptado para MVP.

---

## ADR-007: Mínimo una entrada por pantalla en el onboarding

**Decisión:** El onboarding está dividido en pasos cortos (máximo 3 campos por paso).

**Por qué:** El target de usuarios incluye personas mayores o sin experiencia digital. Un formulario largo con 15 campos es abrumador y genera abandono. Pasos cortos dan sensación de progreso y son más manejables.

**Implementación:** `OnboardingScreen` usa `PageView` con `PageController`. El progreso se guarda en Firestore después de cada paso para no perder datos si el usuario sale.

---

## Decisiones pendientes para V2

- **Monetización:** Freemium (N evaluaciones gratis, luego suscripción mensual en ARS) vs. donación. A definir cuando haya usuarios reales.
- **Portal scanner:** Integrar búsqueda de ofertas en Bumeran, ZonaJobs, LinkedIn. Requiere Playwright en Cloud Functions (costo) o scraping client-side (complejo). A evaluar en V2.
- **Tema oscuro:** Implementar en V1.5 cuando la UX base esté estable.
- **Backend alternativo:** Si Firebase se vuelve costoso, migrar a Supabase (similar API, más barato a escala).
