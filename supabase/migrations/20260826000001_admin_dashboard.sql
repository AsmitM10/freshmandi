-- Admin dashboard (Home screen): read-only, cross-restaurant visibility for
-- the admin session only. Adds ADDITIONAL select policies (RLS policies are
-- OR'd together) on top of each table's existing "own row(s) only" policy —
-- restaurants keep seeing only their own data; an is_admin() session
-- additionally sees everyone's, via the same helper used for admin login
-- routing (migration 20260825000001_admin_login.sql).
drop policy if exists restaurants_select_admin on public.restaurants;
create policy restaurants_select_admin on public.restaurants
  for select to authenticated
  using (public.is_admin());

drop policy if exists orders_select_admin on public.orders;
create policy orders_select_admin on public.orders
  for select to authenticated
  using (public.is_admin());

drop policy if exists invoices_select_admin on public.invoices;
create policy invoices_select_admin on public.invoices
  for select to authenticated
  using (public.is_admin());

-- One row per order with its restaurant's name joined in, for the admin
-- Transactions list. `security_invoker` means it only ever returns what the
-- querying session's own RLS (above) already allows — a restaurant querying
-- this directly would only ever see its own orders, same as order_history.
create or replace view public.admin_order_overview
  with (security_invoker = true) as
select
  o.id as order_id,
  o.restaurant_id,
  r.restaurant_name,
  o.order_number,
  o.status as order_status,
  o.created_at,
  i.total_amount as invoice_total,
  i.payment_status,
  i.invoice_number,
  (i.id is not null) as has_invoice
from public.orders o
join public.restaurants r on r.id = o.restaurant_id
left join public.invoices i on i.order_id = o.id
order by o.created_at desc;

-- Single-row aggregate for the Overview card. "Sale" is every invoice ever
-- generated; "you will get" (receivable) is the still-unpaid subset. Both
-- are real sums over `invoices.total_amount` — there is no separate
-- "amount paid so far" column, so a paid invoice contributes 0 to
-- receivable and its full total to sale, never a partial figure.
create or replace view public.admin_revenue_summary
  with (security_invoker = true) as
select
  coalesce(sum(total_amount) filter (where payment_status = 'pending'), 0) as total_receivable,
  coalesce(sum(total_amount), 0) as total_sale
from public.invoices;
