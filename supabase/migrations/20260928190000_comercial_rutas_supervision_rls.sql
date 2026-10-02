-- ============================================================
-- ETAPA 5
-- Bloque 7: RLS Comercial - rutas y supervision
--
-- COMERCIAL puede:
--   - gestionar ruta diaria de vendedores de su estructura
--   - configurar jornada/modo de sus supervisores
--   - asignar zonas y criticidades a MODO_SUPERVISION
--
-- SUPERVISOR puede:
--   - consultar la ruta diaria de sus vendedores efectivos
--
-- ADMIN conserva control total.
-- No se habilitan DELETE.
-- ============================================================


-- ============================================================
-- SELLER DAILY ROUTES
-- ============================================================

create policy seller_daily_routes_comercial_select
on public.seller_daily_routes
for select
to authenticated
using (
  public.is_active_user()
  and public.is_effective_commercial_of_seller(
    auth.uid(),
    seller_id,
    fecha::timestamp + time '12:00'
  )
);


create policy seller_daily_routes_comercial_insert
on public.seller_daily_routes
for insert
to authenticated
with check (
  public.is_active_user()
  and creado_por = auth.uid()
  and public.is_effective_commercial_of_seller(
    auth.uid(),
    seller_id,
    fecha::timestamp + time '12:00'
  )
);


create policy seller_daily_routes_comercial_update
on public.seller_daily_routes
for update
to authenticated
using (
  public.is_active_user()
  and public.is_effective_commercial_of_seller(
    auth.uid(),
    seller_id,
    fecha::timestamp + time '12:00'
  )
)
with check (
  public.is_active_user()
  and public.is_effective_commercial_of_seller(
    auth.uid(),
    seller_id,
    fecha::timestamp + time '12:00'
  )
);


-- Supervisor puede consultar la ruta diaria
-- de sus vendedores efectivos.

create policy seller_daily_routes_supervisor_select
on public.seller_daily_routes
for select
to authenticated
using (
  public.is_active_user()
  and public.is_effective_supervisor_of_seller(
    auth.uid(),
    seller_id,
    fecha::timestamp + time '12:00'
  )
);


-- ============================================================
-- SUPERVISOR WORKDAYS
-- ============================================================

create policy supervisor_workdays_comercial_select
on public.supervisor_workdays
for select
to authenticated
using (
  public.is_active_user()
  and public.is_effective_commercial_of_supervisor(
    auth.uid(),
    supervisor_id,
    fecha::timestamp + time '12:00'
  )
);


create policy supervisor_workdays_comercial_insert
on public.supervisor_workdays
for insert
to authenticated
with check (
  public.is_active_user()
  and creado_por = auth.uid()
  and public.is_effective_commercial_of_supervisor(
    auth.uid(),
    supervisor_id,
    fecha::timestamp + time '12:00'
  )
);


create policy supervisor_workdays_comercial_update
on public.supervisor_workdays
for update
to authenticated
using (
  public.is_active_user()
  and public.is_effective_commercial_of_supervisor(
    auth.uid(),
    supervisor_id,
    fecha::timestamp + time '12:00'
  )
)
with check (
  public.is_active_user()
  and public.is_effective_commercial_of_supervisor(
    auth.uid(),
    supervisor_id,
    fecha::timestamp + time '12:00'
  )
);


-- ============================================================
-- SUPERVISOR WORKDAY ZONES
-- ============================================================

create policy supervisor_workday_zones_comercial_select
on public.supervisor_workday_zones
for select
to authenticated
using (
  exists (
    select 1
    from public.supervisor_workdays sw
    where sw.id = supervisor_workday_zones.workday_id
      and public.is_effective_commercial_of_supervisor(
        auth.uid(),
        sw.supervisor_id,
        sw.fecha::timestamp + time '12:00'
      )
  )
);


create policy supervisor_workday_zones_comercial_insert
on public.supervisor_workday_zones
for insert
to authenticated
with check (
  exists (
    select 1
    from public.supervisor_workdays sw
    where sw.id = supervisor_workday_zones.workday_id
      and public.is_effective_commercial_of_supervisor(
        auth.uid(),
        sw.supervisor_id,
        sw.fecha::timestamp + time '12:00'
      )
  )
);


-- ============================================================
-- SUPERVISOR WORKDAY CRITICALITIES
-- ============================================================

create policy supervisor_workday_criticalities_comercial_select
on public.supervisor_workday_criticalities
for select
to authenticated
using (
  exists (
    select 1
    from public.supervisor_workdays sw
    where sw.id = supervisor_workday_criticalities.workday_id
      and public.is_effective_commercial_of_supervisor(
        auth.uid(),
        sw.supervisor_id,
        sw.fecha::timestamp + time '12:00'
      )
  )
);


create policy supervisor_workday_criticalities_comercial_insert
on public.supervisor_workday_criticalities
for insert
to authenticated
with check (
  exists (
    select 1
    from public.supervisor_workdays sw
    where sw.id = supervisor_workday_criticalities.workday_id
      and public.is_effective_commercial_of_supervisor(
        auth.uid(),
        sw.supervisor_id,
        sw.fecha::timestamp + time '12:00'
      )
  )
);