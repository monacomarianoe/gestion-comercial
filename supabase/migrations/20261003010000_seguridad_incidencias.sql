-- ============================================================
-- ETAPA 6E.4
-- SEGURIDAD DE ACCIONES DE INCIDENCIAS
-- ============================================================

-- ------------------------------------------------------------
-- FUNCIÓN AUXILIAR:
-- determina si el usuario actual puede actuar por un área.
--
-- ADMIN puede actuar sobre cualquier área.
-- Los demás solamente sobre su propia área funcional.
-- ------------------------------------------------------------

create or replace function public.can_act_on_incident_area(
  p_area public.incident_area
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    public.is_active_user()
    and (
      public.is_admin()
      or exists (
  select 1
  from public.profiles p
  where p.id = auth.uid()
    and p.activo is true
    and (
      (p_area = 'MONITOR' and p.rol = 'MONITOR')
      or
      (p_area = 'COMERCIAL' and p.rol = 'COMERCIAL')
      or
      (p_area = 'DEPOSITO' and p.rol = 'DEPOSITO')
      or
      (p_area = 'ADMIN' and p.rol = 'ADMIN')
    )
)
    );
$$;


-- ------------------------------------------------------------
-- ACEPTAR
-- Solo el área responsable actual.
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

  if not public.can_act_on_incident_area(v_incident.area_responsable) then
    raise exception
      'No tiene permiso para aceptar incidencias del area %',
      v_incident.area_responsable;
  end if;

  if v_incident.estado <> 'PENDIENTE' then
    raise exception 'Solo puede aceptarse una incidencia PENDIENTE';
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


-- ------------------------------------------------------------
-- RECHAZAR
-- Solo el área responsable actual.
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
  v_estado_anterior public.incident_status;
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

  if not public.can_act_on_incident_area(v_incident.area_responsable) then
    raise exception
      'No tiene permiso para rechazar incidencias del area %',
      v_incident.area_responsable;
  end if;

  if v_incident.estado not in ('PENDIENTE', 'ACEPTADA') then
    raise exception 'La incidencia ya no puede rechazarse';
  end if;

  v_estado_anterior := v_incident.estado;
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
    v_estado_anterior,
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
-- Solo el área responsable actual.
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

  if not public.can_act_on_incident_area(v_incident.area_responsable) then
    raise exception
      'No tiene permiso para resolver incidencias del area %',
      v_incident.area_responsable;
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


-- ------------------------------------------------------------
-- CERRAR
-- Solo el área responsable actual.
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

  if not public.can_act_on_incident_area(v_incident.area_responsable) then
    raise exception
      'No tiene permiso para cerrar incidencias del area %',
      v_incident.area_responsable;
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


-- ------------------------------------------------------------
-- SEGURIDAD DE LA FUNCIÓN AUXILIAR
-- ------------------------------------------------------------

revoke all on function public.can_act_on_incident_area(
  public.incident_area
) from public, anon;

grant execute on function public.can_act_on_incident_area(
  public.incident_area
) to authenticated;