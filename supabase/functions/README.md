# Supabase Edge Functions

This folder contains auth, courses, notes, and AI transcription orchestration functions used by the Flutter app.

## Functions

- `auth-signup`: validates role/email domain and upserts `public.profiles`.
- `auth-login-bootstrap`: reads authenticated user profile and returns role metadata.
- `create-course`: validates lecturer input and inserts a `public.courses` row.
- `alerts-api`: handles alerts CRUD for assignments, CAs, exams, and notices.
- `notes-api`: handles note CRUD against `public.notes`.
- `transcribe-audio`: downloads lecture audio from Storage, sends it to Gladia, and writes transcript/summary/result JSON to `public.lectures`.
- `courses-api`: lecturer course management actions (create/list/details/update/delete, students, delegates).
- `notes-api`: notes metadata and signed-download flows for lecturers, delegates, and students.

## Required Function Secrets

Set these in your Supabase project before deploying:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (required by all current functions)
- `GLADIA_API_KEY` (required by `transcribe-audio`)
- `GLADIA_BASE_URL` (optional, defaults to `https://api.gladia.io/v2`)
- `GLADIA_POLL_INTERVAL_MS` (optional, defaults to `2500`)
- `GLADIA_TIMEOUT_MS` (optional, defaults to `180000`)

## Deploy

```bash
supabase functions deploy auth-signup
supabase functions deploy auth-login-bootstrap
supabase functions deploy create-course
supabase functions deploy alerts-api
supabase functions deploy notes-api
supabase functions deploy transcribe-audio
supabase functions deploy courses-api
supabase functions deploy notes-api
```

## Local Serve

```bash
supabase functions serve auth-signup --env-file .env.local
supabase functions serve auth-login-bootstrap --env-file .env.local
supabase functions serve create-course --env-file .env.local
supabase functions serve alerts-api --env-file .env.local
supabase functions serve notes-api --env-file .env.local
supabase functions serve transcribe-audio --env-file .env.local
supabase functions serve courses-api --env-file .env.local
supabase functions serve notes-api --env-file .env.local
```

