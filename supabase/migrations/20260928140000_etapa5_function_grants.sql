-- ============================================================
-- ETAPA 5
-- Permisos de ejecucion para funciones utilizadas por RLS
-- ============================================================

grant execute
on function public.is_effective_supervisor_of_seller(uuid, uuid, timestamptz)
to authenticated;

grant execute
on function public.is_effective_commercial_of_supervisor(uuid, uuid, timestamptz)
to authenticated;

grant execute
on function public.is_effective_commercial_of_seller(uuid, uuid, timestamptz)
to authenticated;