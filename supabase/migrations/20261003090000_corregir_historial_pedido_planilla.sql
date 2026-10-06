-- ============================================================
-- ETAPA 6
-- PERMITIR HISTORIAL DEL MISMO PEDIDO EN VARIAS PLANILLAS
-- ============================================================

-- Quitar la restricción histórica original:
-- UNIQUE(order_id)
alter table public.delivery_sheet_orders
drop constraint if exists delivery_sheet_orders_order_unique;

-- Por seguridad, eliminar también un posible índice viejo
-- con el mismo nombre si existiera como índice independiente.
drop index if exists public.delivery_sheet_orders_order_unique;

-- Solo puede existir UNA relación ACTIVA por pedido.
-- Las relaciones históricas inactivas se conservan.
create unique index if not exists
delivery_sheet_orders_order_active_unique
on public.delivery_sheet_orders(order_id)
where activo = true;