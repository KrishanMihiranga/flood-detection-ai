# Admin broadcast announcements (`broadcast_announcements`)

Administrators use **Profile → Admin · urgent broadcast** to enqueue a bulletin. The app:

1. Inserts **`Official broadcast`** rows into offline **Alerts / notification history** immediately (visible to citizens and admins).
2. `INSERT`s the same bulletin into **`broadcast_announcements`** when `--dart-define=SUPABASE_URL` + `SUPABASE_ANON_KEY` are set.
3. Listens via **Supabase Realtime** (`DashboardShell`) and merges unseen rows—showing an in-app snackbar teaser (not a hardware push).

Firebase Cloud Messaging still needs wiring for genuine OS pushes on locked devices.

## SQL (Supabase)

```sql
create table public.broadcast_announcements (
  id text primary key,
  title text not null default 'Official broadcast',
  summary text not null,
  area text not null default 'Basin-wide',
  severity text not null default 'warning',
  issued_at timestamptz not null default now()
);

-- ⚠ Pilot RLS — lock down before production.
alter table public.broadcast_announcements enable row level security;
create policy "anon broadcast insert pilot"
  on public.broadcast_announcements for insert to anon with check (true);
create policy "anon broadcast select pilot"
  on public.broadcast_announcements for select to anon using (true);
```

Add the table to the Realtime publication (Dashboard → Replication) or SQL:

```sql
alter publication supabase_realtime add table public.broadcast_announcements;
```

## Flutter secrets

Reuse the dart-defines from [`SUPABASE_REPORT_MODERATION.md`](SUPABASE_REPORT_MODERATION.md).

Without Supabase, broadcasts populate **Alerts** on the authoring device only; fleet-wide delivery requires Cloud + realtime or FCM later.
