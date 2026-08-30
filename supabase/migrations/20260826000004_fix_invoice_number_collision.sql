-- Bug fix: `lpad(text, length, fill)` in Postgres TRUNCATES a string that's
-- already longer than `length`, it doesn't just skip padding it — so
-- lpad(nextval('invoice_number_seq')::text, 5, '0') was silently cutting
-- every invoice number's counter portion down to just its first 5 digits.
-- Since the sequence starts at 20260001, that means every invoice number
-- generated so far collapsed to the same "20260" suffix — invoice_number
-- was never actually unique despite being documented (and relied on by the
-- downloadable invoice feature) as a stable per-order identifier.
--
-- Fix: restart the sequence at 1 (so lpad naturally zero-pads instead of
-- truncating), regenerate every existing invoice_number so they're
-- actually distinct, and add a real uniqueness constraint so this class of
-- bug can't silently reoccur.
alter sequence public.invoice_number_seq restart with 1;

with ranked as (
  select id, generated_at, row_number() over (order by generated_at) as rn
  from public.invoices
)
update public.invoices i
set invoice_number = 'INV-' || to_char(r.generated_at, 'YYYYMMDD') || '-' || lpad(r.rn::text, 5, '0')
from ranked r
where r.id = i.id;

select setval('public.invoice_number_seq', (select count(*) from public.invoices));

alter table public.invoices
  add constraint invoices_invoice_number_unique unique (invoice_number);
