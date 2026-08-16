-- FreshMandi: Orders / Order Items / Invoices.
--
-- This did not exist before the History screen work — flagged during the
-- Items/Shop implementation as needed but deliberately not invented then.
-- Building it now because History cannot be real without it. Kept
-- deliberately minimal: just enough for order submission (Repeat Order ->
-- cart -> a future "Place Order" action) and for History/Invoice display.
-- No price ever appears on `orders`/`order_items` — only on `invoices`,
-- which the restaurant can never write to (wholesaler/admin-only, and
-- there's no admin app yet, so this table is empty/manually seeded via
-- the SQL editor until one exists — same pattern as account_status
-- approval).

create sequence if not exists public.order_number_seq start 10001;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  order_number text not null unique,
  status text not null default 'submitted'
    check (status in ('submitted', 'confirmed', 'delivered', 'cancelled')),
  delivery_date date,
  created_at timestamptz not null default now()
);

-- Assigned server-side so the client never picks/collides on order numbers.
create or replace function public.assign_order_number()
returns trigger as $$
begin
  if new.order_number is null then
    new.order_number := nextval('public.order_number_seq')::text;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists set_order_number on public.orders;
create trigger set_order_number
  before insert on public.orders
  for each row execute function public.assign_order_number();

-- Quantity/unit are snapshotted at order time (not looked up live from
-- `items`) so a later catalog edit/rename never rewrites order history.
-- No price column — see the no-price rule enforced structurally
-- throughout this app.
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  item_id uuid references public.items(id) on delete set null,
  item_name text not null,
  quantity integer not null check (quantity > 0),
  unit text not null,
  created_at timestamptz not null default now()
);

create index if not exists order_items_order_id_idx on public.order_items (order_id);

-- One invoice per order. Its *absence* is what "Pending Invoice" means —
-- there is no separate status column to keep in sync with a null total.
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  total_amount numeric(12, 2) not null check (total_amount >= 0),
  payment_status text not null default 'pending'
    check (payment_status in ('pending', 'paid')),
  generated_at timestamptz not null default now()
);

create index if not exists orders_restaurant_id_created_at_idx
  on public.orders (restaurant_id, created_at desc);

alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.invoices enable row level security;

-- Ownership is always resolved through the caller's own auth.uid() ->
-- restaurants.user_id -> restaurants.id chain, never through a
-- client-supplied restaurant_id — a restaurant cannot read or write
-- another restaurant's orders no matter what id it sends.
drop policy if exists orders_select_own on public.orders;
create policy orders_select_own on public.orders
  for select to authenticated
  using (
    restaurant_id in (select id from public.restaurants where user_id = auth.uid())
  );

drop policy if exists orders_insert_own on public.orders;
create policy orders_insert_own on public.orders
  for insert to authenticated
  with check (
    restaurant_id in (select id from public.restaurants where user_id = auth.uid())
  );

-- No update/delete policy for `authenticated` — orders are immutable once
-- placed, per the explicit business rule.

drop policy if exists order_items_select_own on public.order_items;
create policy order_items_select_own on public.order_items
  for select to authenticated
  using (
    order_id in (
      select o.id from public.orders o
      join public.restaurants r on r.id = o.restaurant_id
      where r.user_id = auth.uid()
    )
  );

drop policy if exists order_items_insert_own on public.order_items;
create policy order_items_insert_own on public.order_items
  for insert to authenticated
  with check (
    order_id in (
      select o.id from public.orders o
      join public.restaurants r on r.id = o.restaurant_id
      where r.user_id = auth.uid()
    )
  );

drop policy if exists invoices_select_own on public.invoices;
create policy invoices_select_own on public.invoices
  for select to authenticated
  using (
    order_id in (
      select o.id from public.orders o
      join public.restaurants r on r.id = o.restaurant_id
      where r.user_id = auth.uid()
    )
  );

-- No insert/update/delete policy on `invoices` for `authenticated` at
-- all — generating an invoice is exclusively a wholesaler/admin action,
-- and there is no admin app yet to perform it.

-- Single-query view for the History screen: one row per order with its
-- item count and (if generated) invoice total/payment status already
-- joined in. `security_invoker` makes it respect the querying user's own
-- RLS on the underlying tables above, rather than the view owner's.
create or replace view public.order_history
  with (security_invoker = true) as
select
  o.id as order_id,
  o.restaurant_id,
  o.order_number,
  o.status as order_status,
  o.created_at,
  o.delivery_date,
  (select count(*) from public.order_items oi where oi.order_id = o.id) as item_count,
  i.total_amount as invoice_total,
  i.payment_status,
  (i.id is not null) as has_invoice
from public.orders o
left join public.invoices i on i.order_id = o.id;
