-- 20260826000006_admin_add_sale.sql gave the admin session insert/delete
-- policies on `order_items` but never a SELECT policy — only
-- `order_items_select_own` (restaurant-scoped, 20260814000001) exists, so
-- an is_admin() session reading `order_items` directly (OrdersRepository
-- .fetchById, AddSaleRepository.fetchForEdit) always got back an empty
-- list, even though the rows themselves were inserted correctly. This is
-- why a freshly generated Sale Invoice showed no items in the PDF/image
-- share (order.items was empty) despite the line item being saved to the
-- database — confirmed live: the order_items row existed with the right
-- item_name/quantity/unit, it just couldn't be read back under RLS.
drop policy if exists order_items_select_admin on public.order_items;
create policy order_items_select_admin on public.order_items
  for select to authenticated
  using (public.is_admin());
