# Supabase report moderation & map broadcast

Citizen submissions are queued locally (`FloodReportsRepository`). When an **administrator** approves a report in **Verify report**, the app:

1. Persists **`approved`** (or **`rejected`**) in SharedPreferences and refreshes **green pins** on the Map tab instantly (same device pilot).
2. **Upserts** a row into **`flood_report_moderation`** in Supabase (if configured), so downstream jobs / realtime can fan out alerts to everyone.

## 1. Provision the table

Run in Supabase SQL:

```sql
create table public.flood_report_moderation (
  report_id text primary key,
  status text not null check (status in ('pending', 'approved', 'rejected')),
  latitude double precision not null,
  longitude double precision not null,
  description text not null,
  reporter_phone text not null default '',
  ai_label text not null default '',
  observed_water_level text not null default 'medium',
  moderated_at timestamptz not null default now(),
  broadcast_to_map boolean not null default false
);

-- ⚠ Pilot only — tighten policies before prod.
alter table public.flood_report_moderation enable row level security;
create policy "anon upsert moderation pilot"
  on public.flood_report_moderation for all to anon using (true) with check (true);
```

Rotate or delete that policy once you authenticate moderators properly.

### Realtime (optional, for remote devices hearing the verdict)

Dashboard → Database → Replication → add **`flood_report_moderation`** to the `supabase_realtime` publication (or):

```sql
alter publication supabase_realtime add table public.flood_report_moderation;
```

The Flutter map tab subscribes to changes on this table whenever Supabase URLs are supplied.

## 2. Inject credentials at compile time

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Never commit secrets. For CI/CD, mirror these definitions in masked variables.

Without both defines, moderation still completes **locally** and the debugger prints that Supabase was skipped.
