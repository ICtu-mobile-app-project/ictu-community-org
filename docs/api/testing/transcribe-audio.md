# transcribe-audio Testing Log

## Test Date
- 2026-04-07

## Preconditions
- Authenticated user session is active in Flutter.
- Storage bucket `lecture-audio` exists.
- `public.lectures` table + RLS policies migrated.
- Edge function secrets are set:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `GLADIA_API_KEY`

## Happy Path
1. Record or pick a valid audio file (`.m4a`, `.mp3`, `.wav`, `.aac`, `.ogg`).
2. Upload through `LectureUploadService`.
3. Insert lecture row (`status = processing`).
4. Invoke `transcribe-audio`.
5. Verify DB row updates:
   - `status = completed`
   - `transcription` populated
   - `summary` populated
   - `transcription_result` populated JSON

## Negative Cases
- Missing `lectureId` -> expect HTTP 400 with `success: false`.
- Full URL in `audioUrl` -> expect HTTP 400.
- Non-existent storage object -> expect HTTP 400 and row status `failed`.
- Gladia timeout -> expect HTTP 400 and row status `failed` with `error_message`.

## Performance Notes
- Poll interval default: `2500ms`
- Timeout default: `180000ms`
- File size cap from bucket policy: `20MB`

