-- Extended vaccination record fields
alter table public.vaccinations
  add column disease_covered text[] not null default '{}',
  add column vet_name text,
  add column clinic_name text,
  add column clinic_location text,
  add column batch_number text,
  add column notes text;
