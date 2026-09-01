-- admin_orders_console (20260830000001) exposed only the order's raw UUID
-- as `id` — every admin screen that displayed "Order #<id>" was showing a
-- UUID instead of the human-friendly order/invoice number. Adds
-- order_number, invoice_number and customer_phone (all already available
-- on admin_order_overview) at the end of the view's column list, since
-- `create or replace view` can only append columns, never insert one in
-- the middle (same constraint noted in earlier migrations on this view's
-- source, admin_order_overview).
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
  restaurant_phone as customer_phone
from public.admin_order_overview;
