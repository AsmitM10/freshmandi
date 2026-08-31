-- Business Console admin app integration.
--
-- The "Business Console" (lib/screens/*) is a standalone admin UI that was
-- dropped into this project pre-built against its own placeholder schema
-- (categories/products/customers/orders/order_items/money_transactions —
-- see the removed supabase/schema.sql). Per product decision, its UI stays
-- exactly as built, but its data layer now points at this app's real
-- tables instead. This migration only ADDS to the existing schema — no
-- existing table, column, or policy from earlier migrations is dropped or
-- redefined destructively.
--
-- Mapping used throughout the Flutter repositories (lib/data/repositories):
--   "customers"   -> restaurants (+ outstanding_balance added below)
--   "products"    -> items (+ item_admin_pricing added below, kept in a
--                    separate table so ordinary restaurant users — whose
--                    `items` SELECT policy is `using (true)` — never gain
--                    row access to price data; see the original comment in
--                    20260808000004_items_catalog.sql)
--   "categories"  -> new table below (admin-managed reference list used by
--                    the Items screen's category picker; items.category
--                    stays the free-text column the restaurant-facing app
--                    already reads/writes — unaffected)
--   "money_transactions" -> new table below (Money In ledger; entries are
--                    not always tied to an order — "Owner Capital
--                    Introduced" / "Miscellaneous Income" etc. have no
--                    order/invoice to derive from)
--   "app_settings" (tax toggle) -> admin_settings below

-- ============================================================================
-- restaurants.outstanding_balance
-- ============================================================================
alter table public.restaurants
  add column if not exists outstanding_balance numeric(12, 2) not null default 0;

-- ============================================================================
-- item_admin_pricing — admin-only price/MRP/stock per catalog item.
-- ============================================================================
create table if not exists public.item_admin_pricing (
  item_id uuid primary key references public.items(id) on delete cascade,
  price numeric(12, 2) not null default 0,
  mrp numeric(12, 2),
  stock integer,
  updated_at timestamptz not null default now()
);

drop trigger if exists set_item_admin_pricing_updated_at on public.item_admin_pricing;
create trigger set_item_admin_pricing_updated_at
  before update on public.item_admin_pricing
  for each row execute function public.set_updated_at();

alter table public.item_admin_pricing enable row level security;

drop policy if exists item_admin_pricing_admin_all on public.item_admin_pricing;
create policy item_admin_pricing_admin_all on public.item_admin_pricing
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================================
-- categories — admin-managed reference list (name + emoji) for the Items
-- screen's category picker. Deliberately NOT foreign-keyed from
-- `items.category`, which stays free text for the existing restaurant app.
-- ============================================================================
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  emoji text not null default '🧺',
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_at timestamptz not null default now()
);

alter table public.categories enable row level security;

drop policy if exists categories_admin_all on public.categories;
create policy categories_admin_all on public.categories
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

insert into public.categories (name, emoji)
select * from (
  values
    ('indian_vegetables', '🥬'),
    ('fruits', '🍎'),
    ('exotic_vegetables', '🥦')
) as seed(name, emoji)
where not exists (select 1 from public.categories);

-- ============================================================================
-- money_transactions — Money In ledger for the admin Transactions screen.
-- Not every row is tied to an order (e.g. "Owner Capital Introduced"), so
-- this is a real ledger table, not a view over invoices.
-- ============================================================================
create table if not exists public.money_transactions (
  id uuid primary key default gen_random_uuid(),
  date timestamptz not null default now(),
  category text not null,
  party_id uuid references public.restaurants(id) on delete set null,
  party_name text,
  amount numeric(12, 2) not null check (amount > 0),
  method text not null,
  ref_type text not null default 'Manual',
  ref_id uuid,
  created_at timestamptz not null default now()
);

create index if not exists money_transactions_date_idx on public.money_transactions (date desc);

alter table public.money_transactions enable row level security;

drop policy if exists money_transactions_admin_all on public.money_transactions;
create policy money_transactions_admin_all on public.money_transactions
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================================
-- admin_settings — admin app's own key/value settings (currently just the
-- tax toggle). Separate from business_settings (the wholesaler's identity
-- shown on customer invoices) — this is admin-console-local config.
-- ============================================================================
create table if not exists public.admin_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.admin_settings enable row level security;

drop policy if exists admin_settings_admin_all on public.admin_settings;
create policy admin_settings_admin_all on public.admin_settings
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================================
-- Admin write RPCs — account_status is structurally pinned to its old
-- value on every UPDATE by protect_restaurants_account_status()
-- (20260819000001), which runs regardless of who issues the update, so a
-- plain admin UPDATE can never change it. SECURITY DEFINER functions give
-- the admin a privileged path that bypasses both that trigger and RLS,
-- after independently checking is_admin() — the same pattern already used
-- by claim_admin()/is_admin() (20260825000001).
-- ============================================================================
create or replace function public.admin_set_customer_blocked(
  p_restaurant_id uuid,
  p_blocked boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  update public.restaurants
  set account_status = case when p_blocked then 'suspended' else 'approved' end
  where id = p_restaurant_id;
end;
$$;

grant execute on function public.admin_set_customer_blocked(uuid, boolean) to authenticated;

create or replace function public.admin_adjust_outstanding_balance(
  p_restaurant_id uuid,
  p_delta numeric
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  update public.restaurants
  set outstanding_balance = greatest(0, outstanding_balance + p_delta)
  where id = p_restaurant_id;
end;
$$;

grant execute on function public.admin_adjust_outstanding_balance(uuid, numeric) to authenticated;

-- Confirms a restaurant-placed order and generates its invoice, computing
-- the total from the admin's own catalog pricing (item_admin_pricing) —
-- the only source of item price in this schema (orders/order_items never
-- carry one; see 20260814000001_orders_history.sql). Upsert on order_id so
-- re-confirming (shouldn't normally happen from the UI, but kept safe)
-- updates rather than duplicates. Line items with no matching
-- item_admin_pricing row (or a null price) contribute 0, not an error.
create or replace function public.admin_confirm_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total numeric(12, 2);
begin
  if not public.is_admin() then
    raise exception 'not authorized';
  end if;

  select coalesce(sum(oi.quantity * coalesce(p.price, 0)), 0)
  into v_total
  from public.order_items oi
  left join public.item_admin_pricing p on p.item_id = oi.item_id
  where oi.order_id = p_order_id;

  update public.orders set status = 'confirmed' where id = p_order_id;

  insert into public.invoices (order_id, total_amount, payment_status)
  values (p_order_id, v_total, 'pending')
  on conflict (order_id) do update set total_amount = excluded.total_amount;
end;
$$;

grant execute on function public.admin_confirm_order(uuid) to authenticated;

-- ============================================================================
-- Views shaped to match the Business Console's existing Dart model
-- fromJson() key expectations exactly, so the repositories can select from
-- them with no per-row remapping code and the model classes stay untouched.
-- ============================================================================

-- Matches models/customer.dart Customer.fromJson.
create or replace view public.admin_customers_overview
  with (security_invoker = true) as
select
  r.id,
  r.restaurant_name as business_name,
  r.owner_name as contact_name,
  r.phone_number as phone,
  r.created_at,
  case when r.account_status = 'suspended' then 'blocked' else 'active' end as status,
  r.outstanding_balance
from public.restaurants r;

-- Matches models/order.dart Order.fromJson. Reuses admin_order_overview
-- (20260826000001_admin_dashboard.sql) as its source rather than
-- reimplementing the same join.
create or replace view public.admin_orders_console
  with (security_invoker = true) as
select
  order_id as id,
  restaurant_id as customer_id,
  restaurant_name as customer_name,
  coalesce(invoice_total, 0) as total,
  order_status as status,
  coalesce(payment_status, 'pending') as payment_status,
  created_at as placed_at
from public.admin_order_overview;

-- Matches models/product.dart Product.fromJson. `category_id`/`category_name`
-- resolve to the best-matching `categories` row by name (case/whitespace
-- insensitive, tolerating the schema drift documented in
-- 20260813000002_relax_items_category_unit_constraints.sql); both are null
-- when nothing matches, which the Add/Edit Item sheet already handles by
-- falling back to the first category in the dropdown.
create or replace view public.admin_items_console
  with (security_invoker = true) as
select
  i.id,
  i.name,
  c.id as category_id,
  coalesce(c.name, i.category) as category_name,
  coalesce(c.emoji, '🥬') as emoji,
  i.unit,
  coalesce(p.price, 0) as price,
  coalesce(p.mrp, p.price, 0) as mrp,
  case when i.is_active then 'active' else 'inactive' end as status,
  p.stock
from public.items i
left join public.item_admin_pricing p on p.item_id = i.id
left join public.categories c on lower(trim(c.name)) = lower(trim(i.category));
