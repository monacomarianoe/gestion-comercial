-- ============================================================
-- ETAPA 6C
-- PEDIDO -> PLANILLA -> ATENDIDO
-- REMITO CORRELATIVO AUTOMATICO
-- ============================================================

-- Secuencia global de remitos.
-- PostgreSQL garantiza que dos operaciones concurrentes
-- no reciban el mismo número.
create sequence public.delivery_note_number_seq
  start with 1
  increment by 1
  minvalue 1
  no cycle;

-- ------------------------------------------------------------
-- Funcion controlada para incorporar un pedido a una planilla
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
  v_remito bigint;
begin

  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  if p_orden_ruta is null or p_orden_ruta <= 0 then
    raise exception 'El orden de ruta debe ser mayor a cero';
  end if;

  -- Bloqueamos la planilla mientras se realiza la operación.
  select *
    into v_sheet
  from public.delivery_sheets
  where id = p_delivery_sheet_id
  for update;

  if not found then
    raise exception 'La planilla no existe';
  end if;

  -- Solo Admin o el Monitor propietario pueden incorporar pedidos.
  if not public.is_admin()
     and v_sheet.monitor_id <> auth.uid() then
    raise exception 'No tiene permiso para operar esta planilla';
  end if;

  if v_sheet.estado not in ('BORRADOR', 'ARMADA') then
    raise exception
      'No pueden agregarse pedidos a una planilla en estado %',
      v_sheet.estado;
  end if;

  -- Bloqueamos también el pedido.
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

  -- Protección explícita adicional al UNIQUE(order_id).
  if exists (
    select 1
    from public.delivery_sheet_orders
    where order_id = p_order_id
  ) then
    raise exception 'El pedido ya pertenece a una planilla';
  end if;

  -- No puede repetirse una posición dentro de la misma ruta.
  if exists (
    select 1
    from public.delivery_sheet_orders
    where delivery_sheet_id = p_delivery_sheet_id
      and orden_ruta = p_orden_ruta
  ) then
    raise exception 'El orden de ruta ya está ocupado';
  end if;

  -- El número se obtiene exclusivamente de la secuencia.
  v_remito := nextval('public.delivery_note_number_seq');

  insert into public.delivery_sheet_orders (
    delivery_sheet_id,
    order_id,
    numero_remito,
    orden_ruta
  )
  values (
    p_delivery_sheet_id,
    p_order_id,
    lpad(v_remito::text, 8, '0'),
    p_orden_ruta
  )
  returning *
  into v_result;

  -- Pedido y hoja quedan vinculados dentro de la misma transacción.
  update public.orders
  set estado = 'ATENDIDO',
      updated_at = now()
  where id = p_order_id;

  return v_result;
end;
$$;

revoke all
on function public.add_order_to_delivery_sheet(bigint, bigint, integer)
from public;

revoke all
on function public.add_order_to_delivery_sheet(bigint, bigint, integer)
from anon;

grant execute
on function public.add_order_to_delivery_sheet(bigint, bigint, integer)
to authenticated;