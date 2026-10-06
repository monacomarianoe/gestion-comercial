-- ============================================================
-- ETAPA 6E.3
-- ACCIONES CONTROLADAS DE INCIDENCIAS
-- ============================================================

-- ------------------------------------------------------------
-- CREAR INCIDENCIA
-- ------------------------------------------------------------

create or replace function public.create_incident(
  p_area_origen public.incident_area,
  p_area_responsable public.incident_area,
  p_tipo text,
  p_detalle text,
  p_order_id bigint default null,
  p_delivery_sheet_id bigint default null
)
returns public.incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  if p_tipo is null or length(trim(p_tipo)) = 0 then
    raise exception 'Debe indicar el tipo de incidencia';
  end if;

  if p_detalle is null or length(trim(p_detalle)) = 0 then
    raise exception 'Debe indicar el detalle de la incidencia';
  end if;

  if p_order_id is null and p_delivery_sheet_id is null then
    raise exception 'La incidencia debe estar vinculada a un pedido o planilla';
  end if;

  if p_order_id is not null
     and not exists (
       select 1 from public.orders where id = p_order_id
     ) then
    raise exception 'El pedido indicado no existe';
  end if;

  if p_delivery_sheet_id is not null
     and not exists (
       select 1
       from public.delivery_sheets
       where id = p_delivery_sheet_id
     ) then
    raise exception 'La planilla indicada no existe';
  end if;

  insert into public.incidents (
    estado,
    area_origen,
    area_responsable,
    creada_por,
    order_id,
    delivery_sheet_id,
    tipo,
    detalle
  )
  values (
    'PENDIENTE',
    p_area_origen,
    p_area_responsable,
    auth.uid(),
    p_order_id,
    p_delivery_sheet_id,
    trim(p_tipo),
    trim(p_detalle)
  )
  returning *
  into v_incident;

  return v_incident;
end;
$$;


-- ------------------------------------------------------------
-- ACEPTAR
-- PENDIENTE -> ACEPTADA
-- ------------------------------------------------------------

create or replace function public.accept_incident(
  p_incident_id bigint
)
returns public.incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  select *
  into v_incident
  from public.incidents
  where id = p_incident_id
  for update;

  if not found then
    raise exception 'La incidencia no existe';
  end if;

  if v_incident.estado <> 'PENDIENTE' then
    raise exception 'Solo puede aceptarse una incidencia PENDIENTE';
  end if;

  update public.incidents
  set estado = 'ACEPTADA',
      responsable_usuario_id = auth.uid(),
      accepted_at = now(),
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
    realizado_por
  )
  values (
    p_incident_id,
    'ACEPTADA',
    'PENDIENTE',
    'ACEPTADA',
    v_incident.area_responsable,
    v_incident.area_responsable,
    auth.uid()
  );

  return v_incident;
end;
$$;


-- ------------------------------------------------------------
-- RECHAZAR
-- Requiere motivo.
-- ------------------------------------------------------------

create or replace function public.reject_incident(
  p_incident_id bigint,
  p_motivo text
)
returns public.incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
  v_area public.incident_area;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  if p_motivo is null or length(trim(p_motivo)) = 0 then
    raise exception 'Debe indicar el motivo del rechazo';
  end if;

  select *
  into v_incident
  from public.incidents
  where id = p_incident_id
  for update;

  if not found then
    raise exception 'La incidencia no existe';
  end if;

  if v_incident.estado not in ('PENDIENTE', 'ACEPTADA') then
    raise exception 'La incidencia ya no puede rechazarse';
  end if;

  v_area := v_incident.area_responsable;

  update public.incidents
  set estado = 'RECHAZADA',
      motivo_rechazo = trim(p_motivo),
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
    'RECHAZADA',
    case
      when v_incident.accepted_at is null
        then 'PENDIENTE'::public.incident_status
      else 'ACEPTADA'::public.incident_status
    end,
    'RECHAZADA',
    v_area,
    v_area,
    auth.uid(),
    trim(p_motivo)
  );

  return v_incident;
end;
$$;


-- ------------------------------------------------------------
-- RESOLVER
-- PENDIENTE/ACEPTADA -> RESUELTA
-- ------------------------------------------------------------

create or replace function public.resolve_incident(
  p_incident_id bigint,
  p_resolucion text
)
returns public.incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
  v_estado_anterior public.incident_status;
  v_area public.incident_area;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  if p_resolucion is null or length(trim(p_resolucion)) = 0 then
    raise exception 'Debe indicar la resolucion';
  end if;

  select *
  into v_incident
  from public.incidents
  where id = p_incident_id
  for update;

  if not found then
    raise exception 'La incidencia no existe';
  end if;

  if v_incident.estado not in ('PENDIENTE', 'ACEPTADA') then
    raise exception 'La incidencia no puede resolverse en su estado actual';
  end if;

  v_estado_anterior := v_incident.estado;
  v_area := v_incident.area_responsable;

  update public.incidents
  set estado = 'RESUELTA',
      resolucion = trim(p_resolucion),
      resolved_at = now(),
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
    'RESUELTA',
    v_estado_anterior,
    'RESUELTA',
    v_area,
    v_area,
    auth.uid(),
    trim(p_resolucion)
  );

  return v_incident;
end;
$$;


-- ------------------------------------------------------------
-- CERRAR
-- RESUELTA -> CERRADA
-- ------------------------------------------------------------

create or replace function public.close_incident(
  p_incident_id bigint
)
returns public.incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
  v_area public.incident_area;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  select *
  into v_incident
  from public.incidents
  where id = p_incident_id
  for update;

  if not found then
    raise exception 'La incidencia no existe';
  end if;

  if v_incident.estado <> 'RESUELTA' then
    raise exception 'Solo puede cerrarse una incidencia RESUELTA';
  end if;

  v_area := v_incident.area_responsable;

  update public.incidents
  set estado = 'CERRADA',
      closed_at = now(),
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
    realizado_por
  )
  values (
    p_incident_id,
    'CERRADA',
    'RESUELTA',
    'CERRADA',
    v_area,
    v_area,
    auth.uid()
  );

  return v_incident;
end;
$$;


-- ------------------------------------------------------------
-- PERMISOS
-- No damos INSERT/UPDATE/DELETE directo sobre incidents.
-- Las mutaciones pasan por estas RPC.
-- ------------------------------------------------------------

revoke all on function public.create_incident(
  public.incident_area,
  public.incident_area,
  text,
  text,
  bigint,
  bigint
) from public, anon;

revoke all on function public.accept_incident(bigint)
from public, anon;

revoke all on function public.reject_incident(bigint, text)
from public, anon;

revoke all on function public.resolve_incident(bigint, text)
from public, anon;

revoke all on function public.close_incident(bigint)
from public, anon;


grant execute on function public.create_incident(
  public.incident_area,
  public.incident_area,
  text,
  text,
  bigint,
  bigint
) to authenticated;

grant execute on function public.accept_incident(bigint)
to authenticated;

grant execute on function public.reject_incident(bigint, text)
to authenticated;

grant execute on function public.resolve_incident(bigint, text)
to authenticated;

grant execute on function public.close_incident(bigint)
to authenticated;