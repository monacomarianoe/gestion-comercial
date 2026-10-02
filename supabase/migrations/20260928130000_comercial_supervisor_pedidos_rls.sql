-- ============================================================
-- ETAPA 5 - COMERCIAL / SUPERVISOR
-- Bloque 2: visibilidad de pedidos por estructura efectiva
-- ============================================================

-- SUPERVISOR:
-- puede consultar pedidos de sus vendedores efectivos.

create policy orders_supervisor_select
on public.orders
for select
to authenticated
using (
  public.is_effective_supervisor_of_seller(
    auth.uid(),
    seller_id
  )
);


-- COMERCIAL:
-- puede consultar pedidos de los vendedores pertenecientes
-- a su estructura efectiva.

create policy orders_comercial_select
on public.orders
for select
to authenticated
using (
  public.is_effective_commercial_of_seller(
    auth.uid(),
    seller_id
  )
);


-- SUPERVISOR: items de los pedidos de sus vendedores.

create policy order_items_supervisor_select
on public.order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = order_items.order_id
      and public.is_effective_supervisor_of_seller(
        auth.uid(),
        o.seller_id
      )
  )
);


-- COMERCIAL: items de pedidos de vendedores
-- pertenecientes a su estructura efectiva.

create policy order_items_comercial_select
on public.order_items
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = order_items.order_id
      and public.is_effective_commercial_of_seller(
        auth.uid(),
        o.seller_id
      )
  )
);