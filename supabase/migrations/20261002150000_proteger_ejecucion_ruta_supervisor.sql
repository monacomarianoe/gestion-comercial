-- ============================================================
-- ETAPA 5
-- Proteger Inicio/Cierre de Ruta del Supervisor
-- ============================================================

-- Quitamos el UPDATE general sobre supervisor_workdays.
REVOKE UPDATE
ON TABLE public.supervisor_workdays
FROM authenticated;

-- Permitimos modificar únicamente los campos de planificación
-- que Comercial puede gestionar directamente.
GRANT UPDATE (
  modo,
  accompanied_seller_id
)
ON TABLE public.supervisor_workdays
TO authenticated;

-- Las columnas de ejecución:
--   inicio_ruta_at
--   inicio_lat
--   inicio_lng
--   cierre_ruta_at
--   cierre_lat
--   cierre_lng
-- quedan fuera del UPDATE directo.
--
-- El Supervisor las modifica exclusivamente mediante:
--   start_supervisor_route()
--   close_supervisor_route()
--
-- Ambas funciones son SECURITY DEFINER y ya realizan
-- las validaciones correspondientes.