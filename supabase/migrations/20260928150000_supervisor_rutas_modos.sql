-- ============================================================
-- ETAPA 5 - SUPERVISOR
-- Bloque 3: rutas diarias y modos de supervision
-- ============================================================

create type public.supervisor_work_mode as enum (
  'EN_COMPANIA',
  'MODO_SUPERVISION'
);

create type public.client_criticality as enum (
  'PRIORIDAD',
  'URGENCIA',
  'ACCION'
);


-- ============================================================
-- RUTA DIARIA DEL VENDEDOR
-- ============================================================

create table public.seller_daily_routes (
  id bigint generated always as identity primary key,

  seller_id uuid not null
    references public.profiles(id),

  zone_id bigint not null
    references public.zones(id),

  fecha date not null,

  creado_por uuid not null
    references public.profiles(id),

  created_at timestamptz not null default now(),

  unique (seller_id, fecha)
);


-- ============================================================
-- JORNADA / ASIGNACION DEL SUPERVISOR
-- ============================================================

create table public.supervisor_workdays (
  id bigint generated always as identity primary key,

  supervisor_id uuid not null
    references public.profiles(id),

  fecha date not null,

  modo public.supervisor_work_mode not null,

  -- Solo EN_COMPANIA:
  accompanied_seller_id uuid
    references public.profiles(id),

  creado_por uuid not null
    references public.profiles(id),

  created_at timestamptz not null default now(),

  unique (supervisor_id, fecha),

  constraint supervisor_workday_mode_check
  check (
    (
      modo = 'EN_COMPANIA'
      and accompanied_seller_id is not null
    )
    or
    (
      modo = 'MODO_SUPERVISION'
      and accompanied_seller_id is null
    )
  )
);


-- ============================================================
-- ZONAS PARA MODO SUPERVISION
-- Puede haber mas de una.
-- ============================================================

create table public.supervisor_workday_zones (
  workday_id bigint not null
    references public.supervisor_workdays(id),

  zone_id bigint not null
    references public.zones(id),

  primary key (workday_id, zone_id)
);


-- ============================================================
-- CRITICIDADES PARA MODO SUPERVISION
-- Puede haber mas de una.
-- ============================================================

create table public.supervisor_workday_criticalities (
  workday_id bigint not null
    references public.supervisor_workdays(id),

  criticidad public.client_criticality not null,

  primary key (workday_id, criticidad)
);


-- ============================================================
-- VALIDACION DE RUTA DIARIA
-- ============================================================

create or replace function public.validate_seller_daily_route()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role public.app_role;
  v_active boolean;
begin

  select rol, activo
  into v_role, v_active
  from public.profiles
  where id = new.seller_id;

  if v_role <> 'VENDEDOR' or v_active is not true then
    raise exception
      'La ruta diaria solo puede asignarse a un vendedor activo'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create trigger trg_validate_seller_daily_route
before insert or update
on public.seller_daily_routes
for each row
execute function public.validate_seller_daily_route();


-- ============================================================
-- VALIDACION DE JORNADA DEL SUPERVISOR
-- ============================================================

create or replace function public.validate_supervisor_workday()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_supervisor_role public.app_role;
  v_supervisor_active boolean;
  v_seller_role public.app_role;
  v_seller_active boolean;
begin

  select rol, activo
  into v_supervisor_role, v_supervisor_active
  from public.profiles
  where id = new.supervisor_id;

  if v_supervisor_role <> 'SUPERVISOR'
     or v_supervisor_active is not true then
    raise exception
      'La jornada solo puede asignarse a un supervisor activo'
      using errcode = 'P0001';
  end if;


  if new.modo = 'EN_COMPANIA' then

    select rol, activo
    into v_seller_role, v_seller_active
    from public.profiles
    where id = new.accompanied_seller_id;

    if v_seller_role <> 'VENDEDOR'
       or v_seller_active is not true then
      raise exception
        'EN_COMPANIA requiere un vendedor activo'
        using errcode = 'P0001';
    end if;

    if not public.is_effective_supervisor_of_seller(
      new.supervisor_id,
      new.accompanied_seller_id,
      new.fecha::timestamptz + interval '12 hours'
    ) then
      raise exception
        'El vendedor no pertenece a la estructura efectiva del supervisor'
        using errcode = 'P0001';
    end if;

  end if;

  return new;
end;
$$;

create trigger trg_validate_supervisor_workday
before insert or update
on public.supervisor_workdays
for each row
execute function public.validate_supervisor_workday();


-- ============================================================
-- RLS
-- ============================================================

alter table public.seller_daily_routes enable row level security;
alter table public.supervisor_workdays enable row level security;
alter table public.supervisor_workday_zones enable row level security;
alter table public.supervisor_workday_criticalities enable row level security;

revoke all on table
  public.seller_daily_routes,
  public.supervisor_workdays,
  public.supervisor_workday_zones,
  public.supervisor_workday_criticalities
from public, anon;

grant select, insert, update on table
  public.seller_daily_routes,
  public.supervisor_workdays,
  public.supervisor_workday_zones,
  public.supervisor_workday_criticalities
to authenticated;


-- ADMIN acceso completo.

create policy seller_daily_routes_admin_all
on public.seller_daily_routes
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy supervisor_workdays_admin_all
on public.supervisor_workdays
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy supervisor_workday_zones_admin_all
on public.supervisor_workday_zones
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy supervisor_workday_criticalities_admin_all
on public.supervisor_workday_criticalities
for all to authenticated
using (public.is_admin())
with check (public.is_admin());


-- SUPERVISOR puede consultar su propia jornada y ruta asignada.

create policy supervisor_workdays_own_select
on public.supervisor_workdays
for select to authenticated
using (
  supervisor_id = auth.uid()
);

create policy supervisor_workday_zones_own_select
on public.supervisor_workday_zones
for select to authenticated
using (
  exists (
    select 1
    from public.supervisor_workdays sw
    where sw.id = supervisor_workday_zones.workday_id
      and sw.supervisor_id = auth.uid()
  )
);

create policy supervisor_workday_criticalities_own_select
on public.supervisor_workday_criticalities
for select to authenticated
using (
  exists (
    select 1
    from public.supervisor_workdays sw
    where sw.id = supervisor_workday_criticalities.workday_id
      and sw.supervisor_id = auth.uid()
  )
);


-- El vendedor puede consultar su propia ruta diaria.

create policy seller_daily_routes_seller_select
on public.seller_daily_routes
for select to authenticated
using (
  seller_id = auth.uid()
);