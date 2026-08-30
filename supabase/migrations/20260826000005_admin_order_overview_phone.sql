-- The admin "Share Transaction" receipt needs the restaurant's phone
-- number too. `create or replace view` can only append columns at the end
-- of the existing list (same constraint hit before on order_history), so
-- restaurant_phone goes after has_invoice, not next to restaurant_name.
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
  r.phone_number as restaurant_phone
from public.orders o
join public.restaurants r on r.id = o.restaurant_id
left join public.invoices i on i.order_id = o.id
order by o.created_at desc;
