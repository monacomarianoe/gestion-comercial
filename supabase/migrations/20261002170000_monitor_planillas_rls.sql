-- ============================================================
-- ETAPA 6B
-- RLS MONITOR / REPARTIDOR / ADMIN
-- ============================================================

-- ------------------------------------------------------------
-- VEHICULOS
-- Todos los usuarios activos pueden consultarlos.
-- Su administración queda reservada al Admin.
-- ------------------------------------------------------------

create policy vehicles_active_users_select
on public.vehicles
for select
to authenticated
using (public.is_active_user());

create policy vehicles_admin_insert
on public.vehicles
for insert
to authenticated
with check (public.is_admin());

create policy vehicles_admin_update
on public.vehicles
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

grant insert, update on public.vehicles to authenticated;


-- ------------------------------------------------------------
-- PLANILLAS - ADMIN
-- ------------------------------------------------------------

create policy delivery_sheets_admin_all
on public.delivery_sheets
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());


-- ------------------------------------------------------------
-- PLANILLAS - MONITOR
-- El Monitor ve y opera únicamente sus propias planillas.
-- ------------------------------------------------------------

create policy delivery_sheets_monitor_select
on public.delivery_sheets
for select
to authenticated
using (
  monitor_id = auth.uid()
  and public.is_active_user()
);

create policy delivery_sheets_monitor_insert
on public.delivery_sheets
for insert
to authenticated
with check (
  monitor_id = auth.uid()
  and public.is_active_user()
);

create policy delivery_sheets_monitor_update
on public.delivery_sheets
for update
to authenticated
using (
  monitor_id = auth.uid()
  and public.is_active_user()
)
with check (
  monitor_id = auth.uid()
  and public.is_active_user()
);


-- ------------------------------------------------------------
-- PLANILLAS - REPARTIDOR
-- El Repartidor solamente consulta las planillas asignadas.
-- No puede crearlas ni modificarlas directamente.
-- ------------------------------------------------------------

create policy delivery_sheets_repartidor_select
on public.delivery_sheets
for select
to authenticated
using (
  repartidor_id = auth.uid()
  and public.is_active_user()
);


-- ------------------------------------------------------------
-- PEDIDOS DE PLANILLA - ADMIN
-- ------------------------------------------------------------

create policy delivery_sheet_orders_admin_all
on public.delivery_sheet_orders
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());


-- ------------------------------------------------------------
-- PEDIDOS DE PLANILLA - MONITOR
-- Solo sobre planillas que le pertenecen.
-- ------------------------------------------------------------

create policy delivery_sheet_orders_monitor_select
on public.delivery_sheet_orders
for select
to authenticated
using (
  exists (
    select 1
    from public.delivery_sheets ds
    where ds.id = delivery_sheet_orders.delivery_sheet_id
      and ds.monitor_id = auth.uid()
  )
  and public.is_active_user()
);

create policy delivery_sheet_orders_monitor_insert
on public.delivery_sheet_orders
for insert
to authenticated
with check (
  exists (
    select 1
    from public.delivery_sheets ds
    where ds.id = delivery_sheet_orders.delivery_sheet_id
      and ds.monitor_id = auth.uid()
  )
  and public.is_active_user()
);


-- ------------------------------------------------------------
-- PEDIDOS DE PLANILLA - REPARTIDOR
-- Solo lectura de los pedidos de sus propias planillas.
-- ------------------------------------------------------------

create policy delivery_sheet_orders_repartidor_select
on public.delivery_sheet_orders
for select
to authenticated
using (
  exists (
    select 1
    from public.delivery_sheets ds
    where ds.id = delivery_sheet_orders.delivery_sheet_id
      and ds.repartidor_id = auth.uid()
  )
  and public.is_active_user()
);