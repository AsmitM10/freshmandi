-- FreshMandi Phase 1: Auth + Restaurant Registration
-- Safe to run once on a fresh Supabase project (Supabase SQL Editor > New query > Run).
-- Idempotent guards are included so a second accidental run does not error out.

-- ============================================================================
-- EXTENSIONS
-- ============================================================================
create extension if not exists pgcrypto; -- gen_random_uuid()

-- ============================================================================
-- SHARED TRIGGER: keep updated_at current
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ============================================================================
-- TABLE: profiles
-- One row per auth.users row. Created automatically by the trigger below —
-- the Flutter client never inserts into this table directly.
-- ============================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  phone_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_phone_format check (
    phone_number is null or phone_number ~ '^\+91[0-9]{10}$'
  )
);

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile row whenever a new auth user is created (covers the
-- phone-OTP signup path, where the user is created at verification time).
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, phone_number)
  values (new.id, new.phone)
  on conflict (id) do update set phone_number = excluded.phone_number;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- ============================================================================
-- TABLE: restaurants
-- One row per restaurant, one restaurant per auth user (user_id is unique).
-- account_status starts at 'pending' and can only move to 'approved' /
-- 'rejected' / 'suspended' via a privileged (service-role) path — see RLS below.
-- ============================================================================
create table if not exists public.restaurants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  restaurant_name text not null,
  owner_name text not null,
  phone_number text not null,
  account_status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint restaurants_name_not_blank check (length(trim(restaurant_name)) > 0),
  constraint restaurants_owner_not_blank check (length(trim(owner_name)) > 0),
  constraint restaurants_phone_format check (phone_number ~ '^\+91[0-9]{10}$'),
  constraint restaurants_account_status_valid check (
    account_status in ('pending', 'approved', 'rejected', 'suspended')
  ),
  constraint restaurants_phone_unique unique (phone_number)
);

create index if not exists restaurants_account_status_idx on public.restaurants (account_status);

drop trigger if exists set_restaurants_updated_at on public.restaurants;
create trigger set_restaurants_updated_at
  before update on public.restaurants
  for each row execute function public.set_updated_at();

-- ============================================================================
-- TABLE: restaurant_documents
-- Stores only a reference to the private Storage object, never the file itself.
-- ============================================================================
create table if not exists public.restaurant_documents (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants (id) on delete cascade,
  document_type text not null default 'fssai_certificate',
  file_name text not null,
  storage_path text not null,
  file_size integer not null,
  mime_type text not null,
  created_at timestamptz not null default now(),
  constraint restaurant_documents_file_size_valid check (
    file_size > 0 and file_size <= 2097152 -- 2 MB
  ),
  constraint restaurant_documents_mime_type_valid check (
    mime_type in ('application/pdf', 'image/jpeg', 'image/jpg', 'image/png')
  )
);

create index if not exists restaurant_documents_restaurant_id_idx
  on public.restaurant_documents (restaurant_id);

-- ============================================================================
-- RPC: is_phone_registered
-- Lets the registration screen check for a duplicate phone number BEFORE the
-- user is authenticated (Supabase phone OTP only creates a session after
-- verification), without exposing any restaurant row data to an anonymous
-- caller. Returns a bare boolean only.
-- ============================================================================
create or replace function public.is_phone_registered(p_phone text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.restaurants where phone_number = p_phone
  );
$$;

revoke all on function public.is_phone_registered(text) from public;
grant execute on function public.is_phone_registered(text) to anon, authenticated;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.profiles enable row level security;
alter table public.restaurants enable row level security;
alter table public.restaurant_documents enable row level security;

-- profiles: a user may only ever see/update their own row. No insert policy
-- for authenticated/anon — rows are created solely by the security-definer
-- trigger above, which bypasses RLS.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated
  using (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- restaurants: users can create exactly one row for themselves, always
-- starting at account_status = 'pending', and can only ever see/update that
-- one row. account_status can never be changed by the authenticated role —
-- the WITH CHECK clause pins it to 'pending' on both insert and update, so
-- approval/rejection/suspension can only happen via a service-role path
-- (which bypasses RLS entirely) in a future admin phase.
drop policy if exists restaurants_select_own on public.restaurants;
create policy restaurants_select_own on public.restaurants
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists restaurants_insert_own on public.restaurants;
create policy restaurants_insert_own on public.restaurants
  for insert to authenticated
  with check (user_id = auth.uid() and account_status = 'pending');

drop policy if exists restaurants_update_own on public.restaurants;
create policy restaurants_update_own on public.restaurants
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and account_status = 'pending');

-- restaurant_documents: ownership is derived through the parent restaurant row.
drop policy if exists restaurant_documents_select_own on public.restaurant_documents;
create policy restaurant_documents_select_own on public.restaurant_documents
  for select to authenticated
  using (
    exists (
      select 1 from public.restaurants r
      where r.id = restaurant_documents.restaurant_id
        and r.user_id = auth.uid()
    )
  );

drop policy if exists restaurant_documents_insert_own on public.restaurant_documents;
create policy restaurant_documents_insert_own on public.restaurant_documents
  for insert to authenticated
  with check (
    exists (
      select 1 from public.restaurants r
      where r.id = restaurant_documents.restaurant_id
        and r.user_id = auth.uid()
    )
  );

-- ============================================================================
-- STORAGE: private fssai-documents bucket
-- Path convention enforced by policy: {auth.uid()}/{restaurant_id}/{filename}
-- ============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'fssai-documents',
  'fssai-documents',
  false,
  2097152,
  array['application/pdf', 'image/jpeg', 'image/jpg', 'image/png']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists fssai_documents_select_own on storage.objects;
create policy fssai_documents_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'fssai-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists fssai_documents_insert_own on storage.objects;
create policy fssai_documents_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'fssai-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists fssai_documents_update_own on storage.objects;
create policy fssai_documents_update_own on storage.objects
  for update to authenticated
  using (
    bucket_id = 'fssai-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'fssai-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists fssai_documents_delete_own on storage.objects;
create policy fssai_documents_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'fssai-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
