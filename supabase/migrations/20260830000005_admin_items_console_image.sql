-- admin_items_console never exposed `items.image_url`, so the admin Items
-- screen could only ever render the generic emoji fallback instead of the
-- real catalog photo already stored in the `item-images` bucket (same
-- image the restaurant-facing catalog shows via CatalogItem.imageUrl —
-- see 20260813000001_item_images_bucket.sql). Adding the raw storage path
-- here; the Flutter client resolves it to a public URL the same way
-- ItemsRepository (features/items/data) already does for the customer app.
--
-- image_url is appended as the LAST column, not inserted next to `emoji`
-- where it reads most naturally: `create or replace view` only allows
-- adding new trailing columns — it errors (42P16, "cannot change name of
-- view column") if an existing column's position/name shifts at all, which
-- inserting a column in the middle does.
create or replace view public.admin_items_console
  with (security_invoker = true) as
select
  i.id,
  i.name,
  c.id as category_id,
  coalesce(c.name, i.category) as category_name,
  coalesce(c.emoji, '🥬') as emoji,
  i.unit,
  coalesce(p.price, 0) as price,
  coalesce(p.mrp, p.price, 0) as mrp,
  case when i.is_active then 'active' else 'inactive' end as status,
  p.stock,
  i.image_url
from public.items i
left join public.item_admin_pricing p on p.item_id = i.id
left join public.categories c on lower(trim(c.name)) = lower(trim(i.category));
