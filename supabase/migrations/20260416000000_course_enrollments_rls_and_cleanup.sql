-- Create course_enrollments table if it doesn't exist (used by student-course-api)
-- This table is code-based (uses course_code) to facilitate easier filtering
create table if not exists public.course_enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references auth.users(id) on delete cascade,
  course_code text not null,
  created_at timestamptz not null default now(),
  unique(student_id, course_code)
);

-- Enable RLS
alter table public.course_enrollments enable row level security;

-- RLS Policies for course_enrollments
create policy "Students can view their own course_enrollments"
on public.course_enrollments
for select
to authenticated
using (auth.uid() = student_id);

create policy "Students can enroll themselves via course_code"
on public.course_enrollments
for insert
to authenticated
with check (auth.uid() = student_id);

-- Add indexes for performance
create index if not exists idx_course_enrollments_student_id on public.course_enrollments(student_id);
create index if not exists idx_course_enrollments_course_code on public.course_enrollments(course_code);

-- Update notes RLS to use course_enrollments as well
drop policy if exists "Students can view notes of enrolled courses" on public.notes;
create policy "Students can view notes of enrolled courses"
on public.notes
for select
to authenticated
using (
  exists (
    select 1 from public.course_enrollments ce
    where ce.student_id = auth.uid()
    and ce.course_code = public.notes.course_code
  )
);

-- Update alerts RLS to use course_enrollments as well
drop policy if exists "Students can view alerts of enrolled courses" on public.alerts;
create policy "Students can view alerts of enrolled courses"
on public.alerts
for select
to authenticated
using (
  exists (
    select 1 from public.course_enrollments ce
    where ce.student_id = auth.uid()
    and ce.course_code = public.alerts.course_code
  )
);

-- Storage Policies for lecture-notes bucket
-- Students should be able to read (select) notes if they are enrolled
-- This requires a slightly complex storage policy because RLS for storage.objects
-- doesn't easily join with public tables without specific setup.
-- However, we can use the same logic as above.

create policy "Enrolled students can read lecture notes"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'lecture-notes'
  and exists (
    -- Extract the course code from the path if stored as notes/uid/timestamp_filename
    -- This is tricky if the path doesn't contain the course code.
    -- In our current implementation (NotesService), the path is 'notes/uid/filename'.
    -- The metadata/linkage is in the 'public.notes' table.
    exists (
      select 1 from public.notes n
      join public.course_enrollments ce on n.course_code = ce.course_code
      where ce.student_id = auth.uid()
      and n.content_url = storage.objects.name
    )
  )
);
