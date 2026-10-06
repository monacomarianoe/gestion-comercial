-- ============================================================
-- ETAPA 6E.7
-- BLINDAJE DE PLANILLAS
-- ============================================================

-- ------------------------------------------------------------
-- 1. El Monitor solo puede CREAR planillas en BORRADOR
-- ------------------------------------------------------------

drop policy if exists delivery_sheets_monitor_insert
on public.delivery_sheets;

create policy delivery_sheets_monitor_insert
on public.delivery_sheets
for insert
to authenticated
with check (
  monitor_id = auth.uid()
  and estado = 'BORRADOR'
  and public.is_active_user()
);

-- ------------------------------------------------------------
-- 2. Evitar inserción directa de pedidos en planilla.
-- Deben entrar exclusivamente mediante RPC.
-- ------------------------------------------------------------

revoke insert
on public.delivery_sheet_orders
from authenticated;

-- ------------------------------------------------------------
-- 3. Evitar que un usuario cambie directamente
-- estado/timestamps críticos de una planilla.
--
-- Las RPC SECURITY DEFINER continúan pudiendo hacerlo.
-- ------------------------------------------------------------

revoke update
on public.delivery_sheets
from authenticated;

grant update (
  repartidor_id,
  vehicle_id,
  observaciones
)
on public.delivery_sheets
to authenticated;

-- ------------------------------------------------------------
-- 4. Validar estructura efectiva Monitor -> Repartidor.
-- Respeta asignaciones TEMPORALES que reemplazan permanentes.
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
    raise exception
      'El responsable de la planilla debe ser un Monitor activo';
  end if;

  if new.repartidor_id is not null then

    select rol
    into v_repartidor_role
    from public.profiles
    where id = new.repartidor_id
      and activo = true;

    if v_repartidor_role is distinct from 'REPARTIDOR' then
      raise exception
        'El repartidor asignado debe ser un Repartidor activo';
    end if;

    if not exists (
      select 1
      from public.effective_assignment(new.fecha::timestamptz) ea
      where ea.superior_id = new.monitor_id
        and ea.subordinado_id = new.repartidor_id
    ) then
      raise exception
        'El Repartidor no pertenece a la estructura efectiva del Monitor';
    end if;

  end if;

  return new;
end;
$$;