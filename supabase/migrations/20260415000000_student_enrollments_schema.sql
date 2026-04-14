-- Student Enrollment Schema

create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(student_id, course_id)
);

-- Enable RLS
alter table public.enrollments enable row level security;

-- RLS Policies for enrollments
create policy "Students can view their own enrollments"
on public.enrollments
for select
to authenticated
using (auth.uid() = student_id);

create policy "Students can enroll themselves"
on public.enrollments
for insert
to authenticated
with check (auth.uid() = student_id);

-- Ensure students can read courses
alter table public.courses enable row level security;

create policy "Anyone authenticated can view courses"
on public.courses
for select
to authenticated
using (true);

-- Ensure students can read notes if they are enrolled in the course
-- Note: notes table uses course_code, but enrollments uses course_id.
-- We might need to join or use a subquery.
-- However, the student-course-api edge function handles content fetching using service role.
-- Adding these policies for defense in depth/direct client access.

alter table public.notes enable row level security;

create policy "Students can view notes of enrolled courses"
on public.notes
for select
to authenticated
using (
  exists (
    select 1 from public.enrollments e
    join public.courses c on e.course_id = c.id
    where e.student_id = auth.uid()
    and c.course_code = public.notes.course_code
  )
);

alter table public.alerts enable row level security;

create policy "Students can view alerts of enrolled courses"
on public.alerts
for select
to authenticated
using (
  exists (
    select 1 from public.enrollments e
    join public.courses c on e.course_id = c.id
    where e.student_id = auth.uid()
    and c.course_code = public.alerts.course_code
  )
);
