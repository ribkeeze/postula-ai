---
name: flutter-postulai
description: Flutter development for PostulaAI app. Use when implementing Flutter features, fixing Flutter bugs, creating widgets, working with Riverpod providers, fixing compilation errors, updating entities, running build_runner, or any Dart/Flutter code change in the PostulaAI project.
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, MultiEdit
model: inherit
---

# PostulaAI Flutter Development Skill

## Project Context
PostulaAI is a Flutter app (Android + iOS) for job search in Argentina.
Stack: Flutter + Firebase + Gemini AI + Riverpod + Clean Architecture feature-first.

## Before Every Task
1. Read CLAUDE.md for full project context
2. Identify affected feature folder in lib/features/
3. Check existing patterns in similar features before implementing

## Architecture Rules (NEVER violate)
- Clean Architecture feature-first: data/ domain/ presentation/ per feature
- Riverpod codegen (@riverpod, @Riverpod(keepAlive: true)) — zero setState outside ephemeral UI
- go_router for navigation — never Navigator.push in business logic
- dartz Either<Failure, T> in domain — AsyncValue in presentation
- All user-visible strings in lib/core/constants/strings_es.dart
- Only Theme.of(context).colorScheme.xxx — no hardcoded colors
- Min font 16sp body, min touch target 48dp

## After Every Flutter Change
```bash
flutter analyze
```

## When Entities Change
```bash
dart run build_runner build --delete-conflicting-outputs
```

## JSON Parsing from Cloud Functions
Always use JSON round-trip before fromJson to fix _Map<Object?, Object?> errors:
```dart
final cleanData = jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;
final entity = Entity.fromJson({...cleanData, 'id': evaluationId});
```

## CV/Coach Providers Pattern
These are keepAlive family providers with _isGenerating/_isPreparing bool.
Never let _loadCached() override state during active generation.

## Error Messages to Users
Always plain Spanish — never technical text, stack traces, or Firebase codes.
- resource-exhausted → "Alcanzaste tu límite diario."
- unauthenticated → "Tu sesión expiró. Volvé a iniciar sesión."
- Any Firebase error → "Algo salió mal. Intentá de nuevo."

## Firestore Rules Pattern
Use `resource == null || request.auth.uid == resource.data.userId`
to avoid permission-denied on non-existent documents.
