-- ============================================================
-- ETAPA 6
-- PERMITIR EL MISMO REMITO EN EL HISTORIAL DEL MISMO PEDIDO
-- ============================================================

-- El remito es único a nivel PEDIDO (orders.numero_remito),
-- pero puede aparecer en varias relaciones históricas
-- delivery_sheet_orders del mismo pedido.

alter table public.delivery_sheet_orders
drop constraint if exists delivery_sheet_orders_remito_unique;

drop index if exists public.delivery_sheet_orders_remito_unique;

-- Dentro de una misma planilla un remito no puede repetirse.
create unique index if not exists
delivery_sheet_orders_sheet_remito_unique
on public.delivery_sheet_orders(delivery_sheet_id, numero_remito);