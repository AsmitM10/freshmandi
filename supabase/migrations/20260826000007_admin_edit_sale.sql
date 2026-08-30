-- Tapping a transaction card on the admin dashboard opens the same "Sale"
-- screen used for Add Sale, pre-filled with that transaction's data (the
-- Figma "Sale" screen the admin gave already showed a populated example
-- with a Delete button — it was always meant to double as add/edit).
-- Re-generating an invoice for an order that already has one needs to
-- UPDATE it, not insert a duplicate (invoices.order_id is unique) — the
-- existing admin insert policy alone isn't enough for that upsert.
drop policy if exists invoices_update_admin on public.invoices;
create policy invoices_update_admin on public.invoices
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());
