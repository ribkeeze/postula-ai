# Flutter AI Workflow — PostulaAI Edition

*Este documento reemplaza al flutter-ai-workflow.md genérico. Está adaptado a este proyecto.*

---

## Contexto del proyecto

PostulaAI es una app Flutter + Firebase + Gemini AI para búsqueda laboral en Argentina.
El proyecto tiene tres dominios de código:

- **Flutter** (`lib/`) — app mobile Android + iOS
- **Cloud Functions** (`functions/`) — TypeScript, llamadas a IA
- **Prompts** (`modes/`) — los archivos Markdown que definen el comportamiento de la IA

Cada uno tiene su propia disciplina de desarrollo. Este documento las cubre.

---

## Fase 1: Mes de Claude Pro — qué construir primero

### Semana 1: Infraestructura base
1. Setup Firebase (proyecto, Firestore, Auth, Functions, Storage)
2. Onboarding completo — el perfil es el corazón de toda la app; sin él nada funciona
3. CI/CD con GitHub Actions (ya en `.github/workflows/ci.yml`)
4. Primera evaluación end-to-end funcionando (aunque sea fea)

### Semana 2: Features core
1. Evaluador completo con pantalla de resultado
2. Tracker básico (lista de postulaciones guardadas)
3. Pulir UX del onboarding con usuarios reales (pedile a un familiar no técnico que lo pruebe)

### Semana 3: Features secundarios + calidad
1. Generador de CV PDF
2. Coach de entrevistas
3. Golden tests de pantallas principales
4. Tests unitarios de use cases

### Semana 4: Preparar transición al free tier
1. Correr toda la app con Gemini Flash en lugar de Pro (verificar calidad de respuestas)
2. Documentar cualquier degradación de calidad en `.ai/known-issues.md`
3. Setup OpenCode + OpenRouter para desarrollo post-Pro

---

## Task routing por modelo (este proyecto específico)

| Tarea | Modelo | Por qué |
|-------|--------|---------|
| Implementar widget nuevo | Gemini 2.5 Flash | Pattern-following, no necesita reasoning |
| Diseñar arquitectura de un feature | Gemini 2.5 Pro | Necesita ver todo el proyecto |
| Debuggear un bug de estado Riverpod | DeepSeek R1 | Reasoning chains para bugs no obvios |
| Editar un archivo `modes/*.md` | Cualquiera | Es texto plano, no código |
| Generar tests para use cases | Gemini 2.5 Flash | Volumen, pattern-following |
| Revisar Cloud Function nueva | Gemini 2.5 Pro | Necesita entender el contexto de Firebase |
| Refactor sin romper nada | Aider | Su modo diff es más seguro |
| Preguntas sobre paquetes Flutter | Gemini + Context7 MCP | Para tener versiones actualizadas |

---

## Flujos de trabajo diarios

### Nuevo feature (ej: "Compartir CV por WhatsApp")

```
1. /plan "Agregar botón de compartir CV por WhatsApp desde la pantalla de CV"
   → El agente lee AGENTS.md + la feature cv_generator existente
   → Produce: qué archivos tocar, qué paquete usar (share_plus ya está en pubspec)

2. /code "Implementar el botón de compartir según el plan"
   → Implementa en cv_preview_screen.dart

3. /test "Generar widget test para el nuevo botón de compartir"

4. flutter analyze && flutter test
```

### Debug de bug en Cloud Function

```
1. Copiar el stack trace o error de Firebase console

2. /debug "La función evaluateJob falla con este error: [error].
   El perfil del usuario sí existe en Firestore. Aquí está el código: [código]"
   → Usar DeepSeek R1 para reasoning sobre el error de TypeScript/Firebase

3. Aplicar el fix, redeploy: cd functions && npm run deploy
```

### Mejorar un prompt de IA

```
1. Identificar el problema: "La evaluación sobreestima el fit cuando el candidato
   no tiene la experiencia exacta pedida"

2. Editar modes/evaluate_es.md directamente (es texto, cualquier editor)

3. Testear manualmente con un perfil y una oferta de prueba

4. Redeploy de las functions: firebase deploy --only functions
```

### Antes de cada merge a main

```bash
flutter analyze --fatal-infos
flutter test
flutter test --update-goldens  # solo si hubo cambios de UI intencionales
```

---

## Estructura de prompts de sesión

Cuando abras Claude Code / OpenCode / Gemini CLI en este proyecto:

```
"Leé AGENTS.md y .ai/architecture.md. Luego [tarea específica]."
```

Para tareas de UI:
```
"Leé AGENTS.md. Implementá [feature] siguiendo la estructura de
lib/features/evaluation/ como referencia. Respetá las reglas de
accesibilidad (fuente mínima 16sp, touch targets 48dp)."
```

Para tareas de Cloud Functions:
```
"Leé AGENTS.md y functions/src/evaluate.ts como referencia.
Implementá [función] siguiendo el mismo patrón."
```

Para mejorar prompts:
```
"Leé modes/evaluate_es.md. El problema es: [descripción del problema].
Proponé cambios al prompt para resolverlo."
```

---

## Estrategia de costos post-Pro

### Firebase (Spark plan → Blaze cuando necesites más)
- Spark (gratis): 1GB Firestore, 10GB Storage, 2M Cloud Functions invocations/mes
- En Blaze (pay-as-you-go): $0.06/GB Firestore reads, funciones muy baratas
- Para los primeros 1000 usuarios: prácticamente gratis

### Gemini API (desde Cloud Functions)
- Google AI Studio free tier: 1500 req/día para Gemini Flash
- Cada evaluación = ~1 request = ~2000-3000 tokens ≈ $0.000something en paid
- Para <1000 usuarios: free tier es más que suficiente
- Para escalar: Vertex AI tiene pricing más predecible

### Desarrollo (tu máquina)
- Firebase Emulators: correr todo localmente sin costo durante desarrollo
- `firebase emulators:start` simula Firestore, Auth y Functions localmente

### Total estimado mientras construís: $0/mes

---

## Accesibilidad — recordatorio constante

El target incluye personas mayores. Antes de marcar cualquier pantalla como completa:

- [ ] ¿El texto más pequeño visible es 16sp?
- [ ] ¿Los botones tienen mínimo 52dp de alto?
- [ ] ¿Los íconos sin texto tienen tooltip o Semantics label?
- [ ] ¿Funciona con el modo de accesibilidad del sistema activado?
- [ ] ¿Lo probaste con una persona no técnica (familiar, vecino)?

El último punto es el más importante y el más fácil de saltear. No lo saltees.

---

## Monetización (para pensar, no para implementar ahora)

Opciones viables para el mercado argentino:

**Opción A — Freemium**
3 evaluaciones gratis → $X ARS/mes para ilimitadas.
Simple de implementar con Firestore counter + RevenueCat para suscripciones.

**Opción B — Pay-per-use**
$X ARS por evaluación, $Y ARS por CV generado.
Más fricción pero menor barrera de entrada.

**Opción C — Gratuita con límite mensual**
10 evaluaciones gratis por mes. Suficiente para la mayoría.
Monetización en features premium (coach avanzado, exportar a LinkedIn, etc.)

Recomendación: empezar con C para maximizar usuarios y aprender qué usan.
Cambiar a A cuando tengas datos reales de uso.
