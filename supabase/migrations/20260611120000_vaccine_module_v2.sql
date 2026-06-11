-- Vaccine module v2: protection duration + renewal reminders
alter table public.vaccinations
  add column protection_months integer not null default 12
    check (protection_months between 1 and 120),
  add column reminder_enabled boolean not null default false;
