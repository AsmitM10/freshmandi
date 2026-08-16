-- Records that the restaurant accepted the Terms & Conditions, per the
-- updated flow: Welcome -> Terms & Conditions -> Registration form.
-- terms_accepted_at is captured client-side at the moment the user taps
-- "Proceed to Register" on the T&C screen (before OTP is even sent), then
-- written into this row when the restaurant is created after OTP verification.
-- terms_version lets a future change to the T&C copy be distinguished from
-- what an existing restaurant actually agreed to — the version string
-- mirrors the "Last Updated" date shown on the T&C screen itself.
alter table public.restaurants
  add column if not exists terms_accepted_at timestamptz,
  add column if not exists terms_version text;

-- Backfill any rows created before this column existed (e.g. rows created
-- while testing the flow pre-T&C) so the NOT NULL constraints below don't
-- fail against live data. Tagged distinctly from a real acceptance.
update public.restaurants
set terms_accepted_at = coalesce(terms_accepted_at, created_at),
    terms_version = coalesce(terms_version, 'legacy-backfilled')
where terms_accepted_at is null or terms_version is null;

alter table public.restaurants
  alter column terms_accepted_at set not null,
  alter column terms_version set not null;
