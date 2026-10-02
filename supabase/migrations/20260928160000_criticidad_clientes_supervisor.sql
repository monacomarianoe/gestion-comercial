-- ============================================================
-- ETAPA 5 - SUPERVISOR
-- Bloque 4: criticidad automatica de clientes
-- y cartera dinamica para MODO_SUPERVISION
-- ============================================================


-- ============================================================
-- NUEVA CRITICIDAD: SIN_COMPRA
-- ============================================================

alter type public.client_criticality
add value if not exists 'SIN_COMPRA';


-- ============================================================
-- ULTIMA COMPRA REAL DEL CLIENTE
--
-- Compra real = ultimo pedido ENTREGADO.
-- Un pedido pendiente, alerta, guardado, atendido o rechazado
-- NO reinicia la antiguedad del cliente.
-- ============================================================

create or replace function public.client_last_purchase(
  p_client_id bigint
)
returns timestamptz
language sql
stable
security definer
set search_path = public
as $$
  select max(o.entregado_at)
  from public.orders o
  where o.client_id = p_client_id
    and o.estado = 'ENTREGADO'
    and o.entregado_at is not null;
$$;


-- ============================================================
-- DIAS DESDE ULTIMA COMPRA
--
-- NULL = nunca compro.
-- ============================================================

create or replace function public.client_days_without_purchase(
  p_client_id bigint,
  p_fecha date default current_date
)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select
    case
      when public.client_last_purchase(p_client_id) is null
        then null
      else greatest(
        0,
        p_fecha - public.client_last_purchase(p_client_id)::date
      )
    end;
$$;


-- ============================================================
-- CLASIFICACION ACTUAL DEL CLIENTE
--
-- Siempre devuelve UNA sola condicion:
--
-- SIN_COMPRA = nunca tuvo pedido ENTREGADO
-- NULL       = 0 a 14 dias (NORMAL)
-- PRIORIDAD  = 15 a 29 dias
-- URGENCIA   = 30 a 44 dias
-- ACCION     = 45 dias o mas
--
-- NULL representa NORMAL porque NORMAL no forma parte
-- de las criticidades seleccionables por Comercial.
-- ============================================================

create or replace function public.client_current_criticality(
  p_client_id bigint,
  p_fecha date default current_date
)
returns public.client_criticality
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days integer;
begin

  v_days := public.client_days_without_purchase(
    p_client_id,
    p_fecha
  );

  if v_days is null then
    return 'SIN_COMPRA'::public.client_criticality;
  end if;

  if v_days >= 45 then
    return 'ACCION'::public.client_criticality;
  end if;

  if v_days >= 30 then
    return 'URGENCIA'::public.client_criticality;
  end if;

  if v_days >= 15 then
    return 'PRIORIDAD'::public.client_criticality;
  end if;

  return null;
end;
$$;


-- ============================================================
-- CLIENTES ASIGNADOS AL SUPERVISOR EN MODO SUPERVISION
--
-- La cartera NO se guarda.
-- Se calcula en tiempo real usando:
--   - jornada del supervisor
--   - zonas seleccionadas
--   - criticidades seleccionadas
--   - ultima compra ENTREGADA de cada cliente
--
-- Si cambia la antiguedad del cliente, cambia automaticamente
-- su clasificacion.
-- ============================================================

create or replace function public.supervisor_critical_clients(
  p_supervisor_id uuid,
  p_fecha date default current_date
)
returns table (
  client_id bigint,
  cod text,
  nombre text,
  zone_id bigint,
  fecha_ultima_compra timestamptz,
  dias_sin_compra integer,
  criticidad public.client_criticality
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id::bigint,
    c.cod,
    c.nombre,
    c.zone_id::bigint,
    public.client_last_purchase(c.id) as fecha_ultima_compra,
    public.client_days_without_purchase(
      c.id,
      p_fecha
    ) as dias_sin_compra,
    public.client_current_criticality(
      c.id,
      p_fecha
    ) as criticidad

  from public.clients c

  join public.supervisor_workdays sw
    on sw.supervisor_id = p_supervisor_id
   and sw.fecha = p_fecha
   and sw.modo = 'MODO_SUPERVISION'

  join public.supervisor_workday_zones swz
    on swz.workday_id = sw.id
   and swz.zone_id = c.zone_id

  join public.supervisor_workday_criticalities swc
    on swc.workday_id = sw.id
   and swc.criticidad =
       public.client_current_criticality(c.id, p_fecha)

  where c.estado = 'ACTIVO';
$$;


-- ============================================================
-- SINCRONIZAR clients.fecha_ultima_compra
--
-- Cuando un pedido pasa a ENTREGADO, actualizamos el campo
-- informativo del cliente con la fecha real de entrega.
--
-- La clasificacion sigue calculandose desde orders,
-- por lo que este campo NO es la fuente de verdad.
-- ============================================================

create or replace function public.sync_client_last_purchase()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin

  if new.estado = 'ENTREGADO'
     and new.entregado_at is not null
     and (
       old.estado is distinct from new.estado
       or old.entregado_at is distinct from new.entregado_at
     )
  then

    update public.clients
    set
      fecha_ultima_compra = new.entregado_at::date,
      updated_at = now()
    where id = new.client_id
      and (
        fecha_ultima_compra is null
        or fecha_ultima_compra < new.entregado_at::date
      );

  end if;

  return new;
end;
$$;

create trigger trg_sync_client_last_purchase
after update
on public.orders
for each row
execute function public.sync_client_last_purchase();


-- ============================================================
-- PERMISOS DE FUNCIONES
-- ============================================================

revoke all
on function public.client_last_purchase(bigint)
from public, anon;

revoke all
on function public.client_days_without_purchase(bigint, date)
from public, anon;

revoke all
on function public.client_current_criticality(bigint, date)
from public, anon;

revoke all
on function public.supervisor_critical_clients(uuid, date)
from public, anon;


grant execute
on function public.client_last_purchase(bigint)
to authenticated;

grant execute
on function public.client_days_without_purchase(bigint, date)
to authenticated;

grant execute
on function public.client_current_criticality(bigint, date)
to authenticated;

grant execute
on function public.supervisor_critical_clients(uuid, date)
to authenticated;