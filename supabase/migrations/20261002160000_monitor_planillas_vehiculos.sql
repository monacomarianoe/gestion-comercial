-- ============================================================
-- ETAPA 6A
-- MONITOR / PLANILLAS / VEHICULOS
-- ============================================================

-- ------------------------------------------------------------
-- Estados
-- ------------------------------------------------------------

create type public.delivery_sheet_status as enum (
  'BORRADOR',
  'ARMADA',
  'ASIGNADA',
  'EN_REPARTO',
  'CERRADA',
  'CANCELADA'
);

-- ------------------------------------------------------------
-- VEHICULOS
-- ------------------------------------------------------------

create table public.vehicles (
  id bigint generated always as identity primary key,
  patente text not null,
  descripcion text,
  activo boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint vehicles_patente_not_empty
    check (btrim(patente) <> '')
);

create unique index vehicles_patente_unique
  on public.vehicles (upper(btrim(patente)));

-- ------------------------------------------------------------
-- PLANILLAS DE REPARTO
-- Una planilla representa una salida física.
-- ------------------------------------------------------------

create table public.delivery_sheets (
  id bigint generated always as identity primary key,

  fecha date not null default current_date,

  monitor_id uuid not null
    references public.profiles(id),

  repartidor_id uuid
    references public.profiles(id),

  vehicle_id bigint
    references public.vehicles(id),

  estado public.delivery_sheet_status
    not null default 'BORRADOR',

  numero_salida integer not null default 1,

  observaciones text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  armada_at timestamptz,
  asignada_at timestamptz,
  inicio_reparto_at timestamptz,
  cerrada_at timestamptz,

  constraint delivery_sheets_numero_salida_positive
    check (numero_salida > 0),

  constraint delivery_sheets_assignment_consistency
    check (
      estado = 'BORRADOR'
      or (
        repartidor_id is not null
        and vehicle_id is not null
      )
    ),

  constraint delivery_sheets_closed_consistency
    check (
      estado <> 'CERRADA'
      or cerrada_at is not null
    )
);

-- Un repartidor puede tener varias salidas por día.
-- numero_salida diferencia esas operaciones.
create unique index delivery_sheets_repartidor_salida_unique
  on public.delivery_sheets (
    fecha,
    repartidor_id,
    numero_salida
  )
  where repartidor_id is not null;

-- ------------------------------------------------------------
-- PEDIDOS INCLUIDOS EN PLANILLA
-- Cada pedido/remito puede pertenecer a una sola planilla.
-- ------------------------------------------------------------

create table public.delivery_sheet_orders (
  id bigint generated always as identity primary key,

  delivery_sheet_id bigint not null
    references public.delivery_sheets(id),

  order_id bigint not null
    references public.orders(id),

  numero_remito text not null,

  orden_ruta integer not null,

  created_at timestamptz not null default now(),

  constraint delivery_sheet_orders_order_unique
    unique (order_id),

  constraint delivery_sheet_orders_remito_unique
    unique (numero_remito),

  constraint delivery_sheet_orders_route_order_positive
    check (orden_ruta > 0),

  constraint delivery_sheet_orders_sheet_route_unique
    unique (delivery_sheet_id, orden_ruta)
);

-- ------------------------------------------------------------
-- VALIDACIONES DE ROLES
-- ------------------------------------------------------------

create or replace function public.validate_delivery_sheet()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_monitor_role public.app_role;
  v_repartidor_role public.app_role;
begin

  select rol
    into v_monitor_role
  from public.profiles
  where id = new.monitor_id
    and activo = true;

  if v_monitor_role is distinct from 'MONITOR' then
    raise exception 'El responsable de la planilla debe ser un Monitor activo';
  end if;

  if new.repartidor_id is not null then

    select rol
      into v_repartidor_role
    from public.profiles
    where id = new.repartidor_id
      and activo = true;

    if v_repartidor_role is distinct from 'REPARTIDOR' then
      raise exception 'El repartidor asignado debe ser un Repartidor activo';
    end if;

    if not exists (
      select 1
      from public.user_assignments ua
      where ua.superior_id = new.monitor_id
        and ua.subordinado_id = new.repartidor_id
        and ua.desde <= new.fecha::timestamptz
        and (
          ua.hasta is null
          or ua.hasta >= new.fecha::timestamptz
        )
    ) then
      raise exception 'El Repartidor no pertenece a la estructura del Monitor';
    end if;

  end if;

  return new;
end;
$$;

create trigger trg_validate_delivery_sheet
before insert or update
on public.delivery_sheets
for each row
execute function public.validate_delivery_sheet();

-- ------------------------------------------------------------
-- VALIDAR PEDIDO AL INCORPORARLO
-- ------------------------------------------------------------

create or replace function public.validate_delivery_sheet_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_estado public.order_status;
begin

  select estado
    into v_estado
  from public.orders
  where id = new.order_id;

  if v_estado is null then
    raise exception 'El pedido no existe';
  end if;

  if v_estado not in ('PENDIENTE', 'GUARDADO') then
    raise exception
      'Solo pueden incorporarse a una planilla pedidos PENDIENTE o GUARDADO';
  end if;

  return new;
end;
$$;

create trigger trg_validate_delivery_sheet_order
before insert
on public.delivery_sheet_orders
for each row
execute function public.validate_delivery_sheet_order();

-- ------------------------------------------------------------
-- PERMISOS BASE
-- RLS específico se completa en 6B.
-- ------------------------------------------------------------

alter table public.vehicles enable row level security;
alter table public.delivery_sheets enable row level security;
alter table public.delivery_sheet_orders enable row level security;

grant select on public.vehicles to authenticated;
grant select, insert, update on public.delivery_sheets to authenticated;
grant select, insert on public.delivery_sheet_orders to authenticated;

grant usage, select on sequence public.vehicles_id_seq to authenticated;
grant usage, select on sequence public.delivery_sheets_id_seq to authenticated;
grant usage, select on sequence public.delivery_sheet_orders_id_seq to authenticated;