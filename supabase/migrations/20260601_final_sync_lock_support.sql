-- ============================================================
-- Memory Maker FINAL app sync / lock / support SQL
-- Run once in Supabase SQL Editor.
-- This avoids the media_kind/media_type type-mismatch errors.
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- Profiles ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  avatar_url text,
  avatar_object_key text,
  avatar_base64 text,
  avatar_content_type text,
  role text default 'user',
  is_super_admin boolean default false,
  last_seen_at timestamptz,
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
  add column if not exists role text default 'user',
  add column if not exists is_super_admin boolean default false,
  add column if not exists last_seen_at timestamptz,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_service_all" on public.profiles;

create policy "profiles_select_own" on public.profiles for select using (id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_service_all" on public.profiles for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role, is_super_admin, created_at, updated_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    'user',
    false,
    now(),
    now()
  )
  on conflict (id) do update set
    full_name = coalesce(public.profiles.full_name, excluded.full_name),
    updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

insert into public.profiles (id, full_name, role, is_super_admin, created_at, updated_at)
select u.id, coalesce(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)), 'user', false, now(), now()
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- ---------- Events / galleries ----------
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references auth.users(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  title text,
  name text,
  slug text,
  event_type text default 'Event',
  event_kind text default 'Event',
  event_start_at timestamptz,
  beta_free_access boolean default true,
  gallery_cover_url text,
  status text default 'active',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.events
  add column if not exists owner_id uuid references auth.users(id) on delete cascade,
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists title text,
  add column if not exists name text,
  add column if not exists slug text,
  add column if not exists event_type text default 'Event',
  add column if not exists event_kind text default 'Event',
  add column if not exists event_start_at timestamptz,
  add column if not exists beta_free_access boolean default true,
  add column if not exists gallery_cover_url text,
  add column if not exists status text default 'active',
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

update public.events set owner_id = coalesce(owner_id, user_id) where owner_id is null and user_id is not null;
update public.events set user_id = coalesce(user_id, owner_id) where user_id is null and owner_id is not null;
update public.events set title = coalesce(title, name, 'Memory Gallery') where title is null;
update public.events set name = coalesce(name, title, 'Memory Gallery') where name is null;
update public.events set slug = lower(regexp_replace(coalesce(slug, title, id::text), '[^a-zA-Z0-9]+', '-', 'g')) where slug is null;

create index if not exists events_owner_id_idx on public.events(owner_id);
create index if not exists events_user_id_idx on public.events(user_id);
create index if not exists events_slug_idx on public.events(slug);

alter table public.events enable row level security;

drop policy if exists "events_read_own" on public.events;
drop policy if exists "events_insert_own" on public.events;
drop policy if exists "events_update_own" on public.events;
drop policy if exists "events_delete_own" on public.events;
drop policy if exists "events_service_all" on public.events;
drop policy if exists "events_owner_read" on public.events;
drop policy if exists "events_owner_insert" on public.events;
drop policy if exists "events_owner_update" on public.events;
drop policy if exists "events_owner_delete" on public.events;
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

-- ---------- Guests ----------
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

alter table public.event_guests enable row level security;

drop policy if exists "event_guests_own_read" on public.event_guests;
drop policy if exists "event_guests_own_insert" on public.event_guests;
drop policy if exists "event_guests_service_all" on public.event_guests;

create policy "event_guests_own_read" on public.event_guests for select using (user_id = auth.uid() or lower(email) = lower(coalesce(auth.jwt()->>'email','')));
create policy "event_guests_own_insert" on public.event_guests for insert with check (user_id = auth.uid() or lower(email) = lower(coalesce(auth.jwt()->>'email','')));
create policy "event_guests_service_all" on public.event_guests for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

-- ---------- Media ----------
create table if not exists public.media_uploads (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  guest_id uuid references public.event_guests(id) on delete set null,
  uploader_id uuid references auth.users(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  uploader_email text,
  title text,
  caption text,
  status text default 'pending',
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
  add column if not exists status text default 'pending',
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

-- Add media_type/kind only when absent. Do not update/cast existing custom enum columns here.
alter table public.media_uploads add column if not exists media_type text default 'photo';
alter table public.media_uploads add column if not exists kind text default 'photo';

update public.media_uploads set uploader_id = coalesce(uploader_id, user_id) where uploader_id is null and user_id is not null;
update public.media_uploads set user_id = coalesce(user_id, uploader_id) where user_id is null and uploader_id is not null;
update public.media_uploads set original_filename = coalesce(original_filename, object_key, storage_key, 'memory.jpg') where original_filename is null;
update public.media_uploads set created_at = coalesce(created_at, uploaded_at, now()) where created_at is null;
update public.media_uploads set updated_at = coalesce(updated_at, uploaded_at, created_at, now()) where updated_at is null;

create index if not exists media_uploads_event_id_idx on public.media_uploads(event_id);
create index if not exists media_uploads_uploader_id_idx on public.media_uploads(uploader_id);
create index if not exists media_uploads_user_id_idx on public.media_uploads(user_id);

alter table public.media_uploads enable row level security;

drop policy if exists "media_uploads_read" on public.media_uploads;
drop policy if exists "media_uploads_insert" on public.media_uploads;
drop policy if exists "media_uploads_update" on public.media_uploads;
drop policy if exists "media_uploads_service_all" on public.media_uploads;
drop policy if exists "media_uploads_uploader_read" on public.media_uploads;
drop policy if exists "media_uploads_insert_own" on public.media_uploads;
drop policy if exists "media_uploads_update_own" on public.media_uploads;

create policy "media_uploads_read" on public.media_uploads for select using (
  uploader_id = auth.uid() or user_id = auth.uid() or
  exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
);
create policy "media_uploads_insert" on public.media_uploads for insert with check (
  uploader_id = auth.uid() or user_id = auth.uid() or
  exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
);
create policy "media_uploads_update" on public.media_uploads for update using (
  uploader_id = auth.uid() or user_id = auth.uid() or
  exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
) with check (
  uploader_id = auth.uid() or user_id = auth.uid() or
  exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
);
create policy "media_uploads_service_all" on public.media_uploads for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

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

alter table public.media_blobs enable row level security;

drop policy if exists "media_blobs_read" on public.media_blobs;
drop policy if exists "media_blobs_insert" on public.media_blobs;
drop policy if exists "media_blobs_update" on public.media_blobs;
drop policy if exists "media_blobs_service_all" on public.media_blobs;

create policy "media_blobs_read" on public.media_blobs for select using (
  owner_id = auth.uid() or exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
);
create policy "media_blobs_insert" on public.media_blobs for insert with check (
  owner_id = auth.uid() or exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
);
create policy "media_blobs_update" on public.media_blobs for update using (
  owner_id = auth.uid() or exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
) with check (
  owner_id = auth.uid() or exists (select 1 from public.events e where e.id = event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
);
create policy "media_blobs_service_all" on public.media_blobs for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

-- ---------- Support and notifications ----------
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
  add column if not exists admin_reply text,
  add column if not exists status text default 'open',
  add column if not exists priority text default 'normal',
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

alter table public.support_tickets enable row level security;

drop policy if exists "support_tickets_own_read" on public.support_tickets;
drop policy if exists "support_tickets_own_insert" on public.support_tickets;
drop policy if exists "support_tickets_own_update" on public.support_tickets;
drop policy if exists "support_tickets_service_all" on public.support_tickets;

create policy "support_tickets_own_read" on public.support_tickets for select using (user_id = auth.uid());
create policy "support_tickets_own_insert" on public.support_tickets for insert with check (user_id = auth.uid());
create policy "support_tickets_own_update" on public.support_tickets for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "support_tickets_service_all" on public.support_tickets for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

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

alter table public.user_notifications enable row level security;

drop policy if exists "user_notifications_own_read" on public.user_notifications;
drop policy if exists "user_notifications_own_insert" on public.user_notifications;
drop policy if exists "user_notifications_own_update" on public.user_notifications;
drop policy if exists "user_notifications_service_all" on public.user_notifications;

create policy "user_notifications_own_read" on public.user_notifications for select using (user_id = auth.uid());
create policy "user_notifications_own_insert" on public.user_notifications for insert with check (user_id = auth.uid());
create policy "user_notifications_own_update" on public.user_notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "user_notifications_service_all" on public.user_notifications for all using (auth.role() = 'service_role') with check (auth.role() = 'service_role');

-- ---------- RPC functions the mobile app uses ----------
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
as $$
  select
    e.id,
    coalesce(e.title, e.name, 'Memory Gallery') as title,
    e.name,
    coalesce(e.slug, e.id::text) as slug,
    e.event_kind::text as event_kind,
    e.event_type::text as event_type,
    coalesce(e.status, 'active') as status,
    e.gallery_cover_url,
    e.event_start_at,
    e.created_at,
    (select count(*) from public.media_uploads m where m.event_id = e.id and m.deleted_at is null) as media_count
  from public.events e
  where e.owner_id = auth.uid()
     or e.user_id = auth.uid()
     or exists (
       select 1 from public.event_guests g
       where g.event_id = e.id
         and (g.user_id = auth.uid() or lower(g.email) = lower(coalesce(auth.jwt()->>'email','')))
     )
  order by e.created_at desc nulls last;
$$;

grant execute on function public.app_list_events() to authenticated;

create or replace function public.app_create_event(p_title text, p_kind text)
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
declare
  v_uid uuid := auth.uid();
  v_title text := coalesce(nullif(trim(p_title), ''), 'Memory Gallery');
  v_kind text := coalesce(nullif(trim(p_kind), ''), 'Event');
  v_id uuid;
  v_slug text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  v_slug := lower(regexp_replace(v_title, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || right(extract(epoch from now())::bigint::text, 6);

  insert into public.events (
    owner_id, user_id, title, name, slug, event_type, event_kind, status,
    beta_free_access, event_start_at, created_at, updated_at
  ) values (
    v_uid, v_uid, v_title, v_title, v_slug, v_kind, v_kind, 'active',
    true, now(), now(), now()
  ) returning events.id into v_id;

  return query
  select e.id, coalesce(e.title, e.name, 'Memory Gallery'), e.name, coalesce(e.slug, e.id::text),
         e.event_kind::text, e.event_type::text, coalesce(e.status,'active'), e.gallery_cover_url,
         e.event_start_at, e.created_at, 0::bigint
  from public.events e
  where e.id = v_id;
end;
$$;

grant execute on function public.app_create_event(text, text) to authenticated;

create or replace function public.app_list_media(p_event_id uuid)
returns table (
  id uuid,
  event_id uuid,
  original_filename text,
  status text,
  caption text,
  file_url text,
  thumbnail_url text,
  data_url text,
  uploaded_at timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    m.id,
    m.event_id,
    coalesce(m.original_filename, m.object_key, m.storage_key, 'memory.jpg') as original_filename,
    coalesce(m.status, 'pending') as status,
    m.caption,
    m.file_url,
    m.thumbnail_url,
    case
      when b.compressed_base64 is not null then 'data:' || coalesce(b.compressed_content_type, 'image/jpeg') || ';base64,' || b.compressed_base64
      else null
    end as data_url,
    m.uploaded_at,
    m.created_at
  from public.media_uploads m
  left join public.media_blobs b on b.upload_id = m.id
  where m.event_id = p_event_id
    and m.deleted_at is null
    and (
      m.uploader_id = auth.uid()
      or m.user_id = auth.uid()
      or exists (select 1 from public.events e where e.id = m.event_id and (e.owner_id = auth.uid() or e.user_id = auth.uid()))
    )
  order by coalesce(m.created_at, m.uploaded_at) desc nulls last;
$$;

grant execute on function public.app_list_media(uuid) to authenticated;

create or replace function public.app_create_support_ticket(p_subject text, p_message text)
returns table (
  id uuid,
  subject text,
  message text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.support_tickets (user_id, subject, message, status, priority, created_at, updated_at)
  values (v_uid, coalesce(nullif(trim(p_subject), ''), 'Support request'), coalesce(p_message, ''), 'open', 'normal', now(), now())
  returning support_tickets.id into v_id;

  insert into public.user_notifications (user_id, title, body, status, created_at)
  values (v_uid, 'Support request sent', 'We received your support request and will reply soon.', 'unread', now());

  return query
  select t.id, t.subject, coalesce(t.message,''), coalesce(t.status,'open'), t.created_at
  from public.support_tickets t
  where t.id = v_id;
end;
$$;

grant execute on function public.app_create_support_ticket(text, text) to authenticated;

-- ---------- updated_at triggers ----------
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

-- Done.
