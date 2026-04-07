# Supabase Auth Edge Functions

This folder contains auth orchestration functions used by the Flutter app.

## Functions

- `auth-signup`: validates role/email domain and upserts `public.profiles`.
- `auth-login-bootstrap`: reads authenticated user profile and returns role metadata.

## Required Function Secrets

Set these in your Supabase project before deploying:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (required by `auth-signup` and `auth-login-bootstrap`)

## Deploy

```bash
supabase functions deploy auth-signup
supabase functions deploy auth-login-bootstrap
```

## Local Serve

```bash
supabase functions serve auth-signup --env-file .env.local
supabase functions serve auth-login-bootstrap --env-file .env.local
```

