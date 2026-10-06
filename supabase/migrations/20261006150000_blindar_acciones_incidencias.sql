-- ============================================================
-- ETAPA 6
-- BLINDAJE DE ACCIONES SOBRE INCIDENCIAS
--
-- Las acciones ya no se autorizan solo por ROL/AREA.
-- Deben pertenecer a la estructura operativa del usuario.
-- ============================================================


-- ============================================================
-- ACEPTAR INCIDENCIA
-- ============================================================

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

  if not public.can_act_on_incident(p_incident_id) then
    raise exception
      'No tiene permiso para aceptar esta incidencia';
  end if;

  if v_incident.estado <> 'PENDIENTE' then
    raise exception
      'Solo puede aceptarse una incidencia PENDIENTE';
  end if;

  v_area := v_incident.area_responsable;

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
    v_area,
    v_area,
    auth.uid()
  );

  return v_incident;
end;
$$;


-- ============================================================
-- RECHAZAR INCIDENCIA
-- ============================================================

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

  if not public.can_act_on_incident(p_incident_id) then
    raise exception
      'No tiene permiso para rechazar esta incidencia';
  end if;

  if v_incident.estado <> 'PENDIENTE' then
    raise exception
      'Solo puede rechazarse una incidencia PENDIENTE';
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
    'PENDIENTE',
    'RECHAZADA',
    v_area,
    v_area,
    auth.uid(),
    trim(p_motivo)
  );

  return v_incident;
end;
$$;


-- ============================================================
-- RESOLVER INCIDENCIA
-- ============================================================

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

  if not public.can_act_on_incident(p_incident_id) then
    raise exception
      'No tiene permiso para resolver esta incidencia';
  end if;

  if v_incident.estado not in ('PENDIENTE', 'ACEPTADA') then
    raise exception
      'La incidencia no puede resolverse en su estado actual';
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


-- ============================================================
-- CERRAR INCIDENCIA
-- ============================================================

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

  if not public.can_act_on_incident(p_incident_id) then
    raise exception
      'No tiene permiso para cerrar esta incidencia';
  end if;

  if v_incident.estado <> 'RESUELTA' then
    raise exception
      'Solo puede cerrarse una incidencia RESUELTA';
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


-- ============================================================
-- PERMISOS
-- ============================================================

revoke all on function public.accept_incident(bigint)
from public, anon;

revoke all on function public.reject_incident(bigint, text)
from public, anon;

revoke all on function public.resolve_incident(bigint, text)
from public, anon;

revoke all on function public.close_incident(bigint)
from public, anon;

grant execute on function public.accept_incident(bigint)
to authenticated;

grant execute on function public.reject_incident(bigint, text)
to authenticated;

grant execute on function public.resolve_incident(bigint, text)
to authenticated;

grant execute on function public.close_incident(bigint)
to authenticated;