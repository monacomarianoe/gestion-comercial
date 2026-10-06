-- ============================================================
-- ETAPA 6
-- GUARDADO POR INCIDENCIA
--
-- GUARDADO puede representar:
-- 1. pedido reprogramado, con fecha_entrega
-- 2. pedido retirado de operación por incidencia,
--    todavía sin nueva fecha de entrega
-- ============================================================

alter table public.orders
drop constraint if exists orders_guardado_fecha_check;