-- ============================================================
-- ETAPA 6
-- BLINDAJE HISTORICO DE DERIVACION DE INCIDENCIAS
--
-- Una incidencia vinculada a una planilla conserva para siempre
-- el alcance de ESA planilla.
--
-- Si el pedido luego entra en otra planilla, una incidencia vieja
-- nunca puede retirar ni modificar la nueva relacion operativa.
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
  v_retirar_pedido boolean := false;
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

  -- ----------------------------------------------------------
  -- CASO 1:
  -- La incidencia ya tiene planilla.
  -- Esa planilla es su alcance historico y es la UNICA que
  -- puede consultar/modificar esta incidencia.
  -- ----------------------------------------------------------

  if v_incident.delivery_sheet_id is not null then

    select *
    into v_sheet
    from public.delivery_sheets
    where id = v_incident.delivery_sheet_id
    for update;

    if not found then
      raise exception 'La planilla asociada no existe';
    end if;

    select dso.*
    into v_relation
    from public.delivery_sheet_orders dso
    where dso.delivery_sheet_id = v_incident.delivery_sheet_id
      and dso.order_id = v_incident.order_id
    order by dso.id desc
    limit 1
    for update;

    if not found then
      raise exception
        'El pedido no tiene relacion historica con la planilla de la incidencia';
    end if;

    -- Solo retiramos si LA MISMA relacion historica de esta
    -- incidencia todavia sigue activa.
    v_retirar_pedido := v_relation.activo;

  else

    -- --------------------------------------------------------
    -- CASO 2:
    -- Incidencia antigua sin planilla registrada.
    -- Solo en este caso tomamos la relacion operativa activa.
    -- Una vez localizada, fijamos la planilla en la incidencia
    -- para que desde este momento quede historicamente ligada.
    -- --------------------------------------------------------

    select dso.*
    into v_relation
    from public.delivery_sheet_orders dso
    where dso.order_id = v_incident.order_id
      and dso.activo = true
    limit 1
    for update;

    if not found then
      raise exception
        'La incidencia no tiene planilla asociada ni relacion operativa activa';
    end if;

    select *
    into v_sheet
    from public.delivery_sheets
    where id = v_relation.delivery_sheet_id
    for update;

    if not found then
      raise exception 'La planilla asociada no existe';
    end if;

    update public.incidents
    set delivery_sheet_id = v_sheet.id,
        updated_at = now()
    where id = p_incident_id;

    v_incident.delivery_sheet_id := v_sheet.id;
    v_retirar_pedido := true;

  end if;

  -- Solo ADMIN o el Monitor dueÃ±o de ESA planilla histÃ³rica.
  if not public.is_admin()
     and v_sheet.monitor_id <> auth.uid() then
    raise exception
      'Solo el Monitor responsable de la planilla puede derivar esta incidencia';
  end if;

  v_estado_anterior := v_incident.estado;

  -- ----------------------------------------------------------
  -- Retiro operativo:
  -- Ãºnicamente si la relacion perteneciente a la planilla de
  -- ESTA incidencia sigue activa.
  -- ----------------------------------------------------------

  if v_retirar_pedido then

    update public.delivery_sheet_orders
    set activo = false,
        retirado_at = now(),
        retirado_por = auth.uid(),
        motivo_retiro = trim(p_detalle),
        incident_id = p_incident_id
    where id = v_relation.id
      and activo = true;

    update public.orders
    set estado = 'GUARDADO',
        updated_at = now()
    where id = v_incident.order_id;

  end if;

  -- ----------------------------------------------------------
  -- La derivacion usa siempre el MISMO registro de incidencia.
  -- ----------------------------------------------------------

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
