# PostulaAI

**La herramienta de búsqueda laboral con IA para todos los argentinos.**

> career-ops demostró que la IA puede transformar la búsqueda de empleo.
> PostulaAI lleva ese poder a quienes más lo necesitan: sin terminal, sin código, sin barreras.

---

## El problema

Las herramientas de IA para búsqueda laboral existen — pero requieren instalar Node.js, abrir una terminal, editar archivos YAML, y entender qué es un CLI. Eso excluye a la mayoría de las personas que más necesitan ayuda: profesionales de mediana edad reinventándose, trabajadores de 50+ que nunca usaron una terminal, primeras generaciones universitarias sin red de contactos.

En Argentina, eso es una enorme cantidad de personas.

## La solución

Una app Flutter (Android + iOS) que hace exactamente lo que hace career-ops — evaluar ofertas, generar CVs personalizados, preparar entrevistas — pero con una interfaz que cualquier persona puede usar desde su celular en 5 minutos.

## Nombre del proyecto

Opciones evaluadas:

| Nombre | Pros | Contras |
|--------|------|---------|
| **PostulaAI** | Claro, moderno, accionable | Puede sonar técnico por el "AI" |
| **TuLaburo** | Argentino, cercano, memorable | Muy informal, posible confusión con sitio existente |
| **CurriculumAI** | Descriptivo | Largo, difícil de recordar |
| **Postulá** | Simple, en castellano local | Genérico |

> Nombre de trabajo: **PostulaAI**. Puede cambiarse antes del lanzamiento.

---

## Features del MVP

### 1. Perfil Guiado (reemplaza cv.md + profile.yml)
Onboarding paso a paso que construye el perfil del usuario: datos personales, experiencia laboral, educación, habilidades, idiomas. Se guarda en Firestore. Se usa en todas las demás features sin que el usuario tenga que repetirlo.

### 2. Evaluador de Ofertas
El usuario pega el texto de una oferta laboral (o una URL). La IA evalúa el fit con su perfil y devuelve: puntuación, fortalezas, brechas, y recomendación de si vale la pena aplicar.

### 3. Generador de CV Personalizado
Para cada oferta guardada, genera un CV PDF adaptado con las keywords del aviso. El usuario puede compartirlo o descargarlo.

### 4. Pipeline de Postulaciones
Tracker visual del estado de cada postulación: Interesado → Aplicado → Entrevista → Oferta → Rechazado. Historial completo.

### 5. Coach de Entrevistas
Genera preguntas probables para cada oferta + ayuda al usuario a construir sus respuestas STAR basadas en su experiencia real.

---

## Stack Técnico

```
Flutter (Android + iOS)
  ↓
Firebase Cloud Functions  ←→  Gemini Flash API (free tier)
  ↓
Firestore (perfiles, evaluaciones, tracker)
Firebase Storage (PDFs generados)
Firebase Auth (Google Sign-In + email)
```

**¿Por qué las llamadas a IA van por Cloud Functions?**
- La API key nunca queda expuesta en el cliente
- Control de rate limiting y costos centralizado
- El perfil del usuario se combina con el prompt server-side

**¿Por qué Gemini Flash como default?**
- 1500 requests/día gratis en Google AI Studio
- 1M tokens de contexto (suficiente para perfil + oferta + instrucciones)
- Puede cambiarse a Claude o DeepSeek con un cambio de variable en Cloud Functions

---

## Arquitectura de IA

El núcleo de la app son los **modos** en `modes/`. Cada feature de IA tiene un archivo de prompt en español que define cómo razona el modelo:

```
modes/
  evaluate_es.md   → evaluación de fit con una oferta
  cv_es.md         → generación de CV personalizado
  coach_es.md      → preparación de entrevista
  research_es.md   → investigación de empresa
```

Los Cloud Functions leen estos archivos, inyectan el perfil del usuario y el input, y llaman a la API de IA. **El mismo sistema de modos que usa career-ops, pero ejecutado server-side y consumido por una UI mobile.**

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

### Setup para Desarrollo

```bash
# 1. Crear proyecto Firebase en https://console.firebase.google.com
#    Habilitar: Authentication, Firestore, Cloud Functions, Storage

# 2. Clonar y setup Flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 3. Firebase CLI
npm install -g firebase-tools
firebase login
firebase use --add  # seleccionar tu proyecto

# 4. Cloud Functions
cd functions
npm install
cp .env.example .env   # luego editar con tu GEMINI_API_KEY

# 5. Desplegar reglas y funciones
firebase deploy --only firestore:rules
firebase deploy --only functions

# 6. Emuladores locales (desarrollo sin costo)
firebase emulators:start

# 7. Correr la app
flutter run
```

---

## Estructura del Proyecto

```
postula_ai/
├── AGENTS.md                    # Contexto para agentes de IA (Claude Code, OpenCode, Gemini CLI)
├── README.md
├── pubspec.yaml
├── modes/                       # Prompts de IA por feature
│   ├── evaluate_es.md
│   ├── cv_es.md
│   ├── coach_es.md
│   └── research_es.md
├── .ai/
│   ├── architecture.md          # Decisiones de arquitectura
│   └── conventions.md           # Convenciones de código
├── lib/
│   ├── core/                    # Router, tema, constantes, errores
│   ├── features/
│   │   ├── profile/             # Onboarding y perfil del usuario
│   │   ├── evaluation/          # Evaluador de ofertas
│   │   ├── cv_generator/        # Generador de CV PDF
│   │   ├── tracker/             # Pipeline de postulaciones
│   │   └── coach/               # Coach de entrevistas
│   └── shared/                  # Widgets y providers compartidos
├── functions/                   # Firebase Cloud Functions (Node.js/TypeScript)
│   └── src/
│       ├── index.ts
│       ├── evaluate.ts
│       ├── generate_cv.ts
│       └── coach.ts
└── test/
```

---

## Por qué esto también es un proyecto de portfolio

Para cualquier empresa que contrate Flutter developers con foco en IA:

- Demuestra arquitectura clean en una app real con múltiples features
- Demuestra integración Firebase completa (Auth, Firestore, Storage, Functions)
- Demuestra AI-native development (no solo "usé ChatGPT", sino integración real de APIs)
- Tiene un user problem real y una solución concreta
- Está construido para escalar (no un side project de tutorial)

> Este proyecto no es solo algo que ayuda a otros a conseguir trabajo — también te ayuda a conseguir el tuyo.

---

## Roadmap

**MVP (mes 1-2):** Perfil + Evaluador + Tracker básico  
**V1 (mes 3):** Generador de CV PDF + Coach básico  
**V1.5 (mes 4):** Pulido UX, accesibilidad, onboarding simplificado para usuarios mayores  
**V2:** Portal scanner (equivalente al scan de career-ops), búsqueda de ofertas integrada
