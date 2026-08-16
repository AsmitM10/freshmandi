-- Public bucket for catalog item photos. Public (not signed URLs) because
-- this content isn't sensitive — same produce photos every authenticated
-- restaurant already sees in the catalog — and a public bucket lets the
-- client resolve `items.image_url` (a path like 'fruits/apple.png') to a
-- displayable URL with a single, tokenless getPublicUrl() call.
--
-- No insert/update/delete storage policy is created here: uploading catalog
-- images is an admin-only, out-of-app task (via the Supabase dashboard or
-- a future admin tool), matching the same "no client-side write path" rule
-- already applied to the `items` table itself.
insert into storage.buckets (id, name, public)
values ('item-images', 'item-images', true)
on conflict (id) do update set public = excluded.public;
