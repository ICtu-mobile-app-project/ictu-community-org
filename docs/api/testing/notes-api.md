# Notes API - Test Log

## Scope
- Create note metadata after storage upload
- List notes for course members (lecturer/student/delegate)
- Get note details
- Update note title (permission-gated)
- Delete note (permission-gated)
- Generate signed download URL

## Manual Verification
1. Login as lecturer and upload a file to bucket `lecture-notes` path `notes/<uid>/<ts>_file.pdf`.
2. Call `notes-api` action `create_note` and confirm row in `public.lecture_notes`.
3. Call `list_notes` as lecturer and ensure note appears.
4. Login as enrolled student and call `list_notes` -> should succeed.
5. Call `create_download_url` as student -> should return signed URL.
6. Login as delegate without edit permission and call `update_note_title` -> should fail 403.
7. Grant delegate edit permission and retry -> should succeed.
8. Delete note as lecturer -> row removed and storage cleanup best-effort.

