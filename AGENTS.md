# AGENTS Guide - ICTU Community

## Project map (what matters first)
- Flutter app entrypoint is `lib/main.dart`: initializes Supabase, then runs `IctuCommunityApp`.
- App shell and auth-driven routing live in `lib/app.dart` (`SplashScreen` first, then role-based redirect).
- Core infrastructure is under `lib/core/`:
  - `lib/core/supabase/supabase_bootstrap.dart` (Supabase init + env config)
  - `lib/core/theme/app_theme.dart` (single dark Material 3 theme)
- Feature slices are under `lib/features/*` with mostly `screens/`, plus light `controllers/` and `models/`.
- Supabase Edge Functions are in `supabase/functions/` and are part of the auth contract (`auth-signup`, `auth-login-bootstrap`).

## Runtime flow and boundaries
- Startup flow: `SplashScreen` waits ~1.4s, calls `AuthController.restoreCurrentUserRole()`, then routes to `WelcomeScreen`, `MainShell`, or `LecturerDashboardScreen`.
- Login flow: `LoginScreen -> AuthController.signIn -> _fetchRole() -> MainShell/LecturerDashboardScreen`.
- Signup flow: `SignupScreen -> AuthController.signUp -> client.auth.signUp + functions.invoke('auth-signup')`.
- Role model is shared by convention: Dart `UserRole` (`student|lecturer|delegateRole`) maps to DB values (`student|lecturer|delegate`).
- Email domain restriction is enforced in both Flutter and functions (`@ictuniversity.edu.cm`); keep both sides aligned.

## Conventions used in this repo
- State management is intentionally simple: `ValueNotifier` + `ValueListenableBuilder` (see `MainNavController`, `MainShell`).
- Navigation is imperative with `Navigator` + `MaterialPageRoute`, often `pushReplacement`/`pushAndRemoveUntil` for auth transitions.
- UI uses hard-coded design tokens/colors heavily; consistency usually means copying existing component patterns instead of introducing a new theme layer.
- Most non-auth feature screens are static/mock UI right now (community, courses, timetable, news, profile, notifications).
- Lints are only `flutter_lints` defaults (`analysis_options.yaml`), no custom strict rules.

## External integrations and contracts
- Flutter dependency surface is small: `supabase_flutter` is the only backend SDK in app code (`pubspec.yaml`).
- `AuthController._fetchRole()` first calls Edge Function `auth-login-bootstrap`, then falls back to direct `profiles` query.
- `auth-signup` uses service-role key and upserts into `public.profiles`; payload fields must match current function schema.
- Function auth/session behavior depends on bearer token forwarding (see `auth-login-bootstrap/index.ts`).
- `package.json` exists for Supabase function JS dependency management (`@supabase/supabase-js`).

## Developer workflows (verified from repo files)
- Install Flutter deps: `flutter pub get`
- Run analyzer: `flutter analyze`
- Run tests: `flutter test` (current coverage is minimal: `test/widget_test.dart`)
- Run app with explicit Supabase env (recommended pattern in code):
  - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- Supabase functions local serve/deploy commands are documented in `supabase/functions/README.md`.

## Practical guardrails for agents
- Prefer code reality over product-plan text in `README.md` (README still describes planned backend architecture).
- Do not rename role literals or profile column keys without updating both Flutter auth controller and Edge Functions.
- If changing auth flows, validate all three route entry points: `SplashScreen`, `LoginScreen`, and auth state listener in `lib/app.dart`.
- Keep asset paths consistent with `pubspec.yaml` (`assets/...`), since many screens reference these directly.

