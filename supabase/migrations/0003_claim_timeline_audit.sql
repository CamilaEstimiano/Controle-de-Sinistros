-- 0003: trilha de auditoria e histórico automático de movimentações.
-- Aplicar primeiro em ambiente de desenvolvimento e validar com os papéis reais.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function public.record_claim_timeline()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
begin
  if tg_op = 'INSERT' then
    insert into public.claim_timeline (claim_id, event_type, description, metadata, actor_id)
    values (
      new.id,
      'criacao',
      'Sinistro criado',
      jsonb_build_object('status', new.status, 'etapa', new.current_stage),
      coalesce(new.created_by, actor)
    );
    return new;
  end if;

  if old.current_stage is distinct from new.current_stage then
    insert into public.claim_stage_history
      (claim_id, from_stage, to_stage, changed_by, notes)
    values
      (new.id, old.current_stage, new.current_stage, actor, 'Mudança registrada automaticamente');

    insert into public.claim_timeline (claim_id, event_type, description, metadata, actor_id)
    values (
      new.id, 'mudanca_etapa',
      format('Etapa alterada de %s para %s', old.current_stage, new.current_stage),
      jsonb_build_object('etapa_anterior', old.current_stage, 'etapa_nova', new.current_stage),
      actor
    );
  end if;

  if old.status is distinct from new.status then
    insert into public.claim_timeline (claim_id, event_type, description, metadata, actor_id)
    values (
      new.id, 'mudanca_status',
      format('Status alterado de %s para %s', old.status, new.status),
      jsonb_build_object('status_anterior', old.status, 'status_novo', new.status),
      actor
    );
    if new.status in ('encerrado', 'cancelado') and new.closed_at is null then
      new.closed_at := now();
    elsif new.status = 'ativo' then
      new.closed_at := null;
    end if;
  end if;

  if old.next_action is distinct from new.next_action
     or old.next_action_at is distinct from new.next_action_at
     or old.deadline_at is distinct from new.deadline_at
     or old.internal_owner is distinct from new.internal_owner then
    insert into public.claim_timeline (claim_id, event_type, description, metadata, actor_id)
    values (
      new.id, 'acao_prazo_responsavel',
      'Responsável, prazo ou próxima ação atualizado',
      jsonb_build_object(
        'responsavel_anterior', old.internal_owner,
        'responsavel_novo', new.internal_owner,
        'prazo_anterior', old.deadline_at,
        'prazo_novo', new.deadline_at,
        'acao_anterior', old.next_action,
        'acao_nova', new.next_action,
        'data_acao_anterior', old.next_action_at,
        'data_acao_nova', new.next_action_at
      ),
      actor
    );
  end if;

  if to_jsonb(old) - array['updated_at','last_activity_at']::text[]
     is distinct from to_jsonb(new) - array['updated_at','last_activity_at']::text[] then
    new.last_activity_at := now();
    insert into public.audit_logs (table_name, record_id, action, actor_id)
    values ('claims', new.id, 'update', actor);
  end if;

  return new;
end;
$$;

drop trigger if exists claims_timeline_after_insert on public.claims;
create trigger claims_timeline_after_insert
after insert on public.claims
for each row execute function public.record_claim_timeline();

drop trigger if exists claims_timeline_before_update on public.claims;
create trigger claims_timeline_before_update
before update on public.claims
for each row execute function public.record_claim_timeline();

-- O histórico e os logs são append-only: alterações e exclusões são bloqueadas.
create or replace function public.prevent_history_mutation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  raise exception 'Registros de histórico e auditoria não podem ser alterados ou excluídos';
end;
$$;

drop trigger if exists claim_timeline_no_mutation on public.claim_timeline;
create trigger claim_timeline_no_mutation
before update or delete on public.claim_timeline
for each row execute function public.prevent_history_mutation();

drop trigger if exists claim_stage_history_no_mutation on public.claim_stage_history;
create trigger claim_stage_history_no_mutation
before update or delete on public.claim_stage_history
for each row execute function public.prevent_history_mutation();

drop trigger if exists audit_logs_no_mutation on public.audit_logs;
create trigger audit_logs_no_mutation
before update or delete on public.audit_logs
for each row execute function public.prevent_history_mutation();

-- Atividade de documentos também entra na timeline; o arquivo binário deve ficar
-- em bucket privado do Supabase Storage, nunca diretamente no banco.
create or replace function public.record_document_timeline()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.claim_timeline (claim_id, event_type, description, metadata, actor_id)
  values (
    new.claim_id,
    'documento_anexado',
    'Documento anexado ao dossiê',
    jsonb_build_object('categoria', new.category, 'arquivo', new.original_filename),
    coalesce(new.uploaded_by, auth.uid())
  );
  update public.claims set last_activity_at = now() where id = new.claim_id;
  return new;
end;
$$;

drop trigger if exists claim_document_timeline_after_insert on public.claim_documents;
create trigger claim_document_timeline_after_insert
after insert on public.claim_documents
for each row execute function public.record_document_timeline();
