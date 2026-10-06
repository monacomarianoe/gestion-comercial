-- ============================================================
-- ETAPA 6 - ASEGURAR REMITO PERMANENTE POR PEDIDO
-- ============================================================
-- Regla:
-- - El numero de remito pertenece al PEDIDO.
-- - Se genera una sola vez.
-- - Si el pedido sale de una planilla y luego reingresa,
--   conserva exactamente el mismo numero de remito.
-- ============================================================

alter table public.orders
add column if not exists numero_remito text;

-- Recuperar para pedidos históricos el primer remito que tuvieron.
update public.orders o
set numero_remito = x.numero_remito
from (
  select distinct on (dso.order_id)
    dso.order_id,
    dso.numero_remito
  from public.delivery_sheet_orders dso
  where dso.numero_remito is not null
  order by dso.order_id, dso.created_at, dso.id
) x
where o.id = x.order_id
  and o.numero_remito is null;

create unique index if not exists orders_numero_remito_unique
on public.orders(numero_remito)
where numero_remito is not null;

-- El remito del pedido, una vez asignado, no puede cambiar.
create or replace function public.protect_order_delivery_note()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if old.numero_remito is not null
     and new.numero_remito is distinct from old.numero_remito then
    raise exception
      'El numero de remito del pedido es permanente y no puede modificarse';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_protect_order_delivery_note
on public.orders;

create trigger trg_protect_order_delivery_note
before update of numero_remito
on public.orders
for each row
execute function public.protect_order_delivery_note();


-- ------------------------------------------------------------
-- La misma combinación planilla/remito no puede repetirse.
-- El mismo remito SÍ puede aparecer históricamente en otra
-- planilla porque sigue perteneciendo al mismo pedido.
-- ------------------------------------------------------------

drop index if exists public.delivery_sheet_orders_numero_remito_key;
drop index if exists public.delivery_sheet_orders_numero_remito_idx;

alter table public.delivery_sheet_orders
drop constraint if exists delivery_sheet_orders_numero_remito_key;

create unique index if not exists
delivery_sheet_orders_sheet_remito_unique
on public.delivery_sheet_orders(delivery_sheet_id, numero_remito);


-- ------------------------------------------------------------
-- VALIDACIÓN RELACIÓN PEDIDO / PLANILLA
-- ------------------------------------------------------------

create or replace function public.validate_delivery_sheet_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order_note text;
begin
  select numero_remito
  into v_order_note
  from public.orders
  where id = new.order_id;

  if not found then
    raise exception 'El pedido no existe';
  end if;

  if v_order_note is null then
    raise exception 'El pedido todavía no tiene numero de remito asignado';
  end if;

  if new.numero_remito is distinct from v_order_note then
    raise exception
      'El remito de la planilla debe coincidir con el remito permanente del pedido';
  end if;

  return new;
end;
$$;


-- ------------------------------------------------------------
-- INCORPORAR PEDIDO A PLANILLA
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
  v_numero_remito text;
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

  -- Si ya tuvo remito, se reutiliza.
  -- Si nunca tuvo, se genera una única vez.
  v_numero_remito := v_order.numero_remito;

  if v_numero_remito is null then
    v_note_number := nextval('public.delivery_note_number_seq');
    v_numero_remito := lpad(v_note_number::text, 8, '0');

    update public.orders
    set numero_remito = v_numero_remito
    where id = p_order_id;
  end if;

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
    v_numero_remito,
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

revoke all
on function public.add_order_to_delivery_sheet(bigint, bigint, integer)
from public, anon;

grant execute
on function public.add_order_to_delivery_sheet(bigint, bigint, integer)
to authenticated;