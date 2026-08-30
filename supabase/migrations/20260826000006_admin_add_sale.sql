-- Admin "Add Sale" — the first admin screen that writes data (previous
-- admin work was read-only dashboards). An admin-entered sale is still
-- just a real order+order_items+invoice, same tables the restaurant-placed
-- flow already uses — there's no separate "admin order" concept.
--
-- order_items.rate is new: the per-unit price the admin enters while
-- building a sale, purely so the app can compute a subtotal/total for
-- them. Nullable because restaurant-placed orders never set it. Never
-- exposed to the restaurant side — OrderLineItem (the domain model
-- restaurant screens use) doesn't map this column at all, so it can't leak
-- through History/Invoice even though the column exists in the same table.
alter table public.order_items
  add column if not exists rate numeric(12, 2);

-- Admin can create/edit/delete orders and their items (a "Save" without an
-- invoice yet is a draft; "Delete" removes the order, which cascades to
-- its items and invoice via the existing FK constraints). Restaurants
-- still can't do any of this — these are ADDITIONAL policies alongside
-- their existing insert-own-only / no-update-no-delete policies.
drop policy if exists orders_insert_admin on public.orders;
create policy orders_insert_admin on public.orders
  for insert to authenticated
  with check (public.is_admin());

drop policy if exists orders_update_admin on public.orders;
create policy orders_update_admin on public.orders
  for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists orders_delete_admin on public.orders;
create policy orders_delete_admin on public.orders
  for delete to authenticated
  using (public.is_admin());

drop policy if exists order_items_insert_admin on public.order_items;
create policy order_items_insert_admin on public.order_items
  for insert to authenticated
  with check (public.is_admin());

drop policy if exists order_items_delete_admin on public.order_items;
create policy order_items_delete_admin on public.order_items
  for delete to authenticated
  using (public.is_admin());

-- Generating an invoice ("Generate Invoice") is the same admin-only action
-- already documented as needing an admin app in the orders_history
-- migration — this is that write path finally existing.
drop policy if exists invoices_insert_admin on public.invoices;
create policy invoices_insert_admin on public.invoices
  for insert to authenticated
  with check (public.is_admin());
