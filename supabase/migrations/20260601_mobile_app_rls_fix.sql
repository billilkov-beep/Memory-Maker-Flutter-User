-- Memory Maker mobile app RLS/connectivity fix
-- Run this in Supabase SQL Editor if the app shows "infinite recursion detected in policy for relation events"
-- This removes recursive policies and replaces them with simple owner/user policies for the beta release.

create extension if not exists pgcrypto;

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists phone text,
  add column if not exists avatar_url text,
  add column if not exists role text default 'user',
  add column if not exists is_super_admin boolean default false,
  add column if not exists last_seen_at timestamptz,
  add column if not exists updated_at timestamptz default now();

alter table public.events
  add column if not exists owner_id uuid references auth.users(id) on delete cascade,
  add column if not exists slug text,
  add column if not exists event_kind text default 'Event',
  add column if not exists status text default 'active',
  add column if not exists event_start_at timestamptz,
  add column if not exists plan_code text default 'beta',
  add column if not exists duration_code text default 'beta',
  add column if not exists duration_days integer default 30,
  add column if not exists max_guests integer default 50,
  add column if not exists max_total_bytes bigint default 1073741824,
  add column if not exists max_photos_per_guest integer default 50,
  add column if not exists used_total_bytes bigint default 0,
  add column if not exists beta_free_access boolean default true,
  add column if not exists gallery_cover_url text,
  add column if not exists paid_at timestamptz,
  add column if not exists stripe_payment_status text default 'beta_free',
  add column if not exists updated_at timestamptz default now();

alter table public.event_guests
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists email text,
  add column if not exists display_name text,
  add column if not exists status text default 'accepted',
  add column if not exists invited_at timestamptz,
  add column if not exists accepted_at timestamptz;

alter table public.media_uploads
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists object_key text,
  add column if not exists original_filename text,
  add column if not exists content_type text,
  add column if not exists byte_size bigint default 0,
  add column if not exists status text default 'pending',
  add column if not exists caption text,
  add column if not exists uploaded_at timestamptz,
  add column if not exists created_at timestamptz default now();

create table if not exists public.media_blobs (
  upload_id uuid primary key references public.media_uploads(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  original_filename text not null,
  original_content_type text not null,
  original_byte_size bigint not null default 0,
  compressed_content_type text not null,
  compressed_byte_size bigint not null default 0,
  compressed_base64 text not null,
  width integer,
  height integer,
  created_at timestamptz not null default now()
);

create table if not exists public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id uuid references public.events(id) on delete cascade,
  title text not null,
  body text,
  status text not null default 'unread',
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null,
  message text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz default now()
);

-- Remove all existing policies on the app tables to eliminate recursive policy loops.
do $$
declare r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename in ('profiles','events','event_guests','media_uploads','media_blobs','user_notifications','support_tickets')
  loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.event_guests enable row level security;
alter table public.media_uploads enable row level security;
alter table public.media_blobs enable row level security;
alter table public.user_notifications enable row level security;
alter table public.support_tickets enable row level security;

-- Profiles
create policy profiles_own_select on public.profiles for select using (id = auth.uid() or auth.role() = 'service_role');
create policy profiles_own_insert on public.profiles for insert with check (id = auth.uid() or auth.role() = 'service_role');
create policy profiles_own_update on public.profiles for update using (id = auth.uid() or auth.role() = 'service_role') with check (id = auth.uid() or auth.role() = 'service_role');

-- Events: owner-only for app beta. No recursive event_guests checks here.
create policy events_owner_select on public.events for select using (owner_id = auth.uid() or auth.role() = 'service_role');
create policy events_owner_insert on public.events for insert with check (owner_id = auth.uid() or auth.role() = 'service_role');
create policy events_owner_update on public.events for update using (owner_id = auth.uid() or auth.role() = 'service_role') with check (owner_id = auth.uid() or auth.role() = 'service_role');
create policy events_owner_delete on public.events for delete using (owner_id = auth.uid() or auth.role() = 'service_role');

-- Event guests: user can see own guest row; event owner can manage guests.
create policy event_guests_user_or_owner_select on public.event_guests for select using (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = event_guests.event_id and e.owner_id = auth.uid())
);
create policy event_guests_user_or_owner_insert on public.event_guests for insert with check (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = event_guests.event_id and e.owner_id = auth.uid())
);
create policy event_guests_user_or_owner_update on public.event_guests for update using (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = event_guests.event_id and e.owner_id = auth.uid())
) with check (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = event_guests.event_id and e.owner_id = auth.uid())
);

-- Media uploads: uploader or event owner can read/write.
create policy media_uploads_user_or_owner_select on public.media_uploads for select using (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_uploads.event_id and e.owner_id = auth.uid())
);
create policy media_uploads_user_or_owner_insert on public.media_uploads for insert with check (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_uploads.event_id and e.owner_id = auth.uid())
);
create policy media_uploads_user_or_owner_update on public.media_uploads for update using (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_uploads.event_id and e.owner_id = auth.uid())
) with check (
  user_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_uploads.event_id and e.owner_id = auth.uid())
);

-- Media blobs: owner or event owner can read/write. This lets app display web/mobile uploaded images.
create policy media_blobs_owner_select on public.media_blobs for select using (
  owner_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_blobs.event_id and e.owner_id = auth.uid())
);
create policy media_blobs_owner_insert on public.media_blobs for insert with check (
  owner_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_blobs.event_id and e.owner_id = auth.uid())
);
create policy media_blobs_owner_update on public.media_blobs for update using (
  owner_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_blobs.event_id and e.owner_id = auth.uid())
) with check (
  owner_id = auth.uid()
  or auth.role() = 'service_role'
  or exists (select 1 from public.events e where e.id = media_blobs.event_id and e.owner_id = auth.uid())
);

-- Notifications and support
create policy user_notifications_own_select on public.user_notifications for select using (user_id = auth.uid() or auth.role() = 'service_role');
create policy user_notifications_own_update on public.user_notifications for update using (user_id = auth.uid() or auth.role() = 'service_role') with check (user_id = auth.uid() or auth.role() = 'service_role');
create policy support_tickets_own_select on public.support_tickets for select using (user_id = auth.uid() or auth.role() = 'service_role');
create policy support_tickets_own_insert on public.support_tickets for insert with check (user_id = auth.uid() or auth.role() = 'service_role');
create policy support_tickets_own_update on public.support_tickets for update using (user_id = auth.uid() or auth.role() = 'service_role') with check (user_id = auth.uid() or auth.role() = 'service_role');

-- Ensure every new Auth user gets a profile row.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, created_at, updated_at)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)), 'user', now(), now())
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
