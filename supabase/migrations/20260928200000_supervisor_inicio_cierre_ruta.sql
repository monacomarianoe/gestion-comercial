-- ============================================================
-- ETAPA 5
-- Bloque 8: Inicio y cierre de ruta del Supervisor
--
-- La planificación ya vive en supervisor_workdays.
-- Se agregan los datos de ejecución real de esa jornada.
-- ============================================================


-- ============================================================
-- COLUMNAS DE EJECUCION
-- ============================================================

alter table public.supervisor_workdays
  add column inicio_ruta_at timestamptz,
  add column inicio_lat double precision,
  add column inicio_lng double precision,
  add column cierre_ruta_at timestamptz,
  add column cierre_lat double precision,
  add column cierre_lng double precision;


-- Coordenadas válidas cuando existan.

alter table public.supervisor_workdays
  add constraint supervisor_workdays_inicio_lat_check
    check (inicio_lat is null or inicio_lat between -90 and 90),

  add constraint supervisor_workdays_inicio_lng_check
    check (inicio_lng is null or inicio_lng between -180 and 180),

  add constraint supervisor_workdays_cierre_lat_check
    check (cierre_lat is null or cierre_lat between -90 and 90),

  add constraint supervisor_workdays_cierre_lng_check
    check (cierre_lng is null or cierre_lng between -180 and 180),

  add constraint supervisor_workdays_cierre_after_inicio_check
    check (
      cierre_ruta_at is null
      or (
        inicio_ruta_at is not null
        and cierre_ruta_at >= inicio_ruta_at
      )
    );


-- ============================================================
-- FUNCIONES CONTROLADAS
--
-- El Supervisor inicia/cierra solamente su propia jornada.
-- No recibe permiso general para modificar la planificación
-- creada por Comercial.
-- ============================================================

create or replace function public.start_supervisor_route(
  p_workday_id bigint,
  p_lat double precision default null,
  p_lng double precision default null
)
returns public.supervisor_workdays
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workday public.supervisor_workdays;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autorizado';
  end if;

  select *
  into v_workday
  from public.supervisor_workdays
  where id = p_workday_id
  for update;

  if not found then
    raise exception 'Jornada de Supervisor inexistente';
  end if;

  if v_workday.supervisor_id <> auth.uid() then
    raise exception 'Solo el Supervisor asignado puede iniciar esta ruta';
  end if;

  if v_workday.fecha <> current_date then
    raise exception 'Solo puede iniciarse la ruta correspondiente al dia actual';
  end if;

  if v_workday.inicio_ruta_at is not null then
    raise exception 'La ruta del Supervisor ya fue iniciada';
  end if;

  if p_lat is not null and (p_lat < -90 or p_lat > 90) then
    raise exception 'Latitud invalida';
  end if;

  if p_lng is not null and (p_lng < -180 or p_lng > 180) then
    raise exception 'Longitud invalida';
  end if;

  update public.supervisor_workdays
  set
    inicio_ruta_at = now(),
    inicio_lat = p_lat,
    inicio_lng = p_lng
  where id = p_workday_id
  returning * into v_workday;

  return v_workday;
end;
$$;


create or replace function public.close_supervisor_route(
  p_workday_id bigint,
  p_lat double precision default null,
  p_lng double precision default null
)
returns public.supervisor_workdays
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workday public.supervisor_workdays;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autorizado';
  end if;

  select *
  into v_workday
  from public.supervisor_workdays
  where id = p_workday_id
  for update;

  if not found then
    raise exception 'Jornada de Supervisor inexistente';
  end if;

  if v_workday.supervisor_id <> auth.uid() then
    raise exception 'Solo el Supervisor asignado puede cerrar esta ruta';
  end if;

  if v_workday.fecha <> current_date then
    raise exception 'Solo puede cerrarse la ruta correspondiente al dia actual';
  end if;

  if v_workday.inicio_ruta_at is null then
    raise exception 'La ruta del Supervisor no fue iniciada';
  end if;

  if v_workday.cierre_ruta_at is not null then
    raise exception 'La ruta del Supervisor ya fue cerrada';
  end if;

  if p_lat is not null and (p_lat < -90 or p_lat > 90) then
    raise exception 'Latitud invalida';
  end if;

  if p_lng is not null and (p_lng < -180 or p_lng > 180) then
    raise exception 'Longitud invalida';
  end if;

  update public.supervisor_workdays
  set
    cierre_ruta_at = now(),
    cierre_lat = p_lat,
    cierre_lng = p_lng
  where id = p_workday_id
  returning * into v_workday;

  return v_workday;
end;
$$;


-- ============================================================
-- PERMISOS
-- ============================================================

revoke all
on function public.start_supervisor_route(bigint, double precision, double precision)
from public, anon;

revoke all
on function public.close_supervisor_route(bigint, double precision, double precision)
from public, anon;

grant execute
on function public.start_supervisor_route(bigint, double precision, double precision)
to authenticated;

grant execute
on function public.close_supervisor_route(bigint, double precision, double precision)
to authenticated;