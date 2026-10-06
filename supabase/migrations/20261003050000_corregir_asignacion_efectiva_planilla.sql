-- ============================================================
-- ETAPA 6E.8
-- CORREGIR VALIDACION DE ASIGNACION EFECTIVA EN PLANILLA
-- ============================================================

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
      from public.effective_assignment(
        new.repartidor_id,
        new.fecha::timestamptz
      ) ea
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