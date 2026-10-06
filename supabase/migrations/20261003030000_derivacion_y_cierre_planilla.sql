-- ============================================================
-- ETAPA 6E.6
-- DERIVACION MONITOR -> COMERCIAL
-- Y BLOQUEO DE CIERRE DE PLANILLA
-- ============================================================

create or replace function public.derive_incident_to_commercial(
  p_incident_id bigint,
  p_detalle text
)
returns public.incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
  v_sheet public.delivery_sheets%rowtype;
  v_relation public.delivery_sheet_orders%rowtype;
  v_estado_anterior public.incident_status;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  if p_detalle is null or length(trim(p_detalle)) = 0 then
    raise exception 'Debe indicar el motivo de la derivacion';
  end if;

  select *
  into v_incident
  from public.incidents
  where id = p_incident_id
  for update;

  if not found then
    raise exception 'La incidencia no existe';
  end if;

  if v_incident.area_responsable <> 'MONITOR' then
    raise exception
      'Solo pueden derivarse a Comercial incidencias actualmente en Monitor';
  end if;

  if v_incident.estado not in ('PENDIENTE', 'ACEPTADA') then
    raise exception
      'Solo pueden derivarse incidencias abiertas';
  end if;

  if v_incident.order_id is null then
    raise exception
      'La derivacion a Comercial requiere una incidencia vinculada a un pedido';
  end if;

  select dso.*
  into v_relation
  from public.delivery_sheet_orders dso
  where dso.order_id = v_incident.order_id
    and dso.activo = true
  for update;

  if not found then
    raise exception
      'El pedido no pertenece actualmente a una planilla activa';
  end if;

  select *
  into v_sheet
  from public.delivery_sheets
  where id = v_relation.delivery_sheet_id
  for update;

  if not found then
    raise exception 'La planilla asociada no existe';
  end if;

  if v_incident.delivery_sheet_id is not null
     and v_incident.delivery_sheet_id <> v_sheet.id then
    raise exception
      'La incidencia no corresponde a la planilla operativa actual del pedido';
  end if;

  if not public.is_admin()
     and v_sheet.monitor_id <> auth.uid() then
    raise exception
      'Solo el Monitor responsable de la planilla puede derivar esta incidencia';
  end if;

  v_estado_anterior := v_incident.estado;

  update public.delivery_sheet_orders
  set activo = false,
      retirado_at = now(),
      retirado_por = auth.uid(),
      motivo_retiro = trim(p_detalle),
      incident_id = p_incident_id
  where id = v_relation.id;

  update public.orders
  set estado = 'GUARDADO',
      updated_at = now()
  where id = v_incident.order_id;

  update public.incidents
  set area_responsable = 'COMERCIAL',
      responsable_usuario_id = null,
      updated_at = now()
  where id = p_incident_id
  returning *
  into v_incident;

  insert into public.incident_history (
    incident_id,
    accion,
    estado_anterior,
    estado_nuevo,
    area_anterior,
    area_nueva,
    realizado_por,
    detalle
  )
  values (
    p_incident_id,
    'DERIVADA',
    v_estado_anterior,
    v_estado_anterior,
    'MONITOR',
    'COMERCIAL',
    auth.uid(),
    trim(p_detalle)
  );

  return v_incident;
end;
$$;

revoke all
on function public.derive_incident_to_commercial(bigint, text)
from public, anon;

grant execute
on function public.derive_incident_to_commercial(bigint, text)
to authenticated;


-- ============================================================
-- CIERRE DE PLANILLA
-- Solo bloquean incidencias ABIERTAS cuyo responsable actual
-- siga siendo MONITOR.
-- ============================================================

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

  if exists (
    select 1
    from public.incidents i
    where i.area_responsable = 'MONITOR'
      and i.estado in ('PENDIENTE', 'ACEPTADA')
      and (
        i.delivery_sheet_id = p_delivery_sheet_id
        or exists (
          select 1
          from public.delivery_sheet_orders dso
          where dso.delivery_sheet_id = p_delivery_sheet_id
            and dso.activo = true
            and dso.order_id = i.order_id
        )
      )
  ) then
    raise exception
      'La planilla tiene incidencias abiertas pendientes en Monitor';
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