-- ============================================================
-- ETAPA 6E.2
-- HISTORIAL PEDIDO <-> PLANILLA
--
-- Un pedido puede salir de la operación sin perder:
-- - planilla histórica
-- - número de remito
-- - orden de ruta
-- - fecha
-- - motivo
--
-- Solo una relación ACTIVA representa pertenencia operativa.
-- ============================================================


-- ------------------------------------------------------------
-- 1. AGREGAR ESTADO OPERATIVO A LA RELACIÓN
-- ------------------------------------------------------------

alter table public.delivery_sheet_orders
add column activo boolean not null default true;

alter table public.delivery_sheet_orders
add column retirado_at timestamptz;

alter table public.delivery_sheet_orders
add column retirado_por uuid
references public.profiles(id);

alter table public.delivery_sheet_orders
add column motivo_retiro text;

alter table public.delivery_sheet_orders
add column incident_id bigint
references public.incidents(id);


-- ------------------------------------------------------------
-- 2. COHERENCIA DEL RETIRO
-- ------------------------------------------------------------

alter table public.delivery_sheet_orders
add constraint delivery_sheet_orders_retiro_coherente
check (
  (
    activo = true
    and retirado_at is null
    and retirado_por is null
    and motivo_retiro is null
  )
  or
  (
    activo = false
    and retirado_at is not null
    and retirado_por is not null
    and motivo_retiro is not null
    and length(trim(motivo_retiro)) > 0
  )
);


-- ------------------------------------------------------------
-- 3. CAMBIAR UNICIDAD DEL PEDIDO
--
-- Antes:
--   un pedido podía aparecer una sola vez para siempre.
--
-- Ahora:
--   puede tener historial en planillas anteriores,
--   pero solo UNA relación operativa activa.
-- ------------------------------------------------------------

alter table public.delivery_sheet_orders
drop constraint if exists delivery_sheet_orders_order_id_key;

drop index if exists delivery_sheet_orders_order_id_key;

create unique index delivery_sheet_orders_one_active_order
on public.delivery_sheet_orders(order_id)
where activo = true;


-- ------------------------------------------------------------
-- 4. REMITO HISTÓRICO SIGUE SIENDO ÚNICO
--
-- NO quitamos la unicidad de numero_remito.
-- Un remito usado nunca se reutiliza.
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- 5. ACTUALIZAR VALIDACIÓN DE INSERCIÓN
--
-- Solo impide que el pedido tenga otra relación ACTIVA.
-- Las relaciones históricas retiradas no impiden que el pedido
-- vuelva posteriormente a otra planilla.
-- ------------------------------------------------------------

create or replace function public.validate_delivery_sheet_order()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_order_status public.order_status;
begin

  select estado
  into v_order_status
  from public.orders
  where id = new.order_id;

  if not found then
    raise exception 'El pedido no existe';
  end if;

  if v_order_status not in ('PENDIENTE', 'GUARDADO') then
    raise exception
      'Solo pueden incorporarse pedidos PENDIENTE o GUARDADO';
  end if;

  if exists (
    select 1
    from public.delivery_sheet_orders dso
    where dso.order_id = new.order_id
      and dso.activo = true
  ) then
    raise exception
      'El pedido ya pertenece a una planilla activa';
  end if;

  return new;
end;
$$;


-- ------------------------------------------------------------
-- 6. CORREGIR RPC DE INCORPORACIÓN
--
-- La comprobación de pertenencia considera solamente
-- relaciones activas.
-- ------------------------------------------------------------

create or replace function public.add_order_to_delivery_sheet(
  p_delivery_sheet_id bigint,
  p_order_id bigint,
  p_orden_ruta integer
)
returns public.delivery_sheet_orders
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sheet public.delivery_sheets%rowtype;
  v_order public.orders%rowtype;
  v_result public.delivery_sheet_orders%rowtype;
  v_note_number bigint;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  if p_orden_ruta is null or p_orden_ruta <= 0 then
    raise exception 'El orden de ruta debe ser mayor a cero';
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
      'Solo el Monitor responsable puede modificar esta planilla';
  end if;

  if v_sheet.estado <> 'BORRADOR' then
    raise exception
      'Solo pueden agregarse pedidos a una planilla en estado BORRADOR';
  end if;

  select *
  into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'El pedido no existe';
  end if;

  if v_order.estado not in ('PENDIENTE', 'GUARDADO') then
    raise exception
      'Solo pueden incorporarse pedidos PENDIENTE o GUARDADO';
  end if;

  if exists (
    select 1
    from public.delivery_sheet_orders
    where order_id = p_order_id
      and activo = true
  ) then
    raise exception
      'El pedido ya pertenece a una planilla activa';
  end if;

  if exists (
    select 1
    from public.delivery_sheet_orders
    where delivery_sheet_id = p_delivery_sheet_id
      and orden_ruta = p_orden_ruta
      and activo = true
  ) then
    raise exception
      'La posicion de ruta ya esta ocupada';
  end if;

  v_note_number := nextval('public.delivery_note_number_seq');

  insert into public.delivery_sheet_orders (
    delivery_sheet_id,
    order_id,
    numero_remito,
    orden_ruta,
    activo
  )
  values (
    p_delivery_sheet_id,
    p_order_id,
    lpad(v_note_number::text, 8, '0'),
    p_orden_ruta,
    true
  )
  returning *
  into v_result;

  update public.orders
  set estado = 'ATENDIDO',
      updated_at = now()
  where id = p_order_id;

  return v_result;
end;
$$;


-- ------------------------------------------------------------
-- 7. SOLO LAS RELACIONES ACTIVAS CUENTAN PARA ARMAR PLANILLA
-- ------------------------------------------------------------

create or replace function public.finalize_delivery_sheet(
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
      'Solo el Monitor responsable puede armar esta planilla';
  end if;

  if v_sheet.estado <> 'BORRADOR' then
    raise exception
      'Solo puede armarse una planilla en estado BORRADOR';
  end if;

  if v_sheet.repartidor_id is null then
    raise exception
      'La planilla debe tener un Repartidor asignado';
  end if;

  if v_sheet.vehicle_id is null then
    raise exception
      'La planilla debe tener un vehiculo asignado';
  end if;

  if not exists (
    select 1
    from public.delivery_sheet_orders dso
    where dso.delivery_sheet_id = p_delivery_sheet_id
      and dso.activo = true
  ) then
    raise exception
      'La planilla debe contener al menos un pedido activo';
  end if;

  update public.delivery_sheets
  set estado = 'ARMADA',
      armada_at = now(),
      updated_at = now()
  where id = p_delivery_sheet_id
  returning *
  into v_sheet;

  return v_sheet;
end;
$$;