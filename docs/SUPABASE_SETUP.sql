-- =====================================================================
-- SUPABASE PROVISIONING SCRIPT FOR FLOOD GUARD AI
-- Run this in the Supabase SQL Editor. ebA0P9LPcldyU3yt
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Profiles Table & Auth Trigger
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text unique not null,
  display_name text,
  role text not null default 'citizen' check (role in ('citizen', 'admin')),
  city text,
  updated_at timestamptz default now()
);

-- Enable RLS on Profiles
alter table public.profiles enable row level security;

create policy "Allow public read access to profiles"
  on public.profiles for select using (true);

create policy "Allow users to update their own profile"
  on public.profiles for update using (auth.uid() = id);

-- Create profile sync trigger
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    case when new.email = 'admin@floodguard.ai' then 'admin' else 'citizen' end
  );
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------
-- 2. Flood Reports & Moderation Table
-- ---------------------------------------------------------------------
create table if not exists public.flood_report_moderation (
  report_id text primary key,
  status text not null check (status in ('pending', 'approved', 'rejected')),
  latitude double precision not null,
  longitude double precision not null,
  description text not null,
  reporter_phone text not null default '',
  ai_label text not null default '',
  observed_water_level text not null default 'medium',
  moderated_at timestamptz not null default now(),
  broadcast_to_map boolean not null default false,
  photo_url text, -- Storage link to bucket
  reporter_id uuid references auth.users on delete set null
);

-- Enable RLS on Reports
alter table public.flood_report_moderation enable row level security;

create policy "Allow public read access to approved reports"
  on public.flood_report_moderation for select
  using (status = 'approved');

create policy "Allow admins to read all reports"
  on public.flood_report_moderation for select
  using (
    exists (
      select 1 from public.profiles 
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

create policy "Allow public to insert reports"
  on public.flood_report_moderation for insert
  with check (true);

create policy "Allow admins to update reports"
  on public.flood_report_moderation for update
  using (
    exists (
      select 1 from public.profiles 
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- ---------------------------------------------------------------------
-- 3. Broadcast Announcements Table
-- ---------------------------------------------------------------------
create table if not exists public.broadcast_announcements (
  id text primary key,
  title text not null default 'Official broadcast',
  summary text not null,
  area text not null default 'Basin-wide',
  severity text not null default 'warning',
  issued_at timestamptz not null default now()
);

-- Enable RLS on Broadcasts
alter table public.broadcast_announcements enable row level security;

create policy "Allow public read access to broadcasts"
  on public.broadcast_announcements for select using (true);

create policy "Allow admins to write broadcasts"
  on public.broadcast_announcements for insert
  with check (
    exists (
      select 1 from public.profiles 
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- Enable Realtime for Broadcast Announcements
alter publication supabase_realtime add table public.broadcast_announcements;
alter publication supabase_realtime add table public.flood_report_moderation;

-- ---------------------------------------------------------------------
-- 4. User Device Tokens (FCM)
-- ---------------------------------------------------------------------
create table if not exists public.user_device_tokens (
  user_id uuid references auth.users on delete cascade,
  token text primary key,
  updated_at timestamptz default now()
);

-- Enable RLS on Tokens
alter table public.user_device_tokens enable row level security;

create policy "Allow users to manage own tokens"
  on public.user_device_tokens for all
  using (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 5. Storage Bucket Setup Instructions
-- ---------------------------------------------------------------------
-- In your Supabase Dashboard:
-- 1. Go to Storage.
-- 2. Create a new public bucket named "report_photos".
-- 3. Create the following Storage policies for "report_photos":
--    - "Allow public uploads" (Insert: select true)
--    - "Allow public read" (Select: select true)
