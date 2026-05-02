# Backend Database Mapping

Mapping of SQL migrations and schemas within the Supabase backend.

## Migrations (`supabase/migrations/`)

- `20260407000100_create_lectures_and_transcription_schema.sql`: Tables for lectures and AI transcripts.
- `20260411000100_create_lecturer_courses_schema.sql`: Schema for lecturer-course assignments.
- `20260411000200_create_lecture_notes_schema.sql`: Storage and metadata for lecture notes.
- `20260412030000_alerts_requirements_and_indexes.sql`: Alert system schema and performance optimizations.
- `20260415000000_student_enrollments_schema.sql`: Student enrollment logic and tables.
- `20260416000000_course_enrollments_rls_and_cleanup.sql`: Security policies (RLS) and schema refinements.
- `20260416000100_create_schedules_table.sql`: Timetable and scheduling data.
- `20260501000000_rename_and_update_notes.sql`: Recent updates to the notes schema.

## Key Tables
- `profiles`: User data and roles.
- `courses`: Core course information.
- `course_enrollments`: Link between students and courses.
- `lecturer_courses`: Link between lecturers and courses.
- `lecture_notes`: Metadata for uploaded course materials.
- `alerts`: Important announcements and notifications.
- `schedules`: Weekly course timings.
