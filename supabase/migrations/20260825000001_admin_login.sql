-- Admin login: a single, manually-seeded admin, authenticated via Supabase
-- email+password auth instead of phone/SMS OTP — deliberately avoids the
-- Twilio SMS pipeline entirely (the project's trial Twilio account can only
-- deliver OTPs to pre-verified numbers, which doesn't work for an admin
-- test number). The app still shows the same phone-number + 6-digit-code UI
-- as restaurant login; the 6 digits are typed in as a PIN and checked via
-- real Supabase password auth, not sent as an SMS. See AppConfig.adminEmail
-- / AppConfig.adminPhoneDigits and login_screen.dart.
--
-- Superseded from an earlier phone-OTP-based version of this migration
-- (never confirmed applied) — dropped defensively so this file is safe to
-- run regardless of prior state.
drop function if exists public.claim_admin(text);
drop function if exists public.is_admin();
drop table if exists public.admins;

create table public.admins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique references auth.users (id) on delete set null,
  email text not null unique,
  display_name text not null default 'Admin',
  created_at timestamptz not null default now()
);

-- Locked down entirely — no direct select/insert/update policies. All
-- access goes through the SECURITY DEFINER functions below, mirroring the
-- existing `is_phone_registered()` RPC precedent for pre-authorization
-- checks that must not leak row data via RLS.
alter table public.admins enable row level security;

-- The one admin. The auth.users row itself (email + password) must be
-- created manually once via Supabase Dashboard -> Authentication -> Users
-- -> Add User, with this exact email, "Auto Confirm User" checked, and a
-- password of your choosing (typed into the app's 6-digit code boxes as a
-- PIN, so it must be exactly 6 digits).
insert into public.admins (email, display_name)
values ('admin@freshmandi.app', 'Admin')
on conflict (email) do nothing;

-- Called once, right after a successful admin sign-in. Links this admins
-- row to the signed-in auth.users id (first login only) by matching the
-- session's own JWT email — no phone number or client-supplied identifier
-- involved, so there's nothing to spoof.
create or replace function public.claim_admin()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_is_admin boolean;
begin
  if auth.uid() is null then
    return false;
  end if;

  v_email := auth.jwt() ->> 'email';
  if v_email is null then
    return false;
  end if;

  select true into v_is_admin from public.admins where email = v_email limit 1;
  if v_is_admin is null then
    return false;
  end if;

  update public.admins
  set user_id = auth.uid()
  where email = v_email
    and (user_id is null or user_id = auth.uid());

  return true;
end;
$$;

grant execute on function public.claim_admin() to authenticated;

-- Called on session restore (app cold start) once a user_id has already
-- been claimed, so a returning admin doesn't need to re-match by email.
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists(select 1 from public.admins where user_id = auth.uid());
$$;

grant execute on function public.is_admin() to authenticated;
