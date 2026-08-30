-- Test data for the one existing test restaurant ("Nom Nom Hotel",
-- +911234567890), so the admin dashboard has real transactions to show
-- during development instead of an empty state. Order items reference
-- real rows from `items` (no fabricated catalog entries); quantities/
-- invoice totals are made-up test numbers, same as any other seed/fixture
-- data in this app (e.g. the business_settings seed row).
--
-- Safe to re-run: does nothing if this restaurant already has orders.
do $$
declare
  v_restaurant_id uuid;
  v_order_a uuid;
  v_order_b uuid;
  v_order_c uuid;
  v_order_d uuid;
begin
  select id into v_restaurant_id
  from public.restaurants
  where phone_number = '+911234567890'
  limit 1;

  if v_restaurant_id is null then
    raise notice 'No restaurant found for +911234567890 — skipping seed.';
    return;
  end if;

  if exists (select 1 from public.orders where restaurant_id = v_restaurant_id) then
    raise notice 'Restaurant % already has orders — skipping seed.', v_restaurant_id;
    return;
  end if;

  -- Order A: delivered, invoice paid.
  insert into public.orders (restaurant_id, status, delivery_date, created_at)
  values (v_restaurant_id, 'delivered', current_date - 4, now() - interval '5 days')
  returning id into v_order_a;

  insert into public.order_items (order_id, item_id, item_name, quantity, unit) values
    (v_order_a, '12a3662c-708c-4bbb-b72e-5878a1e6190a', 'Coriender leave', 5, 'Bdl'),
    (v_order_a, '808f755f-f93b-44aa-8fb5-b803b6f2d0b5', 'Red apple', 10, 'Kg');

  insert into public.invoices (order_id, total_amount, payment_status, generated_at)
  values (v_order_a, 950.00, 'paid', now() - interval '4 days');

  -- Order B: delivered, invoice still pending.
  insert into public.orders (restaurant_id, status, delivery_date, created_at)
  values (v_restaurant_id, 'delivered', current_date - 2, now() - interval '3 days')
  returning id into v_order_b;

  insert into public.order_items (order_id, item_id, item_name, quantity, unit) values
    (v_order_b, '6ac79b5f-5d6f-43f3-8c8d-26fe0d4d14f4', 'Mint', 3, 'Bdl'),
    (v_order_b, '78bd70a6-23bc-4f73-981e-59ff2de8182c', 'Green apple', 8, 'Kg'),
    (v_order_b, '5d0543c2-6eb1-48b4-bc8a-c8bf7c4c973d', 'Methi', 4, 'Bdl');

  insert into public.invoices (order_id, total_amount, payment_status, generated_at)
  values (v_order_b, 1450.00, 'pending', now() - interval '2 days');

  -- Order C: confirmed, no invoice yet at all.
  insert into public.orders (restaurant_id, status, delivery_date, created_at)
  values (v_restaurant_id, 'confirmed', current_date + 1, now() - interval '1 day')
  returning id into v_order_c;

  insert into public.order_items (order_id, item_id, item_name, quantity, unit) values
    (v_order_c, '721cfa21-4b87-42cf-8283-ee3203efc6c9', 'Painapple', 2, 'Pac/Kg');

  -- Order D: delivered today, invoice paid.
  insert into public.orders (restaurant_id, status, delivery_date, created_at)
  values (v_restaurant_id, 'delivered', current_date, now())
  returning id into v_order_d;

  insert into public.order_items (order_id, item_id, item_name, quantity, unit) values
    (v_order_d, '727420b6-e297-428f-bf22-efd2f0dc02c6', 'Coriender leave (big)', 6, 'Bdl'),
    (v_order_d, '0ed5d183-39fe-4bc4-8454-39c540b776e8', 'Peru', 5, 'Kg');

  insert into public.invoices (order_id, total_amount, payment_status, generated_at)
  values (v_order_d, 620.00, 'paid', now());
end $$;
