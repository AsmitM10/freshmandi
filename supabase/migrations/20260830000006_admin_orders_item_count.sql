-- The admin Dashboard's "Recent orders" and the Orders list both showed
-- "0 items" for every order, no matter how many line items it actually
-- had. Root cause: OrdersRepository.fetchAll/fetchToday/fetchByCustomer
-- (everything except fetchById) build Order.fromJson with no `items`
-- argument, so `items` defaults to an empty list — `order.items.length` in
-- those two list screens was never going to be anything but 0. Rather than
-- have every list row issue a second query against order_items (10+ extra
-- roundtrips per screen), expose a precomputed item_count on the same
-- views the lists already read from.
--
-- `create or replace view` can only append columns at the end (see prior
-- migrations on both of these views), so item_count goes last in both.
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
  (i.id is not null) as has_invoice,
  r.phone_number as restaurant_phone,
  (select count(*) from public.order_items oi where oi.order_id = o.id) as item_count
from public.orders o
join public.restaurants r on r.id = o.restaurant_id
left join public.invoices i on i.order_id = o.id
order by o.created_at desc;

create or replace view public.admin_orders_console
  with (security_invoker = true) as
select
  order_id as id,
  restaurant_id as customer_id,
  restaurant_name as customer_name,
  coalesce(invoice_total, 0) as total,
  order_status as status,
  coalesce(payment_status, 'pending') as payment_status,
  created_at as placed_at,
  order_number,
  invoice_number,
  restaurant_phone as customer_phone,
  item_count
from public.admin_order_overview;
