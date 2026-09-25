-- Etapa 1: perfiles vinculados a Supabase Auth.
-- No aplicar este archivo contra el proyecto remoto sin autorización explícita.

CREATE TYPE public.app_role AS ENUM (
  'ADMIN',
  'COMERCIAL',
  'SUPERVISOR',
  'VENDEDOR',
  'MONITOR',
  'REPARTIDOR',
  'DEPOSITO'
);

CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  nombre text NOT NULL,
  apellido text NOT NULL,
  email text NOT NULL,
  rol public.app_role NOT NULL,
  activo boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profiles_nombre_not_blank CHECK (length(trim(nombre)) > 0),
  CONSTRAINT profiles_apellido_not_blank CHECK (length(trim(apellido)) > 0),
  CONSTRAINT profiles_email_not_blank CHECK (length(trim(email)) > 0)
);

CREATE UNIQUE INDEX profiles_email_lower_idx ON public.profiles (lower(email));

COMMENT ON TABLE public.profiles IS
  'Perfil de aplicación 1:1 con auth.users. Las contraseñas no se almacenan aquí.';

CREATE OR REPLACE FUNCTION public.set_profiles_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_profiles_updated_at();

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'ADMIN'
      AND activo IS TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND activo IS TRUE
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requested text;
  new_role public.app_role;
BEGIN
  requested := upper(trim(coalesce(NEW.raw_user_meta_data ->> 'rol', '')));

  IF requested IN (
    'COMERCIAL',
    'SUPERVISOR',
    'VENDEDOR',
    'MONITOR',
    'REPARTIDOR',
    'DEPOSITO'
  ) THEN
    new_role := requested::public.app_role;
  ELSE
    -- Nunca ADMIN por defecto. El rol provisional no deja al usuario operativo.
    new_role := 'VENDEDOR';
  END IF;

  INSERT INTO public.profiles (
    id,
    nombre,
    apellido,
    email,
    rol,
    activo
  )
  VALUES (
    NEW.id,
    coalesce(nullif(trim(NEW.raw_user_meta_data ->> 'nombre'), ''), 'Pendiente'),
    coalesce(nullif(trim(NEW.raw_user_meta_data ->> 'apellido'), ''), 'Pendiente'),
    lower(coalesce(NEW.email, '')),
    new_role,
    false
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.sync_profile_email_from_auth()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    PERFORM set_config('app.skip_profile_guard', '1', true);

    UPDATE public.profiles
    SET email = lower(coalesce(NEW.email, ''))
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_email_updated
AFTER UPDATE OF email ON auth.users
FOR EACH ROW
WHEN (NEW.email IS DISTINCT FROM OLD.email)
EXECUTE FUNCTION public.sync_profile_email_from_auth();

CREATE OR REPLACE FUNCTION public.guard_profile_updates()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_setting('app.skip_profile_guard', true) = '1' THEN
    RETURN NEW;
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'No se puede cambiar el id del perfil'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'No se puede cambiar created_at'
      USING ERRCODE = 'P0001';
  END IF;

  IF OLD.rol = 'ADMIN' AND OLD.activo IS TRUE THEN
    IF NEW.activo IS NOT TRUE OR NEW.rol IS DISTINCT FROM 'ADMIN'::public.app_role THEN
      IF NOT EXISTS (
        SELECT 1
        FROM public.profiles AS other
        WHERE other.id <> OLD.id
          AND other.rol = 'ADMIN'
          AND other.activo IS TRUE
      ) THEN
        RAISE EXCEPTION 'No se puede desactivar o degradar al último ADMIN activo'
          USING ERRCODE = 'P0001';
      END IF;
    END IF;
  END IF;

  IF public.is_admin() THEN
    IF NEW.email IS DISTINCT FROM OLD.email THEN
      RAISE EXCEPTION 'El email se sincroniza desde Supabase Auth'
        USING ERRCODE = 'P0001';
    END IF;

    RETURN NEW;
  END IF;

  IF NOT public.is_active_user() THEN
    RAISE EXCEPTION 'La cuenta inactiva no puede modificar el perfil'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.rol IS DISTINCT FROM OLD.rol
     OR NEW.activo IS DISTINCT FROM OLD.activo
     OR NEW.email IS DISTINCT FROM OLD.email THEN
    RAISE EXCEPTION 'No autorizado a modificar rol, estado o email'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_guard_updates
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.guard_profile_updates();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

GRANT USAGE ON TYPE public.app_role TO authenticated;

REVOKE ALL ON TABLE public.profiles FROM PUBLIC, anon;
GRANT SELECT, UPDATE ON TABLE public.profiles TO authenticated;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_active_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_active_user() TO authenticated;

CREATE POLICY profiles_select_own_or_admin
ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id OR public.is_admin());

CREATE POLICY profiles_update_own_or_admin
ON public.profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id OR public.is_admin())
WITH CHECK (auth.uid() = id OR public.is_admin());

-- Sin políticas INSERT/DELETE: el alta es por trigger sobre auth.users;
-- la baja operativa es activo = false.

-- Bootstrap controlado del primer ADMIN (manual, después de crear el usuario en Auth):
-- UPDATE public.profiles
-- SET rol = 'ADMIN', activo = true, nombre = 'Nombre', apellido = 'Apellido'
-- WHERE email = 'admin@tu-dominio.com';
