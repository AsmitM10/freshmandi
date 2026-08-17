-- Adds Razorpay order tracking to invoices for the "Pay Now" flow. The
-- client never writes payment_status directly (invoices still has zero
-- authenticated write policy, unchanged) — only the two Edge Functions
-- (create-razorpay-order, verify-razorpay-payment), using the service-role
-- key after independently confirming ownership via the caller's own RLS-
-- scoped session, are allowed to set these columns.
alter table public.invoices
  add column if not exists razorpay_order_id text,
  add column if not exists razorpay_payment_id text;

create unique index if not exists invoices_razorpay_order_id_idx
  on public.invoices (razorpay_order_id)
  where razorpay_order_id is not null;
