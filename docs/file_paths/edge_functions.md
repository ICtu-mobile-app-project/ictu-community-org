# Edge Functions Mapping

Mapping of serverless logic (Deno/TypeScript) within Supabase.

## Functions (`supabase/functions/`)

- `auth-login-bootstrap/`: Post-login initialization and role check.
- `auth-signup/`: Logic for creating new user profiles upon signup.
- `courses-api/`: General CRUD and query logic for courses.
- `student-course-api/`: Specific logic for student enrollments and course access.
- `create-course/`: Specialized logic for course creation (Admin/Staff).
- `notes-api/`: Management and retrieval of lecture notes.
- `alerts-api/`: Processing and distribution of campus alerts.
- `transcribe-audio/`: Integration with AI services for lecture transcription.

## Shared Code
- `_shared/`: Common utilities and types used across functions.
