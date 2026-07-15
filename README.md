# PostulaAI

**La herramienta de búsqueda laboral con IA para todos los argentinos.**

---

## El problema

Las herramientas de IA para búsqueda laboral existen — pero requieren instalar Node.js, abrir una terminal, editar archivos YAML, y entender qué es un CLI. Eso excluye a la mayoría de las personas que más necesitan ayuda: profesionales de mediana edad reinventándose, trabajadores de 50+ que nunca usaron una terminal, primeras generaciones universitarias sin red de contactos.

En Argentina, eso es una enorme cantidad de personas.

## La solución

Una app Flutter (Android + iOS) que lleva la asistencia de IA para búsqueda laboral — evaluación de ofertas, generación de CVs personalizados, preparación de entrevistas — a una interfaz mobile simple que cualquier persona puede usar desde su celular.

---

## Qué está construido y funcionando

### 1. Perfil Guiado (Onboarding)
Onboarding paso a paso que construye el perfil completo del usuario: datos personales, experiencia laboral (con referencias), educación, certificaciones, habilidades, idiomas, proyectos, expectativas salariales, modalidad preferida e industrias excluidas. Se guarda en Firestore y se reutiliza en todas las demás features.

### 2. Evaluador de Ofertas
El usuario pega el texto de una oferta laboral. La IA lo compara con su perfil y devuelve un score de fit, fortalezas, brechas y una recomendación — con guardrails estrictos para no inventar experiencia que el usuario no tiene.

### 3. Generador de CV Personalizado
Para cualquier oferta evaluada, genera un PDF personalizado: detecta el idioma del aviso (español/inglés) y escribe el CV en ese idioma, incluye solo los proyectos, certificaciones y habilidades relevantes para ese rol, y agrega referencias y links de contacto cuando están disponibles. Se cachea para no regenerarse innecesariamente.

### 4. Pipeline de Postulaciones
Tracker visual de cada postulación por estado (Interesado → Aplicado → Entrevista → Oferta). Swipe para eliminar con deshacer, y limpieza en cascada de datos relacionados al borrar.

### 5. Coach de Entrevistas
Genera preguntas probables (técnicas, conductuales, motivacionales) + tips de coaching y cosas a evitar, basado en el perfil real del candidato y los requisitos concretos del puesto. Se cachea por postulación.

### 6. Suscripción / Freemium
Límites de uso diario para evaluaciones, generación de CV y sesiones de coach en el plan gratuito. El plan premium elimina límites y publicidad, gestionado a través de RevenueCat. Los contadores de uso se aplican server-side para evitar manipulación del cliente.

### 7. Búsqueda de Empleos
Acceso rápido a los principales portales de empleo argentinos (Bumeran, ZonaJobs, LinkedIn Jobs, Computrabajo, GetOnBoard). El usuario elige qué habilidades buscar y la app abre una query prearmada en el portal seleccionado.

### 8. Publicidad (Ads)
Banner de AdMob (pantalla del tracker), interstitial (cada 2 evaluaciones) y rewarded (antes de descargar o compartir el PDF) — mostrados solo a usuarios del plan gratuito.

### 9. Pantallas Legales
Política de privacidad y Términos de uso, accesibles desde el login (antes de crear cuenta) y desde el perfil del usuario. Sin autenticación requerida.

---

## Stack Técnico

```
Flutter (Android + iOS)
  ↓
Firebase Cloud Functions (TypeScript)  ←→  Google Gemini 3.1 Flash Lite
  ↓
Firestore (perfiles, evaluaciones, postulaciones, CVs, sesiones de coach, suscripciones, uso)
Firebase Auth (Google Sign-In)
```

- **State management:** Riverpod con generación de código (`@riverpod`)
- **Arquitectura:** Clean Architecture, feature-first (`data/ domain/ presentation/` por feature)
- **Navegación:** go_router
- **Manejo de errores:** `Either<Failure, T>` en dominio, `AsyncValue` en presentación
- **Monetización:** AdMob (publicidad) + RevenueCat (suscripciones)
- **Generación de PDF:** client-side con el paquete `pdf`

**¿Por qué las llamadas a IA van por Cloud Functions?**
La API key de Gemini nunca llega al cliente. Los límites de uso se aplican server-side. El perfil del usuario se combina con el prompt en el backend, sin exponerlo a la app.

**¿Por qué Gemini 3.1 Flash Lite?**
Tier gratuito generoso, ventana de contexto amplia (suficiente para un perfil completo + oferta + instrucciones), y thinking deshabilitado (`thinkingConfig: { thinkingBudget: 0 }`) para respuestas más rápidas y económicas en tareas de output estructurado como estas.

---

## Arquitectura de IA

El comportamiento de la IA está definido en archivos de prompt independientes dentro de `modes/`, no hardcodeado en TypeScript:

```
modes/
  evaluate_es.md   → lógica de evaluación de fit con una oferta
  cv_es.md         → reglas de generación de CV personalizado
  coach_es.md      → lógica de preparación de entrevistas
```

Los Cloud Functions leen estos archivos, inyectan el perfil del usuario y el texto de la oferta, y llaman a Gemini. Separar los prompts del código facilita iterar sin tocar la lógica de la aplicación, y quedan versionados como cualquier otro archivo fuente.

El texto de la oferta ingresado por el usuario se sanitiza antes de interpolarse en los prompts (`functions/src/utils/sanitize.ts`) para reducir el riesgo de prompt injection.

---

## Setup

> **Note:** This repo does not include `.env`, `google-services.json`, `GoogleService-Info.plist`, or any Firebase config files. These are specific to your own Firebase project and must never be committed to version control.
>
> To run this project you need to create your own Firebase project and obtain your own credentials.

### Required Environment Variables

`functions/.env` (never committed):

```
GEMINI_API_KEY=your_google_ai_studio_key_here
```

Get a key at [Google AI Studio](https://aistudio.google.com/app/apikey).

### Firebase Config Files (never committed)

- `android/app/google-services.json` — download from Firebase Console → Project Settings → Android
- `ios/Runner/GoogleService-Info.plist` — download from Firebase Console → Project Settings → iOS
- `lib/firebase_options.dart` — generated by FlutterFire CLI (see step 3 below)

`lib/firebase_options.dart.example` is committed and shows the expected shape. The real file is gitignored.

### Setup para Desarrollo

```bash
# 1. Crear proyecto Firebase en https://console.firebase.google.com
#    Habilitar: Authentication, Firestore, Cloud Functions, Storage

# 2. Clonar y setup Flutter
flutter pub get

# 3. Generar lib/firebase_options.dart con FlutterFire CLI
npm install -g firebase-tools
npm install -g flutterfire_cli   # o: dart pub global activate flutterfire_cli
firebase login
firebase use --add               # seleccionar tu proyecto
flutterfire configure            # genera lib/firebase_options.dart automáticamente

# 4. Generar código (freezed, riverpod)
dart run build_runner build --delete-conflicting-outputs

# 5. Cloud Functions
cd functions
npm install
cp .env.example .env   # luego editar con tu GEMINI_API_KEY

# 6. Desplegar reglas y funciones
firebase deploy --only firestore:rules
firebase deploy --only functions

# 7. Emuladores locales (desarrollo sin costo)
firebase emulators:start

# 8. Correr la app
flutter run
```

---

## Estructura del Proyecto

```
postula_ai/
├── CLAUDE.md                    # Contexto del proyecto para agentes de IA (Claude Code)
├── README.md
├── pubspec.yaml
├── modes/                       # Prompts de IA por feature
│   ├── evaluate_es.md
│   ├── cv_es.md
│   └── coach_es.md
├── lib/
│   ├── core/                    # Router, tema, constantes, tipos de error
│   ├── features/
│   │   ├── profile/             # Onboarding y perfil del usuario
│   │   ├── evaluation/          # Evaluador de ofertas
│   │   ├── tracker/             # Pipeline de postulaciones
│   │   ├── cv_generator/        # Generación de CV + exportación PDF
│   │   ├── coach/               # Coach de entrevistas
│   │   ├── subscription/        # Lógica freemium + RevenueCat
│   │   ├── job_search/          # Acceso rápido a portales de empleo
│   │   ├── ads/                 # Integración AdMob
│   │   └── legal/               # Política de privacidad y Términos de uso
│   └── shared/                  # Providers y widgets compartidos entre features
├── functions/                   # Firebase Cloud Functions (TypeScript)
│   └── src/
│       ├── index.ts
│       ├── evaluate.ts
│       ├── generate_cv.ts
│       ├── coach.ts
│       └── utils/
└── test/
```

---

## Desarrollo con IA

Este proyecto fue construido en solitario, de principio a fin, usando Claude Code como parte central del flujo de desarrollo — no solo para autocompletado, sino para decisiones de arquitectura, debugging e implementación de features. El repo incluye:

- `CLAUDE.md` — contexto persistente del proyecto cargado automáticamente en cada sesión
- `.claude/skills/` — conocimiento específico por tarea para trabajo en Flutter y Cloud Functions, cargado bajo demanda
- `.claude/agents/` — subagentes personalizados (un revisor de código de solo lectura, un explorador del codebase) para tareas enfocadas y aisladas

Este setup refleja un enfoque deliberado hacia la ingeniería asistida por IA: contexto estructurado, expertise reutilizable y límites claros de las herramientas — en lugar de prompting ad-hoc.

---

## Por qué esto también es un proyecto de portfolio

Para cualquier empresa que contrate Flutter developers con foco en IA:

- Demuestra arquitectura clean en una app real con múltiples features
- Demuestra integración Firebase completa (Auth, Firestore, Storage, Functions, reglas de seguridad)
- Demuestra desarrollo AI-native real: prompt engineering server-side, outputs estructurados, guardrails anti-alucinación y control de costos/uso — no solo llamar a una API una vez
- Resuelve un problema real y bien definido de principio a fin
- Construido con consideraciones de producción en mente: manejo de errores, accesibilidad, monetización y enforcement freemium

> Este proyecto no es solo algo que ayuda a otros a conseguir trabajo — también te ayuda a conseguir el tuyo.
