-- Audio/AI transcription schema for lecture processing.
create extension if not exists pgcrypto;

create table if not exists public.lectures (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  audio_url text not null,
  course_code text not null default 'UNKNOWN',
  title text,
  status text not null default 'processing' check (status in ('processing', 'completed', 'failed')),
  transcription text,
  summary text,
  transcription_result jsonb,
  processed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_lectures_user_id on public.lectures(user_id);
create index if not exists idx_lectures_status on public.lectures(status);
create index if not exists idx_lectures_course_code on public.lectures(course_code);
create index if not exists idx_lectures_created_at on public.lectures(created_at desc);

alter table public.lectures enable row level security;

create policy if not exists "lectures_select_own"
on public.lectures
for select
using (auth.uid() = user_id);

create policy if not exists "lectures_insert_own"
on public.lectures
for insert
with check (auth.uid() = user_id);

create policy if not exists "lectures_update_own"
on public.lectures
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.set_updated_at_timestamp()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_lectures_updated_at on public.lectures;
create trigger trg_lectures_updated_at
before update on public.lectures
for each row
execute function public.set_updated_at_timestamp();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'lecture-audio',
  'lecture-audio',
  false,
  20971520,
  array['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/x-m4a', 'audio/aac', 'audio/wav', 'audio/ogg']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy if not exists "lecture_audio_upload_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'lecture-audio'
  and split_part(name, '/', 2) = auth.uid()::text
);

create policy if not exists "lecture_audio_read_own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'lecture-audio'
  and split_part(name, '/', 2) = auth.uid()::text
);

create policy if not exists "lecture_audio_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'lecture-audio'
  and split_part(name, '/', 2) = auth.uid()::text
)
with check (
  bucket_id = 'lecture-audio'
  and split_part(name, '/', 2) = auth.uid()::text
);

create policy if not exists "lecture_audio_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'lecture-audio'
  and split_part(name, '/', 2) = auth.uid()::text
);

