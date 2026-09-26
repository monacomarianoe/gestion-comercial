-- Etapa 2: estructura organizativa y asignaciones.
-- No aplicar contra el proyecto remoto sin autorizacion explicita.
--
-- Jerarquia permitida:
-- COMERCIAL -> SUPERVISOR -> VENDEDOR
-- MONITOR -> REPARTIDOR
--
-- ADMIN administra toda la estructura.
-- DEPOSITO es transversal y no lleva asignacion jerarquica.
--
-- Las asignaciones conservan historial.
-- Una asignacion TEMPORAL reemplaza a la PERMANENTE durante
-- su periodo de vigencia, sin destruirla.

CREATE TYPE public.assignment_type AS ENUM (
  'PERMANENTE',
  'TEMPORAL'
);

CREATE TABLE public.user_assignments (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  superior_id uuid NOT NULL
    REFERENCES public.profiles (id),

  subordinado_id uuid NOT NULL
    REFERENCES public.profiles (id),

  tipo public.assignment_type NOT NULL,

  desde timestamptz NOT NULL DEFAULT now(),

  hasta timestamptz,

  creado_por uuid NOT NULL
    REFERENCES public.profiles (id),

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT user_assignments_no_self_assignment
    CHECK (superior_id <> subordinado_id),

  CONSTRAINT user_assignments_valid_period
    CHECK (hasta IS NULL OR hasta > desde)
);

CREATE INDEX user_assignments_superior_idx
  ON public.user_assignments (superior_id);

CREATE INDEX user_assignments_subordinado_idx
  ON public.user_assignments (subordinado_id);

CREATE INDEX user_assignments_period_idx
  ON public.user_assignments (subordinado_id, desde, hasta);

COMMENT ON TABLE public.user_assignments IS
  'Historial de relaciones jerarquicas. Las asignaciones cerradas no se eliminan.';


-- =========================================================
-- VALIDACION DE ROLES Y ESTADO DE LOS USUARIOS
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_user_assignment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  superior_role public.app_role;
  subordinado_role public.app_role;
  superior_activo boolean;
  subordinado_activo boolean;
BEGIN
  SELECT rol, activo
  INTO superior_role, superior_activo
  FROM public.profiles
  WHERE id = NEW.superior_id;

  SELECT rol, activo
  INTO subordinado_role, subordinado_activo
  FROM public.profiles
  WHERE id = NEW.subordinado_id;

  IF superior_role IS NULL OR subordinado_role IS NULL THEN
    RAISE EXCEPTION 'Los usuarios de la asignacion deben existir'
      USING ERRCODE = 'P0001';
  END IF;

  IF superior_activo IS NOT TRUE OR subordinado_activo IS NOT TRUE THEN
    RAISE EXCEPTION 'Solo pueden crearse asignaciones entre usuarios activos'
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT (
    (superior_role = 'COMERCIAL' AND subordinado_role = 'SUPERVISOR')
    OR
    (superior_role = 'SUPERVISOR' AND subordinado_role = 'VENDEDOR')
    OR
    (superior_role = 'MONITOR' AND subordinado_role = 'REPARTIDOR')
  ) THEN
    RAISE EXCEPTION 'Relacion jerarquica no permitida: % -> %',
      superior_role, subordinado_role
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER user_assignments_validate_roles
BEFORE INSERT OR UPDATE
ON public.user_assignments
FOR EACH ROW
EXECUTE FUNCTION public.validate_user_assignment();


-- =========================================================
-- VALIDACION DE PERIODOS E HISTORIAL
-- =========================================================

CREATE OR REPLACE FUNCTION public.validate_assignment_period()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.hasta IS NOT NULL AND NEW.hasta <= NEW.desde THEN
    RAISE EXCEPTION 'La fecha hasta debe ser posterior a la fecha desde'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.tipo = 'TEMPORAL' AND NEW.hasta IS NULL THEN
    RAISE EXCEPTION 'Una asignacion TEMPORAL debe tener fecha hasta'
      USING ERRCODE = 'P0001';
  END IF;

  -- Solo una asignacion permanente ABIERTA por subordinado.
  IF NEW.tipo = 'PERMANENTE' AND NEW.hasta IS NULL THEN
    IF EXISTS (
      SELECT 1
      FROM public.user_assignments AS ua
      WHERE ua.subordinado_id = NEW.subordinado_id
        AND ua.tipo = 'PERMANENTE'
        AND ua.hasta IS NULL
        AND ua.id <> NEW.id
    ) THEN
      RAISE EXCEPTION
        'El usuario ya tiene una asignacion permanente abierta'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  -- No permitimos dos reemplazos temporales que se superpongan
  -- para el mismo subordinado.
  IF NEW.tipo = 'TEMPORAL' THEN
    IF EXISTS (
      SELECT 1
      FROM public.user_assignments AS ua
      WHERE ua.subordinado_id = NEW.subordinado_id
        AND ua.tipo = 'TEMPORAL'
        AND ua.id <> NEW.id
        AND tstzrange(ua.desde, ua.hasta, '[)')
            && tstzrange(NEW.desde, NEW.hasta, '[)')
    ) THEN
      RAISE EXCEPTION
        'El usuario ya tiene una asignacion temporal superpuesta'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER user_assignments_validate_period
BEFORE INSERT OR UPDATE
ON public.user_assignments
FOR EACH ROW
EXECUTE FUNCTION public.validate_assignment_period();


-- =========================================================
-- ASIGNACION EFECTIVA EN UNA FECHA
-- =========================================================
--
-- Si existe TEMPORAL vigente, manda sobre PERMANENTE.
-- Al finalizar la temporal, la permanente vuelve a ser efectiva
-- automaticamente porque nunca fue eliminada ni modificada.

CREATE OR REPLACE FUNCTION public.effective_assignment(
  p_subordinado_id uuid,
  p_fecha timestamptz DEFAULT now()
)
RETURNS TABLE (
  assignment_id bigint,
  superior_id uuid,
  subordinado_id uuid,
  tipo public.assignment_type,
  desde timestamptz,
  hasta timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    ua.id,
    ua.superior_id,
    ua.subordinado_id,
    ua.tipo,
    ua.desde,
    ua.hasta
  FROM public.user_assignments AS ua
  WHERE ua.subordinado_id = p_subordinado_id
    AND ua.desde <= p_fecha
    AND (ua.hasta IS NULL OR p_fecha < ua.hasta)
  ORDER BY
    CASE
      WHEN ua.tipo = 'TEMPORAL' THEN 0
      ELSE 1
    END,
    ua.desde DESC,
    ua.id DESC
  LIMIT 1;
$$;

-- =========================================================
-- PROTECCION DEL HISTORIAL
-- =========================================================

CREATE OR REPLACE FUNCTION public.guard_assignment_history()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'No se puede modificar el id de una asignacion'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.creado_por IS DISTINCT FROM OLD.creado_por THEN
    RAISE EXCEPTION 'No se puede modificar quien creo la asignacion'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'No se puede modificar la fecha de creacion'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER user_assignments_guard_history
CREATE OR REPLACE FUNCTION public.prevent_assignment_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Las asignaciones no se eliminan; deben cerrarse mediante hasta'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER user_assignments_prevent_delete
BEFORE DELETE
ON public.user_assignments
FOR EACH ROW
EXECUTE FUNCTION public.prevent_assignment_delete();

-- =========================================================
-- SEGURIDAD / RLS
-- =========================================================

ALTER TABLE public.user_assignments ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.user_assignments FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.user_assignments
TO authenticated;

REVOKE ALL ON FUNCTION public.effective_assignment(uuid, timestamptz)
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION public.effective_assignment(uuid, timestamptz)
TO authenticated;


-- ADMIN puede consultar y administrar toda la estructura.

CREATE POLICY user_assignments_admin_select
ON public.user_assignments
FOR SELECT
TO authenticated
USING (public.is_admin());

CREATE POLICY user_assignments_admin_insert
ON public.user_assignments
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  AND creado_por = auth.uid()
);

CREATE POLICY user_assignments_admin_update
ON public.user_assignments
FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (
  public.is_admin()
  AND creado_por IS NOT NULL
);


-- Los usuarios activos pueden consultar exclusivamente las
-- asignaciones en las que participan directamente.
-- El acceso a estructuras descendientes completas se ampliara
-- de forma controlada cuando se implementen los modulos que
-- necesiten esa visibilidad.

CREATE POLICY user_assignments_participant_select
ON public.user_assignments
FOR SELECT
TO authenticated
USING (
  public.is_active_user()
  AND (
    superior_id = auth.uid()
    OR subordinado_id = auth.uid()
  )
);


-- No existe DELETE.
-- El historial se conserva cerrando una asignacion mediante "hasta".

REVOKE DELETE ON TABLE public.user_assignments FROM authenticated;