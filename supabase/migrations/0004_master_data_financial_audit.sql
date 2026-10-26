-- 0004: auditoria dos cadastros e movimentos financeiros.
-- Registra snapshots antes/depois para permitir rastrear alterações administrativas.
create or replace function public.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  row_id uuid;
  before_json jsonb;
  after_json jsonb;
  actor uuid := auth.uid();
  action_name text := lower(tg_op);
begin
  if tg_op = 'INSERT' then
    after_json := to_jsonb(new);
    row_id := (after_json ->> 'id')::uuid;
  elsif tg_op = 'UPDATE' then
    before_json := to_jsonb(old);
    after_json := to_jsonb(new);
    row_id := (after_json ->> 'id')::uuid;
  else
    before_json := to_jsonb(old);
    row_id := (before_json ->> 'id')::uuid;
  end if;

  insert into public.audit_logs
    (table_name, record_id, action, before_data, after_data, actor_id)
  values
    (tg_table_name, row_id, action_name, before_json, after_json, actor);

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists vehicles_audit_row on public.vehicles;
create trigger vehicles_audit_row after insert or update or delete on public.vehicles
for each row execute function public.audit_row_change();

drop trigger if exists trailers_audit_row on public.trailers;
create trigger trailers_audit_row after insert or update or delete on public.trailers
for each row execute function public.audit_row_change();

drop trigger if exists drivers_audit_row on public.drivers;
create trigger drivers_audit_row after insert or update or delete on public.drivers
for each row execute function public.audit_row_change();

drop trigger if exists insurers_audit_row on public.insurers;
create trigger insurers_audit_row after insert or update or delete on public.insurers
for each row execute function public.audit_row_change();

drop trigger if exists workshop_repairs_audit_row on public.workshop_repairs;
create trigger workshop_repairs_audit_row after insert or update or delete on public.workshop_repairs
for each row execute function public.audit_row_change();

drop trigger if exists driver_charges_audit_row on public.driver_charges;
create trigger driver_charges_audit_row after insert or update or delete on public.driver_charges
for each row execute function public.audit_row_change();

drop trigger if exists charge_payments_audit_row on public.charge_payments;
create trigger charge_payments_audit_row after insert or update or delete on public.charge_payments
for each row execute function public.audit_row_change();

-- Índices para as consultas mais comuns de operação, SLA e pesquisa.
create index if not exists claims_owner_status_idx
  on public.claims(internal_owner, status);
create index if not exists claims_stage_status_idx
  on public.claims(current_stage, status);
create index if not exists claims_next_action_idx
  on public.claims(next_action_at) where status = 'ativo';
create index if not exists vehicles_active_plate_idx
  on public.vehicles(active, plate);
create index if not exists trailers_active_plate_idx
  on public.trailers(active, plate);
create index if not exists insurers_active_name_idx
  on public.insurers(active, name);
create index if not exists audit_logs_record_time_idx
  on public.audit_logs(table_name, record_id, occurred_at desc);
