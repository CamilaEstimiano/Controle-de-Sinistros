-- CONTROLE DE SINISTROS
-- Esquema inicial: revisar políticas e testar em ambiente de desenvolvimento antes de usar dados reais.
create extension if not exists pgcrypto;

create type public.app_role as enum ('gestor_frota', 'oficina', 'consulta');
create type public.claim_status as enum ('ativo', 'encerrado', 'cancelado');
create type public.claim_responsibility as enum ('motorista', 'terceiro', 'transportadora', 'em_analise', 'nao_identificado');
create type public.repair_status as enum ('nao_iniciado', 'aguardando', 'em_reparo', 'concluido', 'entregue');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null,
  role public.app_role not null default 'consulta',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  plate text not null unique,
  make_model text,
  manufacture_year integer,
  vehicle_type text,
  client_name text,
  carrier_name text,
  chassis text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vehicles_plate_uppercase check (plate = upper(plate))
);

create table public.trailers (
  id uuid primary key default gen_random_uuid(),
  plate text not null unique,
  make_model text,
  chassis text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trailers_plate_uppercase check (plate = upper(plate))
);

create table public.drivers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  cpf text,
  cnh text,
  cnh_category text,
  cnh_expiry date,
  first_license_date date,
  phone text,
  marital_status text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index drivers_name_idx on public.drivers using gin (to_tsvector('simple', full_name));

create table public.insurers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.claims (
  id uuid primary key default gen_random_uuid(),
  internal_number bigint generated always as identity unique,
  insurer_notice_number text,
  brf_claim_number text,
  occurred_at timestamptz not null,
  opened_at timestamptz not null default now(),
  location_description text,
  city text,
  state char(2),
  status public.claim_status not null default 'ativo',
  current_stage text not null default 'Ocorrência',
  internal_owner uuid references public.profiles(id) on delete restrict,
  vehicle_id uuid not null references public.vehicles(id) on delete restrict,
  trailer_id uuid references public.trailers(id) on delete restrict,
  driver_id uuid references public.drivers(id) on delete restrict,
  loaded boolean not null default false,
  incident_type text not null,
  incident_description text not null,
  has_third_party boolean not null default false,
  has_victim boolean not null default false,
  victim_details jsonb,
  has_police_report boolean not null default false,
  vehicle_immobilized boolean not null default false,
  needs_tow boolean not null default false,
  responsibility public.claim_responsibility not null default 'em_analise',
  insurer_id uuid references public.insurers(id) on delete restrict,
  insurer_claim_number text,
  next_action text,
  next_action_at timestamptz,
  deadline_at timestamptz,
  last_activity_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  closed_at timestamptz,
  constraint active_claim_action_required check (
    status <> 'ativo' or (
      internal_owner is not null and
      deadline_at is not null and
      nullif(trim(next_action), '') is not null and
      next_action_at is not null
    )
  )
);
create index claims_status_idx on public.claims(status);
create index claims_occurred_at_idx on public.claims(occurred_at desc);
create index claims_vehicle_idx on public.claims(vehicle_id);
create index claims_driver_idx on public.claims(driver_id);
create index claims_deadline_idx on public.claims(deadline_at) where status = 'ativo';
create index claims_last_activity_idx on public.claims(last_activity_at) where status = 'ativo';

create table public.claim_stage_history (
  id uuid primary key default gen_random_uuid(),
  claim_id uuid not null references public.claims(id) on delete restrict,
  from_stage text,
  to_stage text not null,
  changed_by uuid references public.profiles(id) on delete restrict,
  changed_at timestamptz not null default now(),
  notes text
);

create table public.claim_documents (
  id uuid primary key default gen_random_uuid(),
  claim_id uuid not null references public.claims(id) on delete restrict,
  category text not null,
  original_filename text not null,
  storage_path text not null unique,
  mime_type text,
  size_bytes bigint,
  uploaded_by uuid references public.profiles(id) on delete restrict,
  uploaded_at timestamptz not null default now(),
  third_party_submission_id uuid,
  notes text
);

create table public.claim_timeline (
  id uuid primary key default gen_random_uuid(),
  claim_id uuid not null references public.claims(id) on delete restrict,
  event_type text not null,
  description text not null,
  metadata jsonb not null default '{}'::jsonb,
  actor_id uuid references public.profiles(id) on delete restrict,
  occurred_at timestamptz not null default now()
);
create index claim_timeline_claim_time_idx on public.claim_timeline(claim_id, occurred_at desc);

create table public.workshop_repairs (
  id uuid primary key default gen_random_uuid(),
  claim_id uuid not null unique references public.claims(id) on delete restrict,
  entry_at timestamptz,
  diagnosis text,
  services_performed text,
  internal_repair_cost numeric(14,2) not null default 0 check (internal_repair_cost >= 0),
  expected_completion_at date,
  completed_at timestamptz,
  status public.repair_status not null default 'nao_iniciado',
  updated_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.driver_charges (
  id uuid primary key default gen_random_uuid(),
  claim_id uuid not null unique references public.claims(id) on delete restrict,
  amount_to_charge numeric(14,2) not null default 0 check (amount_to_charge >= 0),
  notes text,
  updated_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.charge_payments (
  id uuid primary key default gen_random_uuid(),
  charge_id uuid not null references public.driver_charges(id) on delete restrict,
  amount_paid numeric(14,2) not null check (amount_paid > 0),
  paid_at date not null default current_date,
  payment_method text,
  reference text,
  recorded_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);
create index charge_payments_charge_idx on public.charge_payments(charge_id);

create table public.third_parties (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text,
  email text,
  document_number text,
  vehicle_plate text,
  vehicle_description text,
  created_at timestamptz not null default now()
);

create table public.third_party_submissions (
  id uuid primary key default gen_random_uuid(),
  claim_id uuid not null references public.claims(id) on delete restrict,
  third_party_id uuid references public.third_parties(id) on delete restrict,
  token_hash text not null unique,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  submitted_at timestamptz,
  status text not null default 'aguardando',
  created_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);
create index third_party_submissions_claim_idx on public.third_party_submissions(claim_id);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  record_id uuid not null,
  action text not null,
  before_data jsonb,
  after_data jsonb,
  actor_id uuid references public.profiles(id) on delete restrict,
  occurred_at timestamptz not null default now()
);

-- Saldo financeiro: valor cobrado menos a soma dos pagamentos registrados.
create view public.driver_charge_balances as
select
  dc.id as charge_id,
  dc.claim_id,
  dc.amount_to_charge,
  coalesce(sum(cp.amount_paid), 0)::numeric(14,2) as amount_paid,
  (dc.amount_to_charge - coalesce(sum(cp.amount_paid), 0))::numeric(14,2) as outstanding_balance
from public.driver_charges dc
left join public.charge_payments cp on cp.charge_id = dc.id
group by dc.id, dc.claim_id, dc.amount_to_charge;

-- Não habilitar a aplicação operacional antes de definir políticas RLS específicas
-- por papel, especialmente para oficina, consulta e envio público por terceiros.
