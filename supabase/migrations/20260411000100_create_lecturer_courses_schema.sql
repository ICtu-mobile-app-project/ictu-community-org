-- Lecturer courses management schema.
create extension if not exists pgcrypto;

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  course_code text not null unique,
  title text not null,
  description text not null default '',
  semester text not null,
  lecturer_id uuid not null references auth.users(id) on delete cascade,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_courses_lecturer_id on public.courses(lecturer_id);
create index if not exists idx_courses_created_at on public.courses(created_at desc);
create index if not exists idx_courses_code on public.courses(course_code);

create table if not exists public.course_enrollments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(course_id, student_id)
);

create index if not exists idx_course_enrollments_course_id on public.course_enrollments(course_id);
create index if not exists idx_course_enrollments_student_id on public.course_enrollments(student_id);

create table if not exists public.course_delegates (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  student_id uuid not null references auth.users(id) on delete cascade,
  can_upload_notes boolean not null default true,
  can_edit_notes boolean not null default false,
  can_delete_notes boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(course_id, student_id)
);

create index if not exists idx_course_delegates_course_id on public.course_delegates(course_id);
create index if not exists idx_course_delegates_student_id on public.course_delegates(student_id);

-- Reuse shared trigger function from previous migrations.
drop trigger if exists trg_courses_updated_at on public.courses;
create trigger trg_courses_updated_at
before update on public.courses
for each row
execute function public.set_updated_at_timestamp();

drop trigger if exists trg_course_delegates_updated_at on public.course_delegates;
create trigger trg_course_delegates_updated_at
before update on public.course_delegates
for each row
execute function public.set_updated_at_timestamp();

alter table public.courses enable row level security;
alter table public.course_enrollments enable row level security;
alter table public.course_delegates enable row level security;

-- Courses: lecturers can manage their courses; students/delegates can read enrolled courses.
create policy if not exists "courses_select_enrolled_or_owner"
on public.courses
for select
using (
  auth.uid() = lecturer_id
  or exists (
    select 1 from public.course_enrollments ce
    where ce.course_id = courses.id and ce.student_id = auth.uid()
  )
);

create policy if not exists "courses_insert_owner"
on public.courses
for insert
with check (auth.uid() = lecturer_id);

create policy if not exists "courses_update_owner"
on public.courses
for update
using (auth.uid() = lecturer_id)
with check (auth.uid() = lecturer_id);

create policy if not exists "courses_delete_owner"
on public.courses
for delete
using (auth.uid() = lecturer_id);

-- Enrollments: lecturer of course can manage; enrolled student can view own enrollment row.
create policy if not exists "course_enrollments_select_owner_or_self"
on public.course_enrollments
for select
using (
  student_id = auth.uid()
  or exists (
    select 1 from public.courses c
    where c.id = course_enrollments.course_id and c.lecturer_id = auth.uid()
  )
);

create policy if not exists "course_enrollments_insert_owner"
on public.course_enrollments
for insert
with check (
  exists (
    select 1 from public.courses c
    where c.id = course_enrollments.course_id and c.lecturer_id = auth.uid()
  )
);

create policy if not exists "course_enrollments_delete_owner"
on public.course_enrollments
for delete
using (
  exists (
    select 1 from public.courses c
    where c.id = course_enrollments.course_id and c.lecturer_id = auth.uid()
  )
);

-- Delegates: lecturer of course manages; delegate can read own assignment.
create policy if not exists "course_delegates_select_owner_or_self"
on public.course_delegates
for select
using (
  student_id = auth.uid()
  or exists (
    select 1 from public.courses c
    where c.id = course_delegates.course_id and c.lecturer_id = auth.uid()
  )
);

create policy if not exists "course_delegates_insert_owner"
on public.course_delegates
for insert
with check (
  exists (
    select 1 from public.courses c
    where c.id = course_delegates.course_id and c.lecturer_id = auth.uid()
  )
);

create policy if not exists "course_delegates_update_owner"
on public.course_delegates
for update
using (
  exists (
    select 1 from public.courses c
    where c.id = course_delegates.course_id and c.lecturer_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.courses c
    where c.id = course_delegates.course_id and c.lecturer_id = auth.uid()
  )
);

create policy if not exists "course_delegates_delete_owner"
on public.course_delegates
for delete
using (
  exists (
    select 1 from public.courses c
    where c.id = course_delegates.course_id and c.lecturer_id = auth.uid()
  )
);

