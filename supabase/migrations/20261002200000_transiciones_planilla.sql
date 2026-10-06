-- ============================================================
-- ETAPA 6D
-- TRANSICIONES CONTROLADAS DE PLANILLA
-- ============================================================

-- ------------------------------------------------------------
-- ARMADA -> ASIGNADA
-- Ejecuta Monitor propietario o Admin.
-- ------------------------------------------------------------

create or replace function public.assign_delivery_sheet(
  p_delivery_sheet_id bigint
)
returns public.delivery_sheets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sheet public.delivery_sheets%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  select *
  into v_sheet
  from public.delivery_sheets
  where id = p_delivery_sheet_id
  for update;

  if not found then
    raise exception 'La planilla no existe';
  end if;

  if not public.is_admin()
     and v_sheet.monitor_id <> auth.uid() then
    raise exception 'Solo el Monitor responsable puede asignar esta planilla';
  end if;

  if v_sheet.estado <> 'ARMADA' then
    raise exception
      'Solo puede asignarse una planilla en estado ARMADA';
  end if;

  if v_sheet.repartidor_id is null or v_sheet.vehicle_id is null then
    raise exception
      'La planilla debe tener Repartidor y vehiculo antes de ser asignada';
  end if;

  update public.delivery_sheets
  set estado = 'ASIGNADA',
      asignada_at = now(),
      updated_at = now()
  where id = p_delivery_sheet_id
  returning *
  into v_sheet;

  return v_sheet;
end;
$$;


-- ------------------------------------------------------------
-- ASIGNADA -> ACEPTADA
-- Únicamente el Repartidor asignado.
-- ------------------------------------------------------------

create or replace function public.accept_delivery_sheet(
  p_delivery_sheet_id bigint
)
returns public.delivery_sheets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sheet public.delivery_sheets%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  select *
  into v_sheet
  from public.delivery_sheets
  where id = p_delivery_sheet_id
  for update;

  if not found then
    raise exception 'La planilla no existe';
  end if;

  if v_sheet.repartidor_id <> auth.uid() then
    raise exception
      'Solo el Repartidor asignado puede aceptar esta planilla';
  end if;

  if v_sheet.estado <> 'ASIGNADA' then
    raise exception
      'Solo puede aceptarse una planilla en estado ASIGNADA';
  end if;

  update public.delivery_sheets
  set estado = 'ACEPTADA',
      updated_at = now()
  where id = p_delivery_sheet_id
  returning *
  into v_sheet;

  return v_sheet;
end;
$$;


-- ------------------------------------------------------------
-- ACEPTADA -> EN_REPARTO
-- Únicamente el Repartidor asignado.
-- ------------------------------------------------------------

create or replace function public.start_delivery_route(
  p_delivery_sheet_id bigint
)
returns public.delivery_sheets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sheet public.delivery_sheets%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  select *
  into v_sheet
  from public.delivery_sheets
  where id = p_delivery_sheet_id
  for update;

  if not found then
    raise exception 'La planilla no existe';
  end if;

  if v_sheet.repartidor_id <> auth.uid() then
    raise exception
      'Solo el Repartidor asignado puede iniciar el reparto';
  end if;

  if v_sheet.estado <> 'ACEPTADA' then
    raise exception
      'Solo puede iniciarse una planilla en estado ACEPTADA';
  end if;

  update public.delivery_sheets
  set estado = 'EN_REPARTO',
      inicio_reparto_at = now(),
      updated_at = now()
  where id = p_delivery_sheet_id
  returning *
  into v_sheet;

  return v_sheet;
end;
$$;


-- ------------------------------------------------------------
-- EN_REPARTO -> CERRADA
-- Monitor propietario o Admin.
--
-- El bloqueo por incidencias abiertas EN MONITOR se incorpora
-- cuando exista el módulo único de Incidencias.
-- ------------------------------------------------------------

create or replace function public.close_delivery_sheet(
  p_delivery_sheet_id bigint
)
returns public.delivery_sheets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sheet public.delivery_sheets%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  select *
  into v_sheet
  from public.delivery_sheets
  where id = p_delivery_sheet_id
  for update;

  if not found then
    raise exception 'La planilla no existe';
  end if;

  if not public.is_admin()
     and v_sheet.monitor_id <> auth.uid() then
    raise exception
      'Solo el Monitor responsable puede cerrar esta planilla';
  end if;

  if v_sheet.estado <> 'EN_REPARTO' then
    raise exception
      'Solo puede cerrarse una planilla en estado EN_REPARTO';
  end if;

  update public.delivery_sheets
  set estado = 'CERRADA',
      cerrada_at = now(),
      updated_at = now()
  where id = p_delivery_sheet_id
  returning *
  into v_sheet;

  return v_sheet;
end;
$$;


-- ------------------------------------------------------------
-- PROTEGER REASIGNACIÓN DESDE ACEPTADA
-- ------------------------------------------------------------

create or replace function public.protect_accepted_delivery_sheet()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if old.estado in ('ACEPTADA', 'EN_REPARTO', 'CERRADA') then

    if new.repartidor_id is distinct from old.repartidor_id then
      raise exception
        'No puede cambiarse el Repartidor una vez aceptada la planilla';
    end if;

    if new.vehicle_id is distinct from old.vehicle_id then
      raise exception
        'No puede cambiarse el vehiculo una vez aceptada la planilla';
    end if;

  end if;

  return new;
end;
$$;

create trigger trg_protect_accepted_delivery_sheet
before update
on public.delivery_sheets
for each row
execute function public.protect_accepted_delivery_sheet();


-- ------------------------------------------------------------
-- PERMISOS RPC
-- ------------------------------------------------------------

revoke all on function public.assign_delivery_sheet(bigint) from public;
revoke all on function public.accept_delivery_sheet(bigint) from public;
revoke all on function public.start_delivery_route(bigint) from public;
revoke all on function public.close_delivery_sheet(bigint) from public;

revoke all on function public.assign_delivery_sheet(bigint) from anon;
revoke all on function public.accept_delivery_sheet(bigint) from anon;
revoke all on function public.start_delivery_route(bigint) from anon;
revoke all on function public.close_delivery_sheet(bigint) from anon;

grant execute on function public.assign_delivery_sheet(bigint) to authenticated;
grant execute on function public.accept_delivery_sheet(bigint) to authenticated;
grant execute on function public.start_delivery_route(bigint) to authenticated;
grant execute on function public.close_delivery_sheet(bigint) to authenticated;