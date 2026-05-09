-- Lecture notes schema shared by lecturers and students.
create extension if not exists pgcrypto;

create table if not exists public.lecture_notes (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  description text not null default '',
  content_url text not null,
  file_name text not null,
  file_size_bytes bigint not null default 0,
  uploaded_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_lecture_notes_course_id on public.lecture_notes(course_id);
create index if not exists idx_lecture_notes_uploaded_by on public.lecture_notes(uploaded_by);
create index if not exists idx_lecture_notes_created_at on public.lecture_notes(created_at desc);

alter table public.lecture_notes enable row level security;

drop trigger if exists trg_lecture_notes_updated_at on public.lecture_notes;
create trigger trg_lecture_notes_updated_at
before update on public.lecture_notes
for each row
execute function public.set_updated_at_timestamp();

-- Read access for lecturer owner, enrolled students, and delegates on the same course.
create policy if not exists "lecture_notes_select_course_members"
on public.lecture_notes
for select
using (
  exists (
    select 1 from public.courses c
    where c.id = lecture_notes.course_id and c.lecturer_id = auth.uid()
  )
  or exists (
    select 1 from public.course_enrollments ce
    where ce.course_id = lecture_notes.course_id and ce.student_id = auth.uid()
  )
  or exists (
    select 1 from public.course_delegates cd
    where cd.course_id = lecture_notes.course_id and cd.student_id = auth.uid()
  )
);

-- Insert allowed for lecturer owner or delegate with can_upload_notes.
create policy if not exists "lecture_notes_insert_owner_or_delegate"
on public.lecture_notes
for insert
with check (
  (
    uploaded_by = auth.uid()
    and exists (
      select 1 from public.courses c
      where c.id = lecture_notes.course_id and c.lecturer_id = auth.uid()
    )
  )
  or (
    uploaded_by = auth.uid()
    and exists (
      select 1 from public.course_delegates cd
      where cd.course_id = lecture_notes.course_id
        and cd.student_id = auth.uid()
        and cd.can_upload_notes = true
    )
  )
);

-- Update title/description allowed for owner lecturer or delegate with edit permission.
create policy if not exists "lecture_notes_update_owner_or_delegate"
on public.lecture_notes
for update
using (
  exists (
    select 1 from public.courses c
    where c.id = lecture_notes.course_id and c.lecturer_id = auth.uid()
  )
  or exists (
    select 1 from public.course_delegates cd
    where cd.course_id = lecture_notes.course_id
      and cd.student_id = auth.uid()
      and cd.can_edit_notes = true
  )
)
with check (
  exists (
    select 1 from public.courses c
    where c.id = lecture_notes.course_id and c.lecturer_id = auth.uid()
  )
  or exists (
    select 1 from public.course_delegates cd
    where cd.course_id = lecture_notes.course_id
      and cd.student_id = auth.uid()
      and cd.can_edit_notes = true
  )
);

-- Delete allowed for owner lecturer or delegate with delete permission.
create policy if not exists "lecture_notes_delete_owner_or_delegate"
on public.lecture_notes
for delete
using (
  exists (
    select 1 from public.courses c
    where c.id = lecture_notes.course_id and c.lecturer_id = auth.uid()
  )
  or exists (
    select 1 from public.course_delegates cd
    where cd.course_id = lecture_notes.course_id
      and cd.student_id = auth.uid()
      and cd.can_delete_notes = true
  )
);

-- Storage bucket for lecture notes files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'lecture-notes',
  'lecture-notes',
  false,
  10485760,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Uploads allowed to lecturer/delegate roles into their own prefix notes/<uid>/...
create policy if not exists "lecture_notes_storage_insert_lecturer_delegate"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'lecture-notes'
  and split_part(name, '/', 1) = 'notes'
  and split_part(name, '/', 2) = auth.uid()::text
  and exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role in ('lecturer', 'delegate')
  )
);

create policy if not exists "lecture_notes_storage_update_owner"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'lecture-notes'
  and split_part(name, '/', 2) = auth.uid()::text
)
with check (
  bucket_id = 'lecture-notes'
  and split_part(name, '/', 2) = auth.uid()::text
);

create policy if not exists "lecture_notes_storage_delete_owner"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'lecture-notes'
  and split_part(name, '/', 2) = auth.uid()::text
);

-- Direct SELECT from storage objects is restricted; app uses signed URLs via notes-api.

