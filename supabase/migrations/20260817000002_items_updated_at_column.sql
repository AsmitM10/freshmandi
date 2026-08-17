-- The live `items` table is missing `updated_at` even though the
-- items-catalog migration defines it and attaches `set_items_updated_at`
-- (calling the shared `set_updated_at()` trigger function) expecting it —
-- confirmed via a direct REST query returning "column items.updated_at
-- does not exist". Any edit to a row in the dashboard fails with
-- `record "new" has no field "updated_at"` until this is reconciled.
alter table public.items
  add column if not exists updated_at timestamptz not null default now();
