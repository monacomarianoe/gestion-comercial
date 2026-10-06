-- ============================================================
-- ETAPA 6D.2
-- ARMADO FORMAL Y BLOQUEO DE PLANILLA
-- ============================================================

-- ------------------------------------------------------------
-- BORRADOR -> ARMADA
-- Monitor responsable o Admin.
-- Requiere:
--   - Repartidor
--   - Vehículo
--   - Al menos un pedido
-- Registra armada_at.
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
    raise exception 'Solo el Monitor responsable puede armar esta planilla';
  end if;

  if v_sheet.estado <> 'BORRADOR' then
    raise exception 'Solo puede armarse una planilla en estado BORRADOR';
  end if;

  if v_sheet.repartidor_id is null then
    raise exception 'La planilla debe tener un Repartidor asignado';
  end if;

  if v_sheet.vehicle_id is null then
    raise exception 'La planilla debe tener un vehiculo asignado';
  end if;

  if not exists (
    select 1
    from public.delivery_sheet_orders dso
    where dso.delivery_sheet_id = p_delivery_sheet_id
  ) then
    raise exception 'La planilla debe contener al menos un pedido';
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


-- ------------------------------------------------------------
-- CORRECCIÓN RPC AGREGAR PEDIDO
--
-- A partir de ahora SOLO se agregan pedidos mientras
-- la planilla está en BORRADOR.
-- ARMADA significa contenido y orden de ruta cerrados.
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
    raise exception 'Solo el Monitor responsable puede modificar esta planilla';
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
  ) then
    raise exception 'El pedido ya pertenece a una planilla';
  end if;

  if exists (
    select 1
    from public.delivery_sheet_orders
    where delivery_sheet_id = p_delivery_sheet_id
      and orden_ruta = p_orden_ruta
  ) then
    raise exception 'La posicion de ruta ya esta ocupada';
  end if;

  v_note_number := nextval('public.delivery_note_number_seq');

  insert into public.delivery_sheet_orders (
    delivery_sheet_id,
    order_id,
    numero_remito,
    orden_ruta
  )
  values (
    p_delivery_sheet_id,
    p_order_id,
    lpad(v_note_number::text, 8, '0'),
    p_orden_ruta
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
-- BLOQUEAR CAMBIOS ESTRUCTURALES DESDE ARMADA
--
-- Una vez ARMADA:
-- - no cambia Repartidor
-- - no cambia vehículo
--
-- Excepción:
-- el propio cambio BORRADOR -> ARMADA conserva los datos.
-- ------------------------------------------------------------

create or replace function public.protect_delivery_sheet_structure()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if old.estado in (
    'ARMADA',
    'ASIGNADA',
    'ACEPTADA',
    'EN_REPARTO',
    'CERRADA'
  ) then

    if new.repartidor_id is distinct from old.repartidor_id then
      raise exception
        'No puede cambiarse el Repartidor de una planilla ya armada';
    end if;

    if new.vehicle_id is distinct from old.vehicle_id then
      raise exception
        'No puede cambiarse el vehiculo de una planilla ya armada';
    end if;

  end if;

  return new;
end;
$$;


-- El trigger anterior protegía desde ACEPTADA.
-- Lo reemplazamos por la protección más estricta desde ARMADA.

drop trigger if exists trg_protect_accepted_delivery_sheet
on public.delivery_sheets;

drop trigger if exists trg_protect_delivery_sheet_structure
on public.delivery_sheets;

create trigger trg_protect_delivery_sheet_structure
before update
on public.delivery_sheets
for each row
execute function public.protect_delivery_sheet_structure();


-- ------------------------------------------------------------
-- PERMISOS
-- ------------------------------------------------------------

revoke all
on function public.finalize_delivery_sheet(bigint)
from public;

revoke all
on function public.finalize_delivery_sheet(bigint)
from anon;

grant execute
on function public.finalize_delivery_sheet(bigint)
to authenticated;