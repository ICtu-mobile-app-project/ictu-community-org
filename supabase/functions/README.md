# Supabase Edge Functions

This folder contains auth and AI transcription orchestration functions used by the Flutter app.

## Functions

- `auth-signup`: validates role/email domain and upserts `public.profiles`.
- `auth-login-bootstrap`: reads authenticated user profile and returns role metadata.
- `transcribe-audio`: downloads lecture audio from Storage, sends it to Gladia, and writes transcript/summary/result JSON to `public.lectures`.

## Required Function Secrets

Set these in your Supabase project before deploying:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (required by `auth-signup` and `auth-login-bootstrap`)
- `GLADIA_API_KEY` (required by `transcribe-audio`)
- `GLADIA_BASE_URL` (optional, defaults to `https://api.gladia.io/v2`)
- `GLADIA_POLL_INTERVAL_MS` (optional, defaults to `2500`)
- `GLADIA_TIMEOUT_MS` (optional, defaults to `180000`)

## Deploy

```bash
supabase functions deploy auth-signup
supabase functions deploy auth-login-bootstrap
supabase functions deploy transcribe-audio
```

## Local Serve

```bash
supabase functions serve auth-signup --env-file .env.local
supabase functions serve auth-login-bootstrap --env-file .env.local
supabase functions serve transcribe-audio --env-file .env.local
```

