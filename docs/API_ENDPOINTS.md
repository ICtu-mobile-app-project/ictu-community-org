# API Endpoints Index

## Supabase Edge Functions
- `auth-signup`
- `auth-login-bootstrap`
- `create-course`
- `alerts-api`
- `notes-api`
- `transcribe-audio` (supports segmented long-audio normalization for >30 min)
- `courses-api` (lecturer courses management actions)
- `notes-api` (course notes upload/list/details/delete/download actions)

## Lecturer Courses REST Endpoints
- `POST /api/courses` (create)
- `GET /api/courses/my-courses` (lecturer paginated list)
- `GET /api/courses/:id` (course details)
- `PUT /api/courses/:id` (update)
- `DELETE /api/courses/:id` (delete only when no content)
- `POST /api/courses/:id/students` (add/enroll students)
- `DELETE /api/courses/:id/students/:studentId` (remove student)
- `POST /api/courses/:id/delegates` (assign delegate)
- `GET /api/courses/:id/delegates` (list delegates)

## Endpoint Specs
- `docs/api/endpoints/alerts-api.md`
- `docs/api/endpoints/transcribe-audio.md`
- `docs/api/endpoints/lecturer-courses.md`
- `docs/api/endpoints/notes-api.md`

## Test Logs
- `docs/api/testing/transcribe-audio.md`
- `docs/api/testing/lecturer-courses.md`
- `docs/api/testing/notes-api.md`
