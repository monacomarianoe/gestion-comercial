-- ============================================================
-- ETAPA 5 - COMERCIAL / SUPERVISOR
-- Bloque 1: alcance jerarquico efectivo
-- ============================================================
--
-- Reutiliza user_assignments de Etapa 2.
-- No crea una segunda estructura organizativa.
--
-- Una asignacion TEMPORAL vigente tiene prioridad sobre
-- la PERMANENTE, igual que effective_assignment().
-- ============================================================


-- ------------------------------------------------------------
-- SUPERVISOR EFECTIVO DE UN VENDEDOR
-- ------------------------------------------------------------

create or replace function public.is_effective_supervisor_of_seller(
  p_supervisor_id uuid,
  p_seller_id uuid,
  p_fecha timestamptz default now()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.effective_assignment(p_seller_id, p_fecha) ea
    join public.profiles superior
      on superior.id = ea.superior_id
    join public.profiles subordinado
      on subordinado.id = ea.subordinado_id
    where ea.superior_id = p_supervisor_id
      and superior.rol = 'SUPERVISOR'
      and superior.activo is true
      and subordinado.rol = 'VENDEDOR'
      and subordinado.activo is true
  );
$$;


-- ------------------------------------------------------------
-- COMERCIAL EFECTIVO DE UN SUPERVISOR
-- ------------------------------------------------------------

create or replace function public.is_effective_commercial_of_supervisor(
  p_commercial_id uuid,
  p_supervisor_id uuid,
  p_fecha timestamptz default now()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.effective_assignment(p_supervisor_id, p_fecha) ea
    join public.profiles superior
      on superior.id = ea.superior_id
    join public.profiles subordinado
      on subordinado.id = ea.subordinado_id
    where ea.superior_id = p_commercial_id
      and superior.rol = 'COMERCIAL'
      and superior.activo is true
      and subordinado.rol = 'SUPERVISOR'
      and subordinado.activo is true
  );
$$;


-- ------------------------------------------------------------
-- COMERCIAL EFECTIVO DE UN VENDEDOR
-- ------------------------------------------------------------
--
-- Resuelve:
-- COMERCIAL -> SUPERVISOR -> VENDEDOR
--
-- Ambas relaciones se calculan con la asignacion efectiva
-- de la fecha consultada.
-- ------------------------------------------------------------

create or replace function public.is_effective_commercial_of_seller(
  p_commercial_id uuid,
  p_seller_id uuid,
  p_fecha timestamptz default now()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.effective_assignment(p_seller_id, p_fecha) seller_assignment
    where public.is_effective_commercial_of_supervisor(
      p_commercial_id,
      seller_assignment.superior_id,
      p_fecha
    )
  );
$$;


-- ------------------------------------------------------------
-- SEGURIDAD DE LAS FUNCIONES
-- ------------------------------------------------------------

revoke all
on function public.is_effective_supervisor_of_seller(uuid, uuid, timestamptz)
from public;

revoke all
on function public.is_effective_commercial_of_supervisor(uuid, uuid, timestamptz)
from public;

revoke all
on function public.is_effective_commercial_of_seller(uuid, uuid, timestamptz)
from public;

