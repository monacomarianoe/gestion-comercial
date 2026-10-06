-- ============================================================
-- ETAPA 6E.11
-- BLINDAJE DE INCIDENCIAS POR ESTRUCTURA
-- ============================================================

-- ------------------------------------------------------------
-- 1. ALCANCE REAL SOBRE UNA INCIDENCIA
-- ADMIN: cualquiera.
-- MONITOR: solamente planillas/pedidos de sus repartos.
-- COMERCIAL: solamente pedidos de vendedores de su estructura.
-- DEPOSITO: incidencias del area DEPOSITO.
-- ------------------------------------------------------------

create or replace function public.can_act_on_incident(
  p_incident_id bigint
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
  v_role public.app_role;
begin
  if not public.is_active_user() then
    return false;
  end if;

  if public.is_admin() then
    return true;
  end if;

  select p.rol
  into v_role
  from public.profiles p
  where p.id = auth.uid()
    and p.activo is true;

  select *
  into v_incident
  from public.incidents
  where id = p_incident_id;

  if not found then
    return false;
  end if;

  if v_incident.area_responsable = 'MONITOR'
     and v_role = 'MONITOR' then

    return exists (
      select 1
      from public.delivery_sheets ds
      where ds.id = v_incident.delivery_sheet_id
        and ds.monitor_id = auth.uid()
    )
    or exists (
      select 1
      from public.delivery_sheet_orders dso
      join public.delivery_sheets ds
        on ds.id = dso.delivery_sheet_id
      where dso.order_id = v_incident.order_id
        and ds.monitor_id = auth.uid()
        and (
          v_incident.delivery_sheet_id is null
          or ds.id = v_incident.delivery_sheet_id
        )
    );
  end if;

  if v_incident.area_responsable = 'COMERCIAL'
     and v_role = 'COMERCIAL' then

    return exists (
      select 1
      from public.orders o
      where o.id = v_incident.order_id
        and public.is_effective_commercial_of_seller(
          auth.uid(),
          o.seller_id
        )
    );
  end if;

  if v_incident.area_responsable = 'DEPOSITO'
     and v_role = 'DEPOSITO' then
    return true;
  end if;

  return false;
end;
$$;


-- ------------------------------------------------------------
-- 2. BLINDAR CREACION
-- No se puede inventar area de origen ni apuntar a objetos
-- fuera de la estructura propia.
-- ------------------------------------------------------------

create or replace function public.create_incident(
  p_area_origen public.incident_area,
  p_area_responsable public.incident_area,
  p_tipo text,
  p_detalle text,
  p_order_id bigint default null,
  p_delivery_sheet_id bigint default null
)
returns public.incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_incident public.incidents%rowtype;
  v_role public.app_role;
  v_sheet public.delivery_sheets%rowtype;
  v_order public.orders%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Usuario inactivo o no autenticado';
  end if;

  if p_tipo is null or length(trim(p_tipo)) = 0 then
    raise exception 'Debe indicar el tipo de incidencia';
  end if;

  if p_detalle is null or length(trim(p_detalle)) = 0 then
    raise exception 'Debe indicar el detalle de la incidencia';
  end if;

  if p_order_id is null and p_delivery_sheet_id is null then
    raise exception
      'La incidencia debe estar vinculada a un pedido o planilla';
  end if;

  select p.rol
  into v_role
  from public.profiles p
  where p.id = auth.uid()
    and p.activo is true;

  if p_order_id is not null then
    select *
    into v_order
    from public.orders
    where id = p_order_id;

    if not found then
      raise exception 'El pedido indicado no existe';
    end if;
  end if;

  if p_delivery_sheet_id is not null then
    select *
    into v_sheet
    from public.delivery_sheets
    where id = p_delivery_sheet_id;

    if not found then
      raise exception 'La planilla indicada no existe';
    end if;
  end if;

  -- ADMIN puede crear y derivar entre cualquier area.
  if not public.is_admin() then

    if v_role = 'MONITOR' then
      if p_area_origen <> 'MONITOR' then
        raise exception
          'Un Monitor solo puede crear incidencias desde MONITOR';
      end if;

      if p_area_responsable not in ('MONITOR', 'COMERCIAL', 'ADMIN') then
        raise exception
          'Area responsable no permitida para Monitor';
      end if;

      if p_delivery_sheet_id is not null
         and v_sheet.monitor_id <> auth.uid() then
        raise exception
          'La planilla no pertenece a este Monitor';
      end if;

      if p_order_id is not null
         and not exists (
           select 1
           from public.delivery_sheet_orders dso
           join public.delivery_sheets ds
             on ds.id = dso.delivery_sheet_id
           where dso.order_id = p_order_id
             and ds.monitor_id = auth.uid()
             and (
               p_delivery_sheet_id is null
               or ds.id = p_delivery_sheet_id
             )
         ) then
        raise exception
          'El pedido no pertenece a la estructura de este Monitor';
      end if;

    elsif v_role = 'COMERCIAL' then
      if p_area_origen <> 'COMERCIAL'
         or p_area_responsable not in ('COMERCIAL', 'ADMIN') then
        raise exception
          'Areas no permitidas para Comercial';
      end if;

      if p_order_id is null
         or not public.is_effective_commercial_of_seller(
           auth.uid(),
           v_order.seller_id
         ) then
        raise exception
          'El pedido no pertenece a la estructura de este Comercial';
      end if;

    elsif v_role = 'DEPOSITO' then
      if p_area_origen <> 'DEPOSITO'
         or p_area_responsable not in ('DEPOSITO', 'ADMIN') then
        raise exception
          'Areas no permitidas para Deposito';
      end if;

    else
      raise exception
        'Este rol no puede crear incidencias mediante esta operacion';
    end if;
  end if;

  insert into public.incidents (
    estado,
    area_origen,
    area_responsable,
    creada_por,
    order_id,
    delivery_sheet_id,
    tipo,
    detalle
  )
  values (
    'PENDIENTE',
    p_area_origen,
    p_area_responsable,
    auth.uid(),
    p_order_id,
    p_delivery_sheet_id,
    trim(p_tipo),
    trim(p_detalle)
  )
  returning *
  into v_incident;

  return v_incident;
end;
$$;


-- ------------------------------------------------------------
-- 3. RLS DE LECTURA POR AREA + ESTRUCTURA
-- ------------------------------------------------------------

drop policy if exists incidents_area_structure_select
on public.incidents;

create policy incidents_area_structure_select
on public.incidents
for select
to authenticated
using (
  public.can_act_on_incident(id)
);


-- ------------------------------------------------------------
-- 4. PERMISOS
-- ------------------------------------------------------------

revoke all on function public.can_act_on_incident(bigint)
from public, anon;

grant execute on function public.can_act_on_incident(bigint)
to authenticated;

revoke all on function public.create_incident(
  public.incident_area,
  public.incident_area,
  text,
  text,
  bigint,
  bigint
) from public, anon;

grant execute on function public.create_incident(
  public.incident_area,
  public.incident_area,
  text,
  text,
  bigint,
  bigint
) to authenticated;
