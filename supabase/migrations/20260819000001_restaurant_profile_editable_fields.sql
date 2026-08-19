-- Adds the fields the new "Edit Details" screen actually needs to save
-- (email, GST number — billing/delivery address already exist from the
-- invoice migration) and fixes a real bug this surfaced: the existing
-- `restaurants_update_own` policy's `with check` pins account_status to
-- 'pending', meaning an *approved* restaurant (the only users who could
-- ever reach this screen — pending/rejected/suspended accounts never get
-- past their status screen) could never update their own row at all.
--
-- Rather than just relaxing the RLS check (which would then rely on every
-- future write path remembering not to touch account_status), a trigger
-- pins account_status to whatever it already was on every update,
-- unconditionally — so account_status is structurally immutable via the
-- `authenticated` role regardless of what any future client-side update
-- sends, and the RLS policy can safely allow profile edits at any
-- account_status.

alter table public.restaurants
  add column if not exists email text,
  add column if not exists gst_number text;

create or replace function public.protect_restaurant_account_status()
returns trigger as $$
begin
  new.account_status := old.account_status;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists protect_restaurants_account_status on public.restaurants;
create trigger protect_restaurants_account_status
  before update on public.restaurants
  for each row execute function public.protect_restaurant_account_status();

drop policy if exists restaurants_update_own on public.restaurants;
create policy restaurants_update_own on public.restaurants
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
