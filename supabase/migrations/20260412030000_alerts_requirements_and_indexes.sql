alter table public.alerts
add column if not exists requirements jsonb not null default '[]'::jsonb;

create index if not exists idx_alerts_course_code on public.alerts(course_code);
create index if not exists idx_alerts_type on public.alerts(type);
create index if not exists idx_alerts_deadline on public.alerts(deadline);

alter table public.alerts enable row level security;

drop policy if exists "alerts_select_lecturer_own" on public.alerts;
create policy "alerts_select_lecturer_own"
on public.alerts
for select
to authenticated
using (lecturer_id = auth.uid());

drop policy if exists "alerts_insert_lecturer_own" on public.alerts;
create policy "alerts_insert_lecturer_own"
on public.alerts
for insert
to authenticated
with check (lecturer_id = auth.uid());

drop policy if exists "alerts_update_lecturer_own" on public.alerts;
create policy "alerts_update_lecturer_own"
on public.alerts
for update
to authenticated
using (lecturer_id = auth.uid())
with check (lecturer_id = auth.uid());

drop policy if exists "alerts_delete_lecturer_own" on public.alerts;
create policy "alerts_delete_lecturer_own"
on public.alerts
for delete
to authenticated
using (lecturer_id = auth.uid());

