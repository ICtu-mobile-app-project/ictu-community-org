-- Fix enrollment migration for schema where course_enrollments uses course_code

-- 1) Migrate existing rows into course_enrollments (only if enrollments exists)
do $$
begin
  if to_regclass('public.enrollments') is not null then
    insert into public.course_enrollments (student_id, course_code, enrolled_at)
    select
      e.student_id,
      c.course_code,
      e.created_at
    from public.enrollments e
    join public.courses c on c.id = e.course_id
    on conflict (course_code, student_id) do nothing;

    drop table if exists public.enrollments cascade;
  end if;
end $$;

-- 2) Replace/ensure RLS policies for notes
drop policy if exists "Students can view notes of enrolled courses" on public.notes;

create policy "Students can view notes of enrolled courses"
on public.notes
for select
to authenticated
using (
  exists (
    select 1
    from public.course_enrollments ce
    where ce.student_id = auth.uid()
      and ce.course_code = public.notes.course_code
  )
);

-- 3) Replace/ensure RLS policies for alerts
drop policy if exists "Students can view alerts of enrolled courses" on public.alerts;

create policy "Students can view alerts of enrolled courses"
on public.alerts
for select
to authenticated
using (
  exists (
    select 1
    from public.course_enrollments ce
    where ce.student_id = auth.uid()
      and ce.course_code = public.alerts.course_code
  )
);
