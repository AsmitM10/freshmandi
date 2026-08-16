-- The live `items` table already contains rows that violate the original
-- items_category_valid / items_unit_valid CHECK constraints from
-- 20260808000004 — category is stored as human-readable text ("Indian
-- Vegetables") rather than the snake_case enum that migration specified,
-- and unit values ("Bdl", "Pac/Kg", "Pcs") aren't in that migration's
-- fixed list either. Since real rows already violate them, those
-- constraints are not actually being enforced as written (schema drift),
-- so this makes the schema honest about what's real rather than leaving a
-- CHECK in the migration history that lies about what's enforced.
--
-- The Flutter client now matches category by keyword (see
-- ItemCategoryParsing.toItemCategory) rather than exact string, so it
-- tolerates whatever casing/spelling the catalog data actually uses —
-- these constraints are relaxed to just "not blank" rather than re-tightened
-- to a new fixed list, since the data source is manual/bulk entry that
-- isn't realistically going to stay pinned to one exact vocabulary.
alter table public.items drop constraint if exists items_category_valid;
alter table public.items add constraint items_category_not_blank
  check (length(trim(category)) > 0);

alter table public.items drop constraint if exists items_unit_valid;
alter table public.items add constraint items_unit_not_blank
  check (length(trim(unit)) > 0);
