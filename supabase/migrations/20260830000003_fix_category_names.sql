-- The `categories` table (20260830000001) was seeded with the original
-- items_catalog.sql migration's snake_case category values
-- ('indian_vegetables', 'fruits', 'exotic_vegetables'), but the real,
-- live `items.category` data actually uses Title Case with spaces
-- ('Indian Vegetables', 'Fruits', 'Exotic Vegetables') — confirmed by
-- querying the live table (268 rows, all in one of those three exact
-- strings). admin_items_console's category match
-- (lower(trim(c.name)) = lower(trim(i.category))) is case/whitespace
-- insensitive, so the space-vs-underscore mismatch was the only real
-- problem: every item's category_id came back null in the admin Items
-- screen. Renaming in place (not re-inserting) so the categories' ids —
-- already possibly referenced from an admin session's in-memory state —
-- stay stable.
update public.categories set name = 'Indian Vegetables' where name = 'indian_vegetables';
update public.categories set name = 'Fruits' where name = 'fruits';
update public.categories set name = 'Exotic Vegetables' where name = 'exotic_vegetables';
