-- ============================================================
-- ETAPA 6
-- DERIVACION DE MULTIPLES INCIDENCIAS DEL MISMO PEDIDO
--
-- Si el pedido sigue activo en una planilla:
--   se retira y pasa a GUARDADO.
--
-- Si otra incidencia del mismo pedido se deriva después:
--   se deriva la incidencia sin volver a retirar el pedido.
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
  v_tiene_relacion_activa boolean := false;
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

  -- Primero buscamos si el pedido todavía tiene relación operativa activa.
  select dso.*
  into v_relation
  from public.delivery_sheet_orders dso
  where dso.order_id = v_incident.order_id
    and dso.activo = true
  limit 1
  for update;

  v_tiene_relacion_activa := found;

  if v_tiene_relacion_activa then

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

  else

    -- El pedido pudo haber sido retirado previamente por otra incidencia.
    -- En ese caso usamos la planilla registrada en esta incidencia.
    if v_incident.delivery_sheet_id is null then
      raise exception
        'La incidencia no tiene una planilla asociada';
    end if;

    select *
    into v_sheet
    from public.delivery_sheets
    where id = v_incident.delivery_sheet_id
    for update;

    if not found then
      raise exception 'La planilla asociada no existe';
    end if;

    -- Debe existir relación histórica del mismo pedido con esa planilla.
    if not exists (
      select 1
      from public.delivery_sheet_orders dso
      where dso.delivery_sheet_id = v_sheet.id
        and dso.order_id = v_incident.order_id
    ) then
      raise exception
        'El pedido no tiene relación histórica con la planilla de la incidencia';
    end if;

  end if;

  if not public.is_admin()
     and v_sheet.monitor_id <> auth.uid() then
    raise exception
      'Solo el Monitor responsable de la planilla puede derivar esta incidencia';
  end if;

  v_estado_anterior := v_incident.estado;

  -- Solo la primera incidencia que retira al pedido modifica
  -- la relación operativa y el estado del pedido.
  if v_tiene_relacion_activa then

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

  end if;

  -- La incidencia siempre se deriva usando el mismo registro.
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