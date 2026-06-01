-- ============================================================
-- Memory Maker FINAL DYNAMIC RPC FIX
-- This patch is made for existing Supabase projects where some
-- columns may be text, enum, nullable, or custom. It creates the
-- app RPC functions used by the Flutter app and avoids hard-coded
-- enum inserts that caused gallery/upload/support failures.
-- Safe to run multiple times.
-- ============================================================

create extension if not exists pgcrypto;

-- -----------------------------
-- Base tables / required columns
-- -----------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  avatar_base64 text,
  avatar_content_type text,
  role text default 'user',
  is_super_admin boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists phone text,
  add column if not exists avatar_url text,
  add column if not exists avatar_object_key text,
  add column if not exists avatar_base64 text,
  add column if not exists avatar_content_type text,
  add column if not exists profile_picture_url text,
  add column if not exists profile_photo_url text,
  add column if not exists image_url text,
  add column if not exists photo_url text,
  add column if not exists role text default 'user',
  add column if not exists is_super_admin boolean default false,
  add column if not exists last_seen_at timestamptz,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  title text,
  name text,
  slug text,
  event_kind text default 'Event',
  event_type text default 'Event',
  status text default 'active',
  beta_free_access boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.events
  add column if not exists owner_id uuid references auth.users(id) on delete cascade,
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists title text,
  add column if not exists name text,
  add column if not exists slug text,
  add column if not exists event_kind text default 'Event',
  add column if not exists event_start_at timestamptz,
  add column if not exists beta_free_access boolean default true,
  add column if not exists gallery_cover_url text,
  add column if not exists public_beta_notes text,
  add column if not exists plan_code text default 'beta',
  add column if not exists duration_code text default 'beta',
  add column if not exists duration_days int default 30,
  add column if not exists max_guests int default 50,
  add column if not exists max_total_bytes bigint default 1073741824,
  add column if not exists max_photos_per_guest int default 50,
  add column if not exists used_total_bytes bigint default 0,
  add column if not exists paid_at timestamptz,
  add column if not exists stripe_payment_status text default 'beta_free',
  add column if not exists status text default 'active',
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.event_guests (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  email text,
  display_name text,
  status text default 'invited',
  invited_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.event_guests
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists email text,
  add column if not exists display_name text,
  add column if not exists status text default 'invited',
  add column if not exists invited_at timestamptz,
  add column if not exists accepted_at timestamptz,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.media_uploads (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  guest_id uuid references public.event_guests(id) on delete set null,
  uploader_id uuid references auth.users(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  uploader_email text,
  media_type text default 'photo',
  title text,
  caption text,
  status text default 'approved',
  file_url text,
  thumbnail_url text,
  object_key text,
  storage_key text,
  original_filename text,
  content_type text,
  byte_size bigint default 0,
  width integer,
  height integer,
  print_count integer default 0,
  share_count integer default 0,
  download_count integer default 0,
  deleted_at timestamptz,
  uploaded_at timestamptz default now(),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.media_uploads
  add column if not exists guest_id uuid references public.event_guests(id) on delete set null,
  add column if not exists uploader_id uuid references auth.users(id) on delete set null,
  add column if not exists user_id uuid references auth.users(id) on delete set null,
  add column if not exists uploader_email text,
  add column if not exists title text,
  add column if not exists caption text,
  add column if not exists status text default 'approved',
  add column if not exists file_url text,
  add column if not exists thumbnail_url text,
  add column if not exists object_key text,
  add column if not exists storage_key text,
  add column if not exists original_filename text,
  add column if not exists content_type text,
  add column if not exists byte_size bigint default 0,
  add column if not exists width integer,
  add column if not exists height integer,
  add column if not exists print_count integer default 0,
  add column if not exists share_count integer default 0,
  add column if not exists download_count integer default 0,
  add column if not exists deleted_at timestamptz,
  add column if not exists uploaded_at timestamptz default now(),
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create table if not exists public.media_blobs (
  upload_id uuid primary key references public.media_uploads(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  original_filename text not null default 'upload.jpg',
  original_content_type text not null default 'image/jpeg',
  original_byte_size bigint not null default 0,
  compressed_content_type text not null default 'image/jpeg',
  compressed_byte_size bigint not null default 0,
  compressed_base64 text,
  width integer,
  height integer,
  created_at timestamptz not null default now()
);

alter table public.media_blobs
  add column if not exists original_filename text not null default 'upload.jpg',
  add column if not exists original_content_type text not null default 'image/jpeg',
  add column if not exists original_byte_size bigint not null default 0,
  add column if not exists compressed_content_type text not null default 'image/jpeg',
  add column if not exists compressed_byte_size bigint not null default 0,
  add column if not exists compressed_base64 text,
  add column if not exists width integer,
  add column if not exists height integer,
  add column if not exists created_at timestamptz not null default now();

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null,
  message text,
  admin_reply text,
  status text default 'open',
  priority text default 'normal',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.support_tickets
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists subject text,
  add column if not exists message text,
  add column if not exists admin_reply text,
  add column if not exists status text default 'open',
  add column if not exists priority text default 'normal',
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

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

alter table public.user_notifications
  add column if not exists event_id uuid references public.events(id) on delete cascade,
  add column if not exists title text,
  add column if not exists body text,
  add column if not exists status text default 'unread',
  add column if not exists created_at timestamptz default now(),
  add column if not exists read_at timestamptz;

-- -----------------------------
-- Utility helpers for dynamic inserts against text/enum/custom columns
-- -----------------------------
create or replace function public.mm_col_exists(p_table text, p_col text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from information_schema.columns
    where table_schema='public' and table_name=p_table and column_name=p_col
  );
$$;

create or replace function public.mm_sql_value(p_table text, p_col text, p_value text)
returns text
language plpgsql
stable
as $$
declare
  v_schema text;
  v_type text;
  v_typtype text;
  v_enum text;
begin
  select n.nspname, t.typname, t.typtype
  into v_schema, v_type, v_typtype
  from pg_attribute a
  join pg_class c on c.oid = a.attrelid
  join pg_namespace cn on cn.oid = c.relnamespace
  join pg_type t on t.oid = a.atttypid
  join pg_namespace n on n.oid = t.typnamespace
  where cn.nspname = 'public'
    and c.relname = p_table
    and a.attname = p_col
    and a.attnum > 0
    and not a.attisdropped
  limit 1;

  if v_type is null then
    return 'null';
  end if;

  if p_value is null then
    return 'null';
  end if;

  if v_typtype = 'e' then
    select e.enumlabel into v_enum
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = v_type
      and lower(e.enumlabel) = lower(p_value)
    order by e.enumsortorder
    limit 1;

    if v_enum is null then
      select e.enumlabel into v_enum
      from pg_enum e
      join pg_type t on t.oid = e.enumtypid
      where t.typname = v_type
      order by e.enumsortorder
      limit 1;
    end if;

    return quote_literal(v_enum) || '::' || quote_ident(v_schema) || '.' || quote_ident(v_type);
  end if;

  if v_type = 'uuid' then
    return quote_literal(p_value) || '::uuid';
  elsif v_type in ('int2','int4','int8','float4','float8','numeric') then
    return coalesce(nullif(regexp_replace(p_value, '[^0-9\.-]', '', 'g'), ''), '0');
  elsif v_type = 'bool' then
    return case when lower(p_value) in ('true','t','1','yes') then 'true' else 'false' end;
  elsif v_type in ('timestamptz','timestamp','date') then
    return quote_literal(p_value) || '::' || v_type;
  else
    return quote_literal(p_value);
  end if;
end;
$$;

create or replace function public.mm_add_insert_value(
  p_cols text[], p_vals text[], p_table text, p_col text, p_value text,
  out cols text[], out vals text[]
)
returns record
language plpgsql
stable
as $$
begin
  cols := p_cols;
  vals := p_vals;
  if public.mm_col_exists(p_table, p_col) then
    cols := cols || quote_ident(p_col);
    vals := vals || public.mm_sql_value(p_table, p_col, p_value);
  end if;
end;
$$;

-- indexes
create index if not exists events_owner_id_idx on public.events(owner_id);
create index if not exists events_user_id_idx on public.events(user_id);
create index if not exists events_slug_idx on public.events(slug);
create index if not exists event_guests_event_id_idx on public.event_guests(event_id);
create index if not exists event_guests_user_id_idx on public.event_guests(user_id);
create index if not exists media_uploads_event_id_idx on public.media_uploads(event_id);
create index if not exists media_uploads_uploader_id_idx on public.media_uploads(uploader_id);
create index if not exists media_uploads_user_id_idx on public.media_uploads(user_id);
create index if not exists media_blobs_event_id_idx on public.media_blobs(event_id);
create index if not exists media_blobs_owner_id_idx on public.media_blobs(owner_id);

-- basic cleanup/backfill
update public.events set owner_id = user_id where owner_id is null and user_id is not null;
update public.events set user_id = owner_id where user_id is null and owner_id is not null;
update public.events set title = coalesce(title, name, 'Memory Gallery') where title is null;
update public.events set name = coalesce(name, title, 'Memory Gallery') where name is null;
update public.events set slug = lower(regexp_replace(coalesce(slug, title, name, id::text), '[^a-zA-Z0-9]+', '-', 'g')) where slug is null;
update public.media_uploads set uploader_id = user_id where uploader_id is null and user_id is not null;
update public.media_uploads set user_id = uploader_id where user_id is null and uploader_id is not null;
update public.media_uploads set original_filename = coalesce(original_filename, object_key, storage_key, 'memory.jpg') where original_filename is null;
update public.media_uploads set created_at = coalesce(created_at, uploaded_at, now()) where created_at is null;
update public.media_uploads set updated_at = coalesce(updated_at, uploaded_at, created_at, now()) where updated_at is null;

-- Relax defaults on common columns where old schemas had NOT NULL/no default.
do $$
declare r record; enum_label text; type_name text; type_schema text;
begin
  for r in
    select table_name, column_name, udt_name, data_type
    from information_schema.columns
    where table_schema='public'
      and table_name in ('events','media_uploads','support_tickets','user_notifications')
      and is_nullable='NO'
      and column_default is null
      and column_name not in ('id','event_id','upload_id')
  loop
    begin
      select n.nspname, t.typname into type_schema, type_name
      from pg_type t join pg_namespace n on n.oid=t.typnamespace
      where t.typname = r.udt_name limit 1;

      if exists (select 1 from pg_type t where t.typname=r.udt_name and t.typtype='e') then
        select e.enumlabel into enum_label
        from pg_enum e join pg_type t on t.oid=e.enumtypid
        where t.typname=r.udt_name order by e.enumsortorder limit 1;
        execute format('alter table public.%I alter column %I set default %L::%I.%I', r.table_name, r.column_name, enum_label, type_schema, type_name);
      elsif r.udt_name = 'uuid' then
        execute format('alter table public.%I alter column %I set default auth.uid()', r.table_name, r.column_name);
      elsif r.udt_name in ('text','varchar') then
        execute format('alter table public.%I alter column %I set default %L', r.table_name, r.column_name, '');
      elsif r.udt_name in ('int2','int4','int8','numeric','float4','float8') then
        execute format('alter table public.%I alter column %I set default 0', r.table_name, r.column_name);
      elsif r.udt_name = 'bool' then
        execute format('alter table public.%I alter column %I set default false', r.table_name, r.column_name);
      elsif r.udt_name in ('timestamptz','timestamp','date') then
        execute format('alter table public.%I alter column %I set default now()', r.table_name, r.column_name);
      end if;
    exception when others then
      null;
    end;
  end loop;
end $$;

-- -----------------------------
-- RLS policies
-- -----------------------------
alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.event_guests enable row level security;
alter table public.media_uploads enable row level security;
alter table public.media_blobs enable row level security;
alter table public.support_tickets enable row level security;
alter table public.user_notifications enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_service_all" on public.profiles;
create policy "profiles_select_own" on public.profiles for select using (id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_service_all" on public.profiles for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create or replace function public.is_event_owner(p_event_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.events e
    where e.id = p_event_id
      and (e.owner_id = auth.uid() or e.user_id = auth.uid())
  );
$$;
grant execute on function public.is_event_owner(uuid) to authenticated;

drop policy if exists "events_read_own" on public.events;
drop policy if exists "events_insert_own" on public.events;
drop policy if exists "events_update_own" on public.events;
drop policy if exists "events_delete_own" on public.events;
drop policy if exists "events_service_all" on public.events;
drop policy if exists "events_owner_read" on public.events;
drop policy if exists "events_owner_insert" on public.events;
drop policy if exists "events_owner_update" on public.events;
drop policy if exists "events_owner_delete" on public.events;
drop policy if exists "events_select_policy" on public.events;
drop policy if exists "events_insert_policy" on public.events;
drop policy if exists "events_update_policy" on public.events;
drop policy if exists "events_delete_policy" on public.events;
drop policy if exists "users can view own events" on public.events;
drop policy if exists "users can create events" on public.events;
drop policy if exists "users can update own events" on public.events;
drop policy if exists "event admin can read events" on public.events;
drop policy if exists "event guests can read events" on public.events;
create policy "events_read_own" on public.events for select using (owner_id = auth.uid() or user_id = auth.uid());
create policy "events_insert_own" on public.events for insert with check (owner_id = auth.uid() or user_id = auth.uid());
create policy "events_update_own" on public.events for update using (owner_id = auth.uid() or user_id = auth.uid()) with check (owner_id = auth.uid() or user_id = auth.uid());
create policy "events_delete_own" on public.events for delete using (owner_id = auth.uid() or user_id = auth.uid());
create policy "events_service_all" on public.events for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

drop policy if exists "event_guests_own_read" on public.event_guests;
drop policy if exists "event_guests_own_insert" on public.event_guests;
drop policy if exists "event_guests_service_all" on public.event_guests;
drop policy if exists "event_guests_owner_event_read" on public.event_guests;
create policy "event_guests_own_read" on public.event_guests for select using (user_id = auth.uid() or public.is_event_owner(event_id));
create policy "event_guests_own_insert" on public.event_guests for insert with check (user_id = auth.uid() or public.is_event_owner(event_id));
create policy "event_guests_service_all" on public.event_guests for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

drop policy if exists "media_uploads_read" on public.media_uploads;
drop policy if exists "media_uploads_insert" on public.media_uploads;
drop policy if exists "media_uploads_update" on public.media_uploads;
drop policy if exists "media_uploads_service_all" on public.media_uploads;
drop policy if exists "media_uploads_owner_read" on public.media_uploads;
drop policy if exists "media_uploads_uploader_read" on public.media_uploads;
drop policy if exists "media_uploads_insert_own" on public.media_uploads;
drop policy if exists "media_uploads_update_own" on public.media_uploads;
create policy "media_uploads_read" on public.media_uploads for select using (uploader_id = auth.uid() or user_id = auth.uid() or public.is_event_owner(event_id));
create policy "media_uploads_insert" on public.media_uploads for insert with check (uploader_id = auth.uid() or user_id = auth.uid() or public.is_event_owner(event_id));
create policy "media_uploads_update" on public.media_uploads for update using (uploader_id = auth.uid() or user_id = auth.uid() or public.is_event_owner(event_id)) with check (uploader_id = auth.uid() or user_id = auth.uid() or public.is_event_owner(event_id));
create policy "media_uploads_service_all" on public.media_uploads for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

drop policy if exists "media_blobs_read" on public.media_blobs;
drop policy if exists "media_blobs_insert" on public.media_blobs;
drop policy if exists "media_blobs_update" on public.media_blobs;
drop policy if exists "media_blobs_service_all" on public.media_blobs;
create policy "media_blobs_read" on public.media_blobs for select using (owner_id = auth.uid() or public.is_event_owner(event_id));
create policy "media_blobs_insert" on public.media_blobs for insert with check (owner_id = auth.uid() or public.is_event_owner(event_id));
create policy "media_blobs_update" on public.media_blobs for update using (owner_id = auth.uid() or public.is_event_owner(event_id)) with check (owner_id = auth.uid() or public.is_event_owner(event_id));
create policy "media_blobs_service_all" on public.media_blobs for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

drop policy if exists "support_tickets_own_read" on public.support_tickets;
drop policy if exists "support_tickets_own_insert" on public.support_tickets;
drop policy if exists "support_tickets_own_update" on public.support_tickets;
drop policy if exists "support_tickets_service_all" on public.support_tickets;
create policy "support_tickets_own_read" on public.support_tickets for select using (user_id = auth.uid());
create policy "support_tickets_own_insert" on public.support_tickets for insert with check (user_id = auth.uid());
create policy "support_tickets_own_update" on public.support_tickets for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "support_tickets_service_all" on public.support_tickets for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

drop policy if exists "user_notifications_own_read" on public.user_notifications;
drop policy if exists "user_notifications_own_insert" on public.user_notifications;
drop policy if exists "user_notifications_own_update" on public.user_notifications;
drop policy if exists "user_notifications_service_all" on public.user_notifications;
create policy "user_notifications_own_read" on public.user_notifications for select using (user_id = auth.uid());
create policy "user_notifications_own_insert" on public.user_notifications for insert with check (user_id = auth.uid());
create policy "user_notifications_own_update" on public.user_notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_notifications_service_all" on public.user_notifications for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

-- -----------------------------
-- Auth profile trigger
-- -----------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, is_super_admin, created_at, updated_at)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)), 'user', false, now(), now())
  on conflict (id) do update set full_name = coalesce(public.profiles.full_name, excluded.full_name), updated_at = now();
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

insert into public.profiles (id, full_name, role, is_super_admin, created_at, updated_at)
select u.id, coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)), 'user', false, now(), now()
from auth.users u left join public.profiles p on p.id = u.id where p.id is null;

-- -----------------------------
-- RPC: create/list galleries
-- -----------------------------
create or replace function public.app_create_event_v2(p_title text, p_kind text)
returns public.events
language plpgsql
security definer
set search_path = public
as $$
declare
  v_event public.events;
  v_uid uuid := auth.uid();
  v_title text := coalesce(nullif(trim(p_title), ''), 'Memory Gallery');
  v_kind text := coalesce(nullif(trim(p_kind), ''), 'Event');
  v_slug text := lower(regexp_replace(coalesce(nullif(trim(p_title), ''), 'Memory Gallery'), '[^a-zA-Z0-9]+', '-', 'g')) || '-' || right(extract(epoch from now())::bigint::text, 6);
  cols text[] := array[]::text[];
  vals text[] := array[]::text[];
  sql text;
begin
  if v_uid is null then raise exception 'Not authenticated'; end if;

  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'owner_id', v_uid::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'user_id', v_uid::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'title', v_title) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'name', v_title) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'slug', v_slug) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'event_kind', v_kind) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'event_type', v_kind) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'status', 'active') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'beta_free_access', 'true') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'plan_code', 'beta') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'duration_code', 'beta') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'duration_days', '30') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'max_guests', '50') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'max_total_bytes', '1073741824') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'max_photos_per_guest', '50') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'used_total_bytes', '0') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'paid_at', now()::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'stripe_payment_status', 'beta_free') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'event_start_at', now()::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'created_at', now()::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'events', 'updated_at', now()::text) x;

  sql := 'insert into public.events (' || array_to_string(cols, ',') || ') values (' || array_to_string(vals, ',') || ') returning *';
  execute sql into v_event;
  return v_event;
end;
$$;
grant execute on function public.app_create_event_v2(text, text) to authenticated;

create or replace function public.app_create_event(p_title text, p_kind text)
returns public.events
language sql
security definer
set search_path = public
as $$ select * from public.app_create_event_v2(p_title, p_kind); $$;
grant execute on function public.app_create_event(text, text) to authenticated;

create or replace function public.app_list_events_v2()
returns table (
  id uuid,
  title text,
  name text,
  slug text,
  event_kind text,
  event_type text,
  status text,
  gallery_cover_url text,
  event_start_at timestamptz,
  created_at timestamptz,
  media_count bigint
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    e.id,
    coalesce(e.title, e.name, 'Memory Gallery')::text,
    coalesce(e.name, e.title, 'Memory Gallery')::text,
    coalesce(e.slug, e.id::text)::text,
    coalesce(e.event_kind::text, e.event_type::text, 'Event')::text,
    coalesce(e.event_type::text, e.event_kind::text, 'Event')::text,
    coalesce(e.status::text, 'active')::text,
    e.gallery_cover_url,
    e.event_start_at,
    e.created_at,
    (select count(*) from public.media_uploads m where m.event_id = e.id and m.deleted_at is null)::bigint
  from public.events e
  where e.owner_id = auth.uid()
     or e.user_id = auth.uid()
     or exists (
       select 1 from public.event_guests g
       where g.event_id = e.id
         and (g.user_id = auth.uid() or lower(coalesce(g.email,'')) = lower(coalesce(auth.jwt()->>'email','')))
     )
  order by e.created_at desc nulls last;
end;
$$;
grant execute on function public.app_list_events_v2() to authenticated;

create or replace function public.app_list_events()
returns table (
  id uuid,
  title text,
  name text,
  slug text,
  event_kind text,
  event_type text,
  status text,
  gallery_cover_url text,
  event_start_at timestamptz,
  created_at timestamptz,
  media_count bigint
)
language sql
security definer
set search_path = public
as $$ select * from public.app_list_events_v2(); $$;
grant execute on function public.app_list_events() to authenticated;

-- -----------------------------
-- RPC: list/upload media
-- -----------------------------
create or replace function public.app_list_media_v2(p_event_id uuid)
returns table (
  id uuid,
  event_id uuid,
  original_filename text,
  file_url text,
  thumbnail_url text,
  object_key text,
  storage_key text,
  status text,
  caption text,
  uploaded_at timestamptz,
  created_at timestamptz,
  data_url text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    m.id,
    m.event_id,
    coalesce(m.original_filename, m.object_key, m.storage_key, 'memory.jpg')::text,
    m.file_url,
    m.thumbnail_url,
    m.object_key,
    m.storage_key,
    coalesce(m.status::text, 'approved')::text,
    m.caption,
    m.uploaded_at,
    m.created_at,
    case when b.compressed_base64 is not null
      then ('data:' || coalesce(b.compressed_content_type, 'image/jpeg') || ';base64,' || b.compressed_base64)::text
      else null
    end as data_url
  from public.media_uploads m
  left join public.media_blobs b on b.upload_id = m.id
  where m.event_id = p_event_id
    and m.deleted_at is null
    and (
      m.uploader_id = auth.uid()
      or m.user_id = auth.uid()
      or public.is_event_owner(m.event_id)
      or exists (
        select 1 from public.event_guests g
        where g.event_id = m.event_id
          and (g.user_id = auth.uid() or lower(coalesce(g.email,'')) = lower(coalesce(auth.jwt()->>'email','')))
      )
    )
  order by coalesce(m.created_at, m.uploaded_at) desc nulls last;
$$;
grant execute on function public.app_list_media_v2(uuid) to authenticated;

create or replace function public.app_list_media(p_event_id uuid)
returns table (
  id uuid,
  event_id uuid,
  original_filename text,
  file_url text,
  thumbnail_url text,
  object_key text,
  storage_key text,
  status text,
  caption text,
  uploaded_at timestamptz,
  created_at timestamptz,
  data_url text
)
language sql
security definer
set search_path = public
stable
as $$ select * from public.app_list_media_v2(p_event_id); $$;
grant execute on function public.app_list_media(uuid) to authenticated;

create or replace function public.app_upload_photo_v2(
  p_event_id uuid,
  p_filename text,
  p_content_type text,
  p_original_content_type text,
  p_original_bytes bigint,
  p_compressed_bytes bigint,
  p_compressed_base64 text,
  p_width integer,
  p_height integer,
  p_caption text
)
returns public.media_uploads
language plpgsql
security definer
set search_path = public
as $$
declare
  v_upload public.media_uploads;
  v_uid uuid := auth.uid();
  v_email text := coalesce(auth.jwt()->>'email','');
  v_guest_id uuid;
  v_upload_id uuid;
  cols text[] := array[]::text[];
  vals text[] := array[]::text[];
  sql text;
begin
  if v_uid is null then raise exception 'Not authenticated'; end if;

  if not exists (select 1 from public.events where id = p_event_id) then
    raise exception 'Gallery not found';
  end if;

  select id into v_guest_id
  from public.event_guests
  where event_id = p_event_id
    and (user_id = v_uid or lower(coalesce(email,'')) = lower(v_email))
  order by created_at desc nulls last
  limit 1;

  if v_guest_id is null then
    insert into public.event_guests (event_id, user_id, email, display_name, status, invited_at, accepted_at, created_at, updated_at)
    values (p_event_id, v_uid, lower(v_email), coalesce(nullif(split_part(v_email,'@',1),''),'Guest'), 'accepted', now(), now(), now(), now())
    returning id into v_guest_id;
  end if;

  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'event_id', p_event_id::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'guest_id', v_guest_id::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'uploader_id', v_uid::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'user_id', v_uid::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'uploader_email', v_email) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'media_type', 'photo') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'kind', 'photo') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'title', coalesce(nullif(trim(p_filename), ''), 'memory.jpg')) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'caption', coalesce(p_caption,'')) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'status', 'approved') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'object_key', 'db-media-pending') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'storage_key', 'db-media-pending') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'original_filename', coalesce(nullif(trim(p_filename), ''), 'memory.jpg')) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'content_type', coalesce(nullif(trim(p_content_type), ''), 'image/jpeg')) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'byte_size', coalesce(p_compressed_bytes, 0)::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'width', coalesce(p_width, 0)::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'height', coalesce(p_height, 0)::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'print_count', '0') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'share_count', '0') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'download_count', '0') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'uploaded_at', now()::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'created_at', now()::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'media_uploads', 'updated_at', now()::text) x;

  sql := 'insert into public.media_uploads (' || array_to_string(cols, ',') || ') values (' || array_to_string(vals, ',') || ') returning *';
  execute sql into v_upload;
  v_upload_id := v_upload.id;

  update public.media_uploads
  set object_key = 'db-media/' || v_upload_id::text,
      storage_key = 'db-media/' || v_upload_id::text,
      updated_at = now()
  where id = v_upload_id
  returning * into v_upload;

  insert into public.media_blobs (
    upload_id, event_id, owner_id, original_filename, original_content_type,
    original_byte_size, compressed_content_type, compressed_byte_size,
    compressed_base64, width, height, created_at
  ) values (
    v_upload_id, p_event_id, v_uid, coalesce(nullif(trim(p_filename), ''), 'memory.jpg'),
    coalesce(nullif(trim(p_original_content_type), ''), 'image/jpeg'), coalesce(p_original_bytes,0),
    coalesce(nullif(trim(p_content_type), ''), 'image/jpeg'), coalesce(p_compressed_bytes,0),
    p_compressed_base64, p_width, p_height, now()
  )
  on conflict (upload_id) do update set
    compressed_base64 = excluded.compressed_base64,
    compressed_content_type = excluded.compressed_content_type,
    compressed_byte_size = excluded.compressed_byte_size,
    width = excluded.width,
    height = excluded.height;

  begin
    insert into public.user_notifications (user_id, event_id, title, body, status, created_at)
    values (v_uid, p_event_id, 'Photo uploaded', 'Your memory was uploaded successfully.', 'unread', now());
  exception when others then null;
  end;

  return v_upload;
end;
$$;
grant execute on function public.app_upload_photo_v2(uuid, text, text, text, bigint, bigint, text, integer, integer, text) to authenticated;

-- -----------------------------
-- RPC: support
-- -----------------------------
create or replace function public.app_create_support_ticket_v2(p_subject text, p_message text)
returns public.support_tickets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.support_tickets;
  v_uid uuid := auth.uid();
  cols text[] := array[]::text[];
  vals text[] := array[]::text[];
  sql text;
begin
  if v_uid is null then raise exception 'Not authenticated'; end if;

  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'support_tickets', 'user_id', v_uid::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'support_tickets', 'subject', coalesce(nullif(trim(p_subject), ''), 'Support request')) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'support_tickets', 'message', coalesce(p_message,'')) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'support_tickets', 'status', 'open') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'support_tickets', 'priority', 'normal') x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'support_tickets', 'created_at', now()::text) x;
  select x.cols, x.vals into cols, vals from public.mm_add_insert_value(cols, vals, 'support_tickets', 'updated_at', now()::text) x;

  sql := 'insert into public.support_tickets (' || array_to_string(cols, ',') || ') values (' || array_to_string(vals, ',') || ') returning *';
  execute sql into v_ticket;

  begin
    insert into public.user_notifications (user_id, title, body, status, created_at)
    values (v_uid, 'Support request sent', 'We received your support request and will reply soon.', 'unread', now());
  exception when others then null;
  end;

  return v_ticket;
end;
$$;
grant execute on function public.app_create_support_ticket_v2(text, text) to authenticated;

create or replace function public.app_create_support_ticket(p_subject text, p_message text)
returns public.support_tickets
language sql
security definer
set search_path = public
as $$ select * from public.app_create_support_ticket_v2(p_subject, p_message); $$;
grant execute on function public.app_create_support_ticket(text, text) to authenticated;

-- updated_at triggers
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
drop trigger if exists set_events_updated_at on public.events;
create trigger set_events_updated_at before update on public.events for each row execute function public.set_updated_at();
drop trigger if exists set_media_uploads_updated_at on public.media_uploads;
create trigger set_media_uploads_updated_at before update on public.media_uploads for each row execute function public.set_updated_at();
drop trigger if exists set_support_tickets_updated_at on public.support_tickets;
create trigger set_support_tickets_updated_at before update on public.support_tickets for each row execute function public.set_updated_at();

-- admin backfill; change email if needed
update public.profiles
set is_super_admin = true, role = 'super_admin', updated_at = now()
where id in (select id from auth.users where lower(email) = lower('admin@memorymaker.com'));

-- DONE
