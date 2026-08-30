-- Nom Nom Hotel already has 9 real orders from earlier testing (and one
-- real paid invoice) — the 20260826000002 seed migration correctly saw
-- those and skipped itself. Rather than inventing a parallel set of fake
-- orders, this attaches a couple more invoices directly to real,
-- already-placed orders that don't have one yet, so the admin dashboard
-- has both a paid and a pending example to show. Invoice totals are
-- admin-entered test figures — this app has no per-item pricing at all
-- (core business rule), so a manually-set total is exactly how a real
-- invoice would be generated, not fabricated data.
insert into public.invoices (order_id, total_amount, payment_status, generated_at)
select id, 1450.00, 'pending', now() - interval '1 day'
from public.orders
where id = 'c5aa8ada-b01e-4f2d-8bdd-1133ea7b76f6'
  and not exists (select 1 from public.invoices where order_id = orders.id);

insert into public.invoices (order_id, total_amount, payment_status, generated_at)
select id, 2100.00, 'paid', now() - interval '3 hours'
from public.orders
where id = '6bcb5158-4a2d-4917-a123-6a26678f94ac'
  and not exists (select 1 from public.invoices where order_id = orders.id);
