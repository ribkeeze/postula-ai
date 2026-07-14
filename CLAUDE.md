# PostulaAI

Flutter (Android/iOS) job search app for Argentina. No terminal needed.
Backend: Firebase. AI: Gemini 2.5 Flash via Cloud Functions. Monetization: AdMob + RevenueCat.

## Stack
Flutter + Riverpod codegen + go_router + Firebase + Gemini 2.5 Flash + Clean Architecture feature-first.

## Architecture
Feature-first. Each feature: `data/datasources/ data/repositories/ domain/entities/ domain/repositories/ domain/usecases/ presentation/providers/ presentation/screens/ presentation/widgets/`

## Rules (NEVER violate)
- `@riverpod` / `@Riverpod(keepAlive:true)` — zero setState outside ephemeral UI
- go_router only — never Navigator.push in business logic
- Either<Failure,T> domain → AsyncValue presentation
- All strings → `lib/core/constants/strings_es.dart`
- Only `Theme.of(context).colorScheme.xxx` — no hardcoded colors
- Min 16sp body, 48dp touch targets
- No Firebase calls from providers (datasource → repository → usecase)
- No Gemini API key in Flutter client
- Error messages: plain Spanish only, never technical text
- JSON round-trip before fromJson: `jsonDecode(jsonEncode(raw)) as Map<String,dynamic>`
- CV/Coach providers: keepAlive family + `_isGenerating` bool prevents `_loadCached()` override

## Firestore Collections
profiles/ evaluations/ applications/ cvs/ coachSessions/ subscriptions/ usage/ coachSessions/

## Firestore Rules Pattern
`resource == null || request.auth.uid == resource.data.userId` (avoids permission-denied on missing docs)

## Free Limits (lib/core/constants/limits.dart)
evaluations: 3/day · cvGenerated: 1/day · coachSessions: 3/day

## Ads
BannerAdWidget: bottomNavigationBar of TrackerScreen (free only)
Interstitial: every 2 evaluations (free only)
Rewarded: before PDF download or share (free only)

## Cloud Functions (functions/src/, TypeScript, southamerica-east1)
Model: `gemini-2.5-flash` + `thinkingConfig:{thinkingBudget:0}`
Prompts: `modes/*.md` — never hardcode in .ts
Error pattern: catch 429 → resource-exhausted HttpsError; rethrow HttpsError; else internal
Functions: evaluateJob · generateCv (caches cvs/) · prepareCoach (caches coachSessions/) · cleanupOldUsage (scheduled)

## Features (8 tabs: evaluate/tracker/job-search/profile)
profile · evaluation · tracker · cv_generator · coach · subscription · job_search · ads · legal

## Legal (lib/features/legal/)
Routes: `/privacy` (PrivacyPolicyScreen) · `/terms` (TermsOfServiceScreen)
Both outside ShellRoute — no bottom nav. Accessible without auth (legal routes exempt from redirect).
Entry points: tappable links in LoginScreen footer · Legal section card in ProfileScreen read mode.

## Commands
```bash
flutter analyze
dart run build_runner build --delete-conflicting-outputs
firebase deploy --only functions
firebase deploy --only firestore:rules
```

## Never
- Business logic in screens/widgets
- Direct Firebase from providers
- dynamic types
- Gemini key in Flutter client
- Technical errors to users
- Hardcoded colors
- Ads to premium users
- Usage counters from Flutter (Cloud Functions only)
