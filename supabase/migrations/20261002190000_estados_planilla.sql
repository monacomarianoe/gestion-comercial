-- ============================================================
-- ETAPA 6D
-- ESTADOS Y TRANSICIONES DE PLANILLA
-- ============================================================

-- Nuevo estado:
-- ASIGNADA -> ACEPTADA -> EN_REPARTO
alter type public.delivery_sheet_status
add value if not exists 'ACEPTADA' after 'ASIGNADA';