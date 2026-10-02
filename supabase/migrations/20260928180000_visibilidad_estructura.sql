-- ============================================================
-- ETAPA 5
-- Bloque 6: visibilidad jerarquica de estructura
--
-- COMERCIAL:
--   ve sus Supervisores efectivos
--   ve los Vendedores efectivos de esos Supervisores
--
-- SUPERVISOR:
--   ve sus Vendedores efectivos
--
-- Solo lectura.
-- No agrega permisos de modificacion.
-- ============================================================


-- ============================================================
-- FUNCION:
-- ¿Puede el usuario actual ver este perfil por estructura?
-- ============================================================

create or replace function public.can_view_profile_in_structure(
  p_viewer_id uuid,
  p_profile_id uuid,
  p_fecha timestamptz default now()
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    -- Siempre puede verse a sí mismo.
    p_viewer_id = p_profile_id

    or

    -- ADMIN puede ver toda la estructura.
    exists (
      select 1
      from public.profiles p
      where p.id = p_viewer_id
        and p.rol = 'ADMIN'
        and p.activo = true
    )

    or

    -- SUPERVISOR -> VENDEDOR efectivo.
    public.is_effective_supervisor_of_seller(
      p_viewer_id,
      p_profile_id,
      p_fecha
    )

    or

    -- COMERCIAL -> SUPERVISOR efectivo.
    public.is_effective_commercial_of_supervisor(
      p_viewer_id,
      p_profile_id,
      p_fecha
    )

    or

    -- COMERCIAL -> VENDEDOR efectivo
    -- a través de su Supervisor.
    public.is_effective_commercial_of_seller(
      p_viewer_id,
      p_profile_id,
      p_fecha
    );
$$;


revoke all
on function public.can_view_profile_in_structure(uuid, uuid, timestamptz)
from public, anon;

grant execute
on function public.can_view_profile_in_structure(uuid, uuid, timestamptz)
to authenticated;


-- ============================================================
-- PROFILES
-- Amplía SELECT solamente.
-- La política original own/admin permanece.
-- ============================================================

create policy profiles_structure_select
on public.profiles
for select
to authenticated
using (
  public.is_active_user()
  and public.can_view_profile_in_structure(
    auth.uid(),
    id,
    now()
  )
);


-- ============================================================
-- USER_ASSIGNMENTS
--
-- Permite consultar las relaciones necesarias para mostrar
-- la estructura visible del usuario.
--
-- No concede INSERT/UPDATE/DELETE.
-- ============================================================

create policy user_assignments_structure_select
on public.user_assignments
for select
to authenticated
using (
  public.is_active_user()
  and (
    -- SUPERVISOR:
    -- asignaciones efectivas hacia sus vendedores.
    public.is_effective_supervisor_of_seller(
      auth.uid(),
      subordinado_id,
      now()
    )

    or

    -- COMERCIAL:
    -- asignaciones hacia sus supervisores efectivos.
    public.is_effective_commercial_of_supervisor(
      auth.uid(),
      subordinado_id,
      now()
    )

    or

    -- COMERCIAL:
    -- asignaciones Supervisor -> Vendedor
    -- correspondientes a vendedores de su estructura.
    public.is_effective_commercial_of_seller(
      auth.uid(),
      subordinado_id,
      now()
    )
  )
);