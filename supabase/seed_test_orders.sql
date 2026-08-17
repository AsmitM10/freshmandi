-- One-off manual test data — NOT a migration, run this yourself in the
-- SQL Editor after 20260814000001_orders_history.sql, only if you want
-- to see the History screen populated before the real order-submission
-- flow exists. Uses the existing test restaurant + a couple of real
-- catalog items already in your `items` table.
do $$
declare
  v_restaurant_id uuid;
  v_order_1 uuid;
  v_order_2 uuid;
  v_item record;
begin
  select id into v_restaurant_id from public.restaurants
  where user_id = '33ff6f8f-57cc-4854-a6d5-5b545ee93934';

  -- Paid order (Transaction tab)
  insert into public.orders (restaurant_id, status, delivery_date, created_at)
  values (v_restaurant_id, 'delivered', current_date + 2, now() - interval '2 days')
  returning id into v_order_1;

  for v_item in (select id, name, unit from public.items limit 3) loop
    insert into public.order_items (order_id, item_id, item_name, quantity, unit)
    values (v_order_1, v_item.id, v_item.name, 5, coalesce(v_item.unit, 'Kg'));
  end loop;

  insert into public.invoices (order_id, total_amount, payment_status)
  values (v_order_1, 12500, 'paid');

  -- Pending-invoice order (Pending Invoice tab)
  insert into public.orders (restaurant_id, status, delivery_date, created_at)
  values (v_restaurant_id, 'submitted', current_date + 4, now() - interval '1 hour')
  returning id into v_order_2;

  for v_item in (select id, name, unit from public.items offset 3 limit 2) loop
    insert into public.order_items (order_id, item_id, item_name, quantity, unit)
    values (v_order_2, v_item.id, v_item.name, 3, coalesce(v_item.unit, 'Kg'));
  end loop;
end $$;
