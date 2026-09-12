-- Generalizes the single-purpose notification plumbing built earlier
-- (order-accepted only, restaurant-only) into the full 4-type system:
-- order_request (-> admin), order_accepted / payment / invoice (->
-- restaurant). All business logic (title/body copy, recipient lookup,
-- payment threshold + duplicate-prevention) lives in the
-- send-notification Edge Function, which uses the service role and so
-- needs no RLS carve-outs of its own — the changes below are just what's
-- needed for the *client* side (registering tokens, reading your own
-- notification history).

-- device_tokens (20260901000001) assumed every token belonged to a
-- restaurant. Admin also needs to receive push (order_request), so a
-- token row is now either "this restaurant's" or "the admin's", never
-- both/neither.
alter table public.device_tokens alter column restaurant_id drop not null;
alter table public.device_tokens add column if not exists is_admin boolean not null default false;

alter table public.device_tokens drop constraint if exists device_tokens_owner_check;
alter table public.device_tokens add constraint device_tokens_owner_check
  check ((restaurant_id is not null and not is_admin) or (restaurant_id is null and is_admin));

drop policy if exists device_tokens_all_own on public.device_tokens;
create policy device_tokens_all_own on public.device_tokens
  for all to authenticated
  using (
    (restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid()))
    or (is_admin and public.is_admin())
  )
  with check (
    (restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid()))
    or (is_admin and public.is_admin())
  );

-- notifications (20260901000002) was restaurant-only and had no
-- structured fields for the payment reminder's amount/dedup state — it
-- was built for a single "order accepted, here's an image" case that
-- this migration supersedes with the general 4-type design.
alter table public.notifications alter column restaurant_id drop not null;
alter table public.notifications add column if not exists to_admin boolean not null default false;
alter table public.notifications add column if not exists amount numeric(12, 2);
alter table public.notifications add column if not exists payment_status text check (payment_status in ('pending', 'paid'));

alter table public.notifications drop constraint if exists notifications_target_check;
alter table public.notifications add constraint notifications_target_check
  check ((restaurant_id is not null and not to_admin) or (restaurant_id is null and to_admin));

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
  for select to authenticated
  using (
    (restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid()))
    or (to_admin and public.is_admin())
  );

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
  for update to authenticated
  using (
    (restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid()))
    or (to_admin and public.is_admin())
  )
  with check (
    (restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid()))
    or (to_admin and public.is_admin())
  );

-- The old admin-insert policy is superseded — every notification is now
-- written by the Edge Function using the service role (which bypasses
-- RLS entirely), not by the admin app inserting directly, so no
-- authenticated-role insert path is needed at all.
drop policy if exists notifications_insert_admin on public.notifications;

-- payment_reminder_threshold / payment_reminder_interval_days live in the
-- existing admin_settings key/value table (20260830000001) — same
-- pattern as the 'tax' key SettingsRepository already reads/writes.
-- Seeded here with sensible defaults so the Edge Function has something
-- to read even before an admin ever visits a settings screen for it;
-- values are still fully configurable by updating this row, never a
-- hardcoded number in the notification logic itself.
insert into public.admin_settings (key, value)
values
  ('payment_reminder_threshold', '{"amount": 10000}'::jsonb),
  ('payment_reminder_interval_days', '{"days": 1}'::jsonb)
on conflict (key) do nothing;
