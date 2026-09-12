-- Stores each restaurant's FCM registration token(s) so the "order
-- accepted" push (sent by a Supabase Edge Function via the FCM HTTP v1
-- API — see supabase/functions/send-order-accepted-push) knows which
-- device(s) to notify. A restaurant can have more than one row (e.g. the
-- app installed on two phones); the same physical token is unique across
-- the whole table since FCM tokens are already globally unique per
-- app-install, and re-registering (token refresh, reinstall) should
-- update the existing row rather than accumulate duplicates.
create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists device_tokens_restaurant_id_idx on public.device_tokens (restaurant_id);

alter table public.device_tokens enable row level security;

-- A restaurant manages only its own token rows — same auth.uid() ->
-- restaurants.user_id -> restaurants.id ownership chain used everywhere
-- else in this schema (see orders_history migration). The Edge Function
-- that actually sends pushes reads this table with the service role key,
-- which bypasses RLS entirely, so no separate admin/service policy is
-- needed here.
drop policy if exists device_tokens_all_own on public.device_tokens;
create policy device_tokens_all_own on public.device_tokens
  for all to authenticated
  using (
    restaurant_id in (
      select r.id from public.restaurants r where r.user_id = auth.uid()
    )
  )
  with check (
    restaurant_id in (
      select r.id from public.restaurants r where r.user_id = auth.uid()
    )
  );
