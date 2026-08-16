-- FreshMandi Phase 3: Item Catalog
-- Restaurant-facing catalog. Deliberately has NO price column anywhere —
-- pricing is an admin/wholesaler-only concern with no UI in this app yet
-- (see project audit). When an admin app exists, prices belong in a
-- separate table that this role is never granted SELECT on, not a column
-- bolted onto this table.

create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  unit text not null,
  image_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint items_name_not_blank check (length(trim(name)) > 0),
  constraint items_category_valid check (
    category in ('indian_vegetables', 'fruits', 'exotic_vegetables')
  ),
  constraint items_unit_valid check (
    unit in ('Kg', 'Gram', 'Bundle', 'Piece', 'Box', 'Dozen')
  )
);

create index if not exists items_category_sort_idx
  on public.items (category, sort_order);

drop trigger if exists set_items_updated_at on public.items;
create trigger set_items_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();

alter table public.items enable row level security;

-- Catalog is readable by any signed-in restaurant user. Inactive items are
-- still returned (not filtered out here) — the client renders them as
-- "Unavailable" rather than hiding them, per the ItemCard states spec.
-- No insert/update/delete policy for `authenticated` — catalog management
-- is an admin-only concern with no client-side path in this app.
drop policy if exists items_select_authenticated on public.items;
create policy items_select_authenticated on public.items
  for select to authenticated
  using (true);

-- Seed data: a modest example set per category (not the full 36-item
-- catalog from the design source — that's a real data-entry task for
-- whoever manages the catalog, not something to fabricate here). All
-- image_url left null intentionally; ItemCard must render a graceful
-- fallback until real images are uploaded to Supabase Storage.
--
-- Guarded by "table is currently empty" (there's no natural unique key to
-- key an ON CONFLICT off) so this migration stays safe to re-run without
-- inserting duplicate rows every time.
insert into public.items (name, category, unit, sort_order)
select * from (
  values
    ('Onion', 'indian_vegetables', 'Kg', 1),
    ('Tomato', 'indian_vegetables', 'Kg', 2),
    ('Potato', 'indian_vegetables', 'Kg', 3),
    ('Coriander', 'indian_vegetables', 'Bundle', 4),
    ('Green Chilli', 'indian_vegetables', 'Kg', 5),
    ('Brinjal', 'indian_vegetables', 'Kg', 6),
    ('Banana', 'fruits', 'Dozen', 1),
    ('Apple', 'fruits', 'Kg', 2),
    ('Papaya', 'fruits', 'Piece', 3),
    ('Watermelon', 'fruits', 'Piece', 4),
    ('Mango', 'fruits', 'Kg', 5),
    ('Broccoli', 'exotic_vegetables', 'Kg', 1),
    ('Zucchini', 'exotic_vegetables', 'Kg', 2),
    ('Red Bell Pepper', 'exotic_vegetables', 'Kg', 3),
    ('Iceberg Lettuce', 'exotic_vegetables', 'Piece', 4),
    ('Asparagus', 'exotic_vegetables', 'Bundle', 5)
) as seed(name, category, unit, sort_order)
where not exists (select 1 from public.items);
