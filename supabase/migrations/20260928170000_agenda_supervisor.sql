-- ============================================================
-- ETAPA 5 - SUPERVISOR
-- Bloque 5: Agenda, visitas, seguimiento y trazabilidad
-- ============================================================

create type public.supervisor_visit_status as enum (
  'PENDIENTE',
  'EN_CURSO',
  'CERRADA'
);

create type public.supervisor_visit_result as enum (
  'VENTA',
  'RESUELTO',
  'REPROGRAMADO',
  'SEGUIMIENTO',
  'DERIVADO_COMERCIAL'
);

create type public.supervisor_visit_origin as enum (
  'COMERCIAL',
  'SUPERVISOR',
  'REPROGRAMACION',
  'SEGUIMIENTO'
);


-- ============================================================
-- AGENDA / VISITAS
-- ============================================================

create table public.supervisor_visits (
  id bigint generated always as identity primary key,

  supervisor_id uuid not null
    references public.profiles(id),

  client_id bigint not null
    references public.clients(id),

  fecha_programada date not null,

  -- Puede utilizarse más adelante para ordenar la agenda.
  hora_programada time,

  origen public.supervisor_visit_origin not null,

  -- Visita que originó esta nueva visita.
  parent_visit_id bigint
    references public.supervisor_visits(id),

  objetivo text not null,

  estado public.supervisor_visit_status not null
    default 'PENDIENTE',

  resultado public.supervisor_visit_result,

  detalle_cierre text,

  -- Para VENTA.
  order_id bigint
    references public.orders(id),

  -- Para REPROGRAMADO / SEGUIMIENTO.
  proxima_fecha date,

  proxima_accion text,

  -- DERIVADO_COMERCIAL:
  -- La incidencia real se vinculará cuando construyamos
  -- el módulo de Incidencias.
  requiere_incidencia_comercial boolean not null
    default false,

  iniciado_at timestamptz,
  cerrado_at timestamptz,

  creado_por uuid not null
    references public.profiles(id),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint supervisor_visit_closed_consistency
  check (
    (
      estado <> 'CERRADA'
      and resultado is null
      and cerrado_at is null
    )
    or
    (
      estado = 'CERRADA'
      and resultado is not null
      and cerrado_at is not null
    )
  )
);


-- ============================================================
-- VALIDAR CREACION DE VISITA
-- ============================================================

create or replace function public.validate_supervisor_visit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_supervisor_role public.app_role;
  v_supervisor_active boolean;
  v_client_status public.client_status;
begin

  select rol, activo
  into v_supervisor_role, v_supervisor_active
  from public.profiles
  where id = new.supervisor_id;

  if v_supervisor_role <> 'SUPERVISOR'
     or v_supervisor_active is not true then
    raise exception
      'La visita debe asignarse a un supervisor activo'
      using errcode = 'P0001';
  end if;

  select estado
  into v_client_status
  from public.clients
  where id = new.client_id;

  if v_client_status <> 'ACTIVO' then
    raise exception
      'No se puede programar una visita a un cliente inactivo'
      using errcode = 'P0001';
  end if;

  -- Comercial solo puede asignar visitas a supervisores
  -- de su estructura efectiva.
  if new.origen = 'COMERCIAL'
     and not public.is_effective_commercial_of_supervisor(
       new.creado_por,
       new.supervisor_id,
       new.fecha_programada::timestamptz + interval '12 hours'
     )
  then
    raise exception
      'El supervisor no pertenece a la estructura efectiva del Comercial'
      using errcode = 'P0001';
  end if;

  -- El Supervisor puede crear tareas para sí mismo.
if new.origen = 'SUPERVISOR'
   and new.creado_por <> new.supervisor_id
then
  raise exception
    'Una visita creada por Supervisor solo puede asignarse a si mismo'
    using errcode = 'P0001';
end if;


-- REPROGRAMACION y SEGUIMIENTO siempre deben nacer
-- de una visita anterior.
if new.origen in ('REPROGRAMACION', 'SEGUIMIENTO') then

  if new.parent_visit_id is null then
    raise exception
      'Una reprogramacion o seguimiento requiere visita de origen'
      using errcode = 'P0001';
  end if;

  if not exists (
    select 1
    from public.supervisor_visits v
    where v.id = new.parent_visit_id
      and v.supervisor_id = new.supervisor_id
      and v.client_id = new.client_id
  ) then
    raise exception
      'La visita de origen no corresponde al mismo Supervisor y cliente'
      using errcode = 'P0001';
  end if;

end if;

return new;
end;
$$;

create trigger trg_validate_supervisor_visit
before insert
on public.supervisor_visits
for each row
execute function public.validate_supervisor_visit();


-- ============================================================
-- CIERRE DE VISITA
--
-- Una visita NO puede cerrarse "sin más".
-- Debe terminar con resolución o continuidad concreta.
-- ============================================================

create or replace function public.validate_supervisor_visit_close()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

  if new.estado = 'CERRADA'
     and old.estado <> 'CERRADA'
  then

    if new.resultado is null then
      raise exception
        'La visita no puede cerrarse sin resultado'
        using errcode = 'P0001';
    end if;


    -- VENTA: pedido obligatorio.
    if new.resultado = 'VENTA' then

      if new.order_id is null then
        raise exception
          'VENTA requiere un pedido asociado'
          using errcode = 'P0001';
      end if;

      if not exists (
        select 1
        from public.orders o
        where o.id = new.order_id
          and o.client_id = new.client_id
      ) then
        raise exception
          'El pedido asociado no pertenece al cliente de la visita'
          using errcode = 'P0001';
      end if;

    end if;


    -- RESUELTO: debe explicar qué se resolvió.
    if new.resultado = 'RESUELTO'
       and nullif(trim(new.detalle_cierre), '') is null
    then
      raise exception
        'RESUELTO requiere detalle de la solucion'
        using errcode = 'P0001';
    end if;


    -- REPROGRAMADO: fecha futura obligatoria.
    if new.resultado = 'REPROGRAMADO' then

      if new.proxima_fecha is null then
        raise exception
          'REPROGRAMADO requiere nueva fecha'
          using errcode = 'P0001';
      end if;

      if new.proxima_fecha <= new.fecha_programada then
        raise exception
          'La nueva visita debe tener una fecha posterior'
          using errcode = 'P0001';
      end if;

      if nullif(trim(new.detalle_cierre), '') is null then
        raise exception
          'REPROGRAMADO requiere motivo'
          using errcode = 'P0001';
      end if;

    end if;


    -- SEGUIMIENTO: próxima acción + fecha.
    if new.resultado = 'SEGUIMIENTO' then

      if new.proxima_fecha is null
         or nullif(trim(new.proxima_accion), '') is null
         or nullif(trim(new.detalle_cierre), '') is null
      then
        raise exception
          'SEGUIMIENTO requiere detalle, proxima accion y fecha'
          using errcode = 'P0001';
      end if;

      if new.proxima_fecha <= new.fecha_programada then
        raise exception
          'La fecha de seguimiento debe ser posterior'
          using errcode = 'P0001';
      end if;

    end if;


    -- DERIVADO: genera posteriormente una incidencia Comercial.
    if new.resultado = 'DERIVADO_COMERCIAL' then

      if nullif(trim(new.detalle_cierre), '') is null then
        raise exception
          'DERIVADO_COMERCIAL requiere detalle del problema'
          using errcode = 'P0001';
      end if;

      new.requiere_incidencia_comercial := true;

    else

      new.requiere_incidencia_comercial := false;

    end if;


    new.cerrado_at := coalesce(new.cerrado_at, now());

  end if;

  return new;
end;
$$;

create trigger trg_validate_supervisor_visit_close
before update
on public.supervisor_visits
for each row
execute function public.validate_supervisor_visit_close();


-- ============================================================
-- CREAR AUTOMATICAMENTE LA CONTINUIDAD
-- ============================================================

create or replace function public.create_supervisor_visit_followup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

  if new.estado = 'CERRADA'
     and old.estado <> 'CERRADA'
  then

    if new.resultado = 'REPROGRAMADO' then

      insert into public.supervisor_visits (
        supervisor_id,
        client_id,
        fecha_programada,
        origen,
        parent_visit_id,
        objetivo,
        estado,
        creado_por
      )
      values (
        new.supervisor_id,
        new.client_id,
        new.proxima_fecha,
        'REPROGRAMACION',
        new.id,
        'Continuidad de visita reprogramada: ' ||
          coalesce(new.detalle_cierre, ''),
        'PENDIENTE',
        new.supervisor_id
      );

    elsif new.resultado = 'SEGUIMIENTO' then

      insert into public.supervisor_visits (
        supervisor_id,
        client_id,
        fecha_programada,
        origen,
        parent_visit_id,
        objetivo,
        estado,
        creado_por
      )
      values (
        new.supervisor_id,
        new.client_id,
        new.proxima_fecha,
        'SEGUIMIENTO',
        new.id,
        new.proxima_accion,
        'PENDIENTE',
        new.supervisor_id
      );

    end if;

  end if;

  return new;
end;
$$;

create trigger trg_create_supervisor_visit_followup
after update
on public.supervisor_visits
for each row
execute function public.create_supervisor_visit_followup();


-- ============================================================
-- PROTEGER HISTORIAL
-- ============================================================

create or replace function public.protect_closed_supervisor_visit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

  if old.estado = 'CERRADA' then
    raise exception
      'Una visita cerrada forma parte del historial y no puede modificarse'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create trigger trg_protect_closed_supervisor_visit
before update
on public.supervisor_visits
for each row
when (old.estado = 'CERRADA')
execute function public.protect_closed_supervisor_visit();


-- No se borran visitas.
create or replace function public.prevent_supervisor_visit_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  raise exception
    'Las visitas forman parte del historial y no pueden eliminarse'
    using errcode = 'P0001';
end;
$$;

create trigger trg_prevent_supervisor_visit_delete
before delete
on public.supervisor_visits
for each row
execute function public.prevent_supervisor_visit_delete();


-- ============================================================
-- RLS
-- ============================================================

alter table public.supervisor_visits enable row level security;

revoke all
on table public.supervisor_visits
from public, anon;

grant select, insert, update
on table public.supervisor_visits
to authenticated;


-- ADMIN
create policy supervisor_visits_admin_all
on public.supervisor_visits
for all to authenticated
using (public.is_admin())
with check (public.is_admin());


-- SUPERVISOR: ve sus propias visitas.
create policy supervisor_visits_supervisor_select
on public.supervisor_visits
for select to authenticated
using (
  supervisor_id = auth.uid()
);


-- SUPERVISOR: puede crear visitas para sí mismo.
create policy supervisor_visits_supervisor_insert
on public.supervisor_visits
for insert to authenticated
with check (
  supervisor_id = auth.uid()
  and creado_por = auth.uid()
  and origen = 'SUPERVISOR'
);


-- SUPERVISOR: puede trabajar sus visitas mientras no estén cerradas.
create policy supervisor_visits_supervisor_update
on public.supervisor_visits
for update to authenticated
using (
  supervisor_id = auth.uid()
  and estado <> 'CERRADA'
)
with check (
  supervisor_id = auth.uid()
);


-- COMERCIAL: ve visitas de Supervisores de su estructura.
create policy supervisor_visits_commercial_select
on public.supervisor_visits
for select to authenticated
using (
  public.is_effective_commercial_of_supervisor(
    auth.uid(),
    supervisor_id,
    fecha_programada::timestamptz + interval '12 hours'
  )
);


-- COMERCIAL: crea visitas para sus Supervisores.
create policy supervisor_visits_commercial_insert
on public.supervisor_visits
for insert to authenticated
with check (
  creado_por = auth.uid()
  and origen = 'COMERCIAL'
  and public.is_effective_commercial_of_supervisor(
    auth.uid(),
    supervisor_id,
    fecha_programada::timestamptz + interval '12 hours'
  )
);