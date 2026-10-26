-- CONTROLE DE SINISTROS — endurecimento inicial de segurança.
-- Todas as tabelas começam fechadas para acesso pela API até que políticas específicas
-- sejam implementadas e testadas. Não publicar o portal externo antes da Edge Function
-- de submissão validar token, expiração, limites e arquivos.

alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.trailers enable row level security;
alter table public.drivers enable row level security;
alter table public.insurers enable row level security;
alter table public.claims enable row level security;
alter table public.claim_stage_history enable row level security;
alter table public.claim_documents enable row level security;
alter table public.claim_timeline enable row level security;
alter table public.workshop_repairs enable row level security;
alter table public.driver_charges enable row level security;
alter table public.charge_payments enable row level security;
alter table public.third_parties enable row level security;
alter table public.third_party_submissions enable row level security;
alter table public.audit_logs enable row level security;

create table public.third_party_files (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.third_party_submissions(id) on delete restrict,
  original_filename text not null,
  storage_path text not null unique,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes > 0),
  uploaded_at timestamptz not null default now()
);
alter table public.third_party_files enable row level security;

comment on table public.third_party_files is
  'Metadados de arquivos recebidos pelo portal externo. O armazenamento deve ser privado; acesso público somente via endpoint validado e limitado.';

-- Sem políticas, o acesso por API fica negado por padrão. Próxima migração deve criar
-- políticas específicas para gestor_frota, oficina atribuída e consulta somente leitura.
-- O portal externo deverá usar uma Edge Function com token hashado; não conceder leitura
-- anônima direta a claims, submissions ou arquivos.
