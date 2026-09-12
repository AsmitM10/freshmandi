-- In-app notifications for the restaurant/customer side — separate from
-- (and complementary to) the FCM push in send-order-accepted-push: the
-- push is a fire-and-forget OS alert with just a title/body, while this
-- table is the persisted record a restaurant can revisit inside the app
-- itself (a "Notifications" page), and is what actually carries the
-- generated invoice image. Written directly by the admin app right after
-- accepting an order (is_admin()-gated insert below) — no Edge Function
-- involved for this part, per the explicit "whole process in app" ask.
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  type text not null default 'order_accepted',
  title text not null,
  message text not null,
  order_id uuid references public.orders(id) on delete set null,
  image_url text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_restaurant_id_idx on public.notifications (restaurant_id, created_at desc);

alter table public.notifications enable row level security;

-- A restaurant reads and marks-read only its own notifications — same
-- auth.uid() -> restaurants.user_id -> restaurants.id ownership chain
-- used throughout this schema.
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
  for select to authenticated
  using (
    restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid())
  );

drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications
  for update to authenticated
  using (
    restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid())
  )
  with check (
    restaurant_id in (select r.id from public.restaurants r where r.user_id = auth.uid())
  );

-- Only the admin app writes new notifications (right after accepting an
-- order) — no restaurant-facing insert path exists or should exist.
drop policy if exists notifications_insert_admin on public.notifications;
create policy notifications_insert_admin on public.notifications
  for insert to authenticated
  with check (public.is_admin());

-- Public-read bucket for generated invoice images, same pattern as
-- item-images (20260813000001_item_images_bucket.sql) — not sensitive
-- beyond what the restaurant already sees in-app, and a public bucket
-- lets the client resolve a stored path to a displayable URL with a
-- single getPublicUrl() call, no signed-URL plumbing needed.
insert into storage.buckets (id, name, public)
values ('invoices', 'invoices', true)
on conflict (id) do update set public = excluded.public;

-- Unlike item-images, this bucket IS written to at runtime (the admin app
-- generates and uploads the invoice PNG itself right after accepting an
-- order), so it needs its own write policy on storage.objects — public
-- bucket read alone only covers downloads.
drop policy if exists invoices_admin_write on storage.objects;
create policy invoices_admin_write on storage.objects
  for all to authenticated
  using (bucket_id = 'invoices' and public.is_admin())
  with check (bucket_id = 'invoices' and public.is_admin());
