-- Create schedules table to store the timetable
create table if not exists public.schedules (
  id uuid primary key default gen_random_uuid(),
  course_code text not null,
  course_name text not null,
  lecturer text,
  hall text,
  day_of_week text not null check (day_of_week in ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY')),
  start_time time not null,
  end_time time not null,
  group_name text, -- e.g., 'Group 1', 'Group 2'
  created_at timestamptz not null default now()
);

-- Enable RLS
alter table public.schedules enable row level security;

-- Everyone authenticated can view schedules
create policy "Anyone authenticated can view schedules"
on public.schedules
for select
to authenticated
using (true);

-- Admins can manage (insert/update/delete) schedules
create policy "Admins can manage schedules"
on public.schedules
for all
to authenticated
using (
  (select role from public.profiles where id = auth.uid()) = 'admin'
);

-- Indexes for performance
create index if not exists idx_schedules_course_code on public.schedules(course_code);
create index if not exists idx_schedules_day_of_week on public.schedules(day_of_week);
