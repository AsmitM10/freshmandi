-- Adds what the downloadable invoice document needs beyond what
-- order_history already provides:
--
--   1. invoices.invoice_number — stable per-order invoice id, assigned
--      once (same pattern as orders.order_number / order_number_seq) so
--      re-downloading the same accepted order's invoice never changes its
--      number.
--   2. restaurants.billing_address / delivery_address — nullable; the
--      Business Details screen and this invoice previously showed
--      "Not set" for these because the columns genuinely didn't exist.
--   3. business_settings — the wholesaler's own business info (name,
--      address, phone, email, UPI id). This app has exactly one
--      wholesaler (no multi-vendor concept), so this is a single
--      admin-seeded row, not a table with a restaurant-facing write path
--      — same "invoices has zero authenticated write policy" pattern
--      already used for pricing.
--
-- The seeded row below uses placeholder business details — replace them
-- via the SQL editor with the real wholesaler's info when known, same as
-- the rest of this app's "seed manually until an admin app exists"
-- convention (see the orders_history migration's own comment on
-- `invoices`).

create sequence if not exists public.invoice_number_seq start 20260001;

alter table public.invoices
  add column if not exists invoice_number text;

create or replace function public.assign_invoice_number()
returns trigger as $$
begin
  if new.invoice_number is null then
    new.invoice_number := 'INV-' || to_char(now(), 'YYYYMMDD') || '-' ||
      lpad(nextval('public.invoice_number_seq')::text, 5, '0');
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists set_invoice_number on public.invoices;
create trigger set_invoice_number
  before insert on public.invoices
  for each row execute function public.assign_invoice_number();

-- Backfill any invoices that predate this column (none expected outside
-- manual testing, but keeps the column non-null in practice going forward).
update public.invoices
set invoice_number = 'INV-' || to_char(generated_at, 'YYYYMMDD') || '-' ||
  lpad(nextval('public.invoice_number_seq')::text, 5, '0')
where invoice_number is null;

alter table public.restaurants
  add column if not exists billing_address text,
  add column if not exists delivery_address text;

create table if not exists public.business_settings (
  id uuid primary key default gen_random_uuid(),
  business_name text not null,
  address text not null,
  phone_number text not null,
  email text,
  upi_id text,
  updated_at timestamptz not null default now()
);

drop trigger if exists set_business_settings_updated_at on public.business_settings;
create trigger set_business_settings_updated_at
  before update on public.business_settings
  for each row execute function public.set_updated_at();

alter table public.business_settings enable row level security;

-- Every authenticated restaurant can read the wholesaler's own business
-- info (it's what appears on their invoice) — no write policy at all, so
-- only a service-role/SQL-editor action can ever change it.
drop policy if exists business_settings_select_all on public.business_settings;
create policy business_settings_select_all on public.business_settings
  for select to authenticated
  using (true);

insert into public.business_settings (business_name, address, phone_number, email, upi_id)
select
  'FreshMandi Wholesale Supply',
  'Shop No. 12, Dadar Vegetable Market, Dadar (East), Mumbai - 400014, Maharashtra, India',
  '+91 98765 43210',
  'support@freshmandi.example',
  'freshmandi@upi'
where not exists (select 1 from public.business_settings);

-- order_history now also carries the invoice number. `create or replace
-- view` can only append new columns at the end of the existing column
-- list, never insert one in the middle — invoice_number must come after
-- has_invoice (the view's original last column), not before it.
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
  (i.id is not null) as has_invoice,
  i.invoice_number
from public.orders o
left join public.invoices i on i.order_id = o.id;
