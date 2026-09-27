-- Etapa 3: clientes, zonas y productos.
-- No aplicar contra el proyecto remoto sin autorizacion explicita.
--
-- Orden de construccion:
-- 1. Zonas
-- 2. Clientes
-- 3. Productos, presentaciones, precios y promociones
--
-- Principios:
-- - Los registros operativos conservan historial.
-- - Las bajas no eliminan informacion historica.
-- - Los cambios sensibles quedan auditables.
-- - Las reglas criticas se protegen tambien en PostgreSQL.


-- =========================================================
-- ZONAS
-- =========================================================
CREATE TABLE public.zones (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  codigo text NOT NULL,
  nombre text NOT NULL,

  activa boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT zones_codigo_not_blank
    CHECK (length(trim(codigo)) > 0),

  CONSTRAINT zones_nombre_not_blank
    CHECK (length(trim(nombre)) > 0)
);

CREATE UNIQUE INDEX zones_codigo_lower_idx
  ON public.zones (lower(codigo));

COMMENT ON TABLE public.zones IS
  'Zonas comerciales. No se eliminan: se conserva su historial y pueden quedar inactivas.';
  CREATE TRIGGER zones_set_updated_at
BEFORE UPDATE ON public.zones
FOR EACH ROW
EXECUTE FUNCTION public.set_profiles_updated_at();
ALTER TABLE public.zones ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.zones FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.zones TO authenticated;

CREATE POLICY zones_active_users_select
ON public.zones
FOR SELECT
TO authenticated
USING (
  public.is_active_user()
);

CREATE POLICY zones_admin_comercial_insert
ON public.zones
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

CREATE POLICY zones_admin_comercial_update
ON public.zones
FOR UPDATE
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

REVOKE DELETE ON TABLE public.zones FROM authenticated;
-- =========================================================
-- CLIENTES
-- =========================================================

CREATE TYPE public.client_status AS ENUM (
  'ACTIVO',
  'BAJA'
);

CREATE TABLE public.clients (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  cod text NOT NULL,
  nombre text NOT NULL,
  rubro text NOT NULL,

  direccion text NOT NULL,
  localidad text NOT NULL,
  telefono text,

  zone_id bigint NOT NULL
    REFERENCES public.zones (id),

  estado public.client_status NOT NULL DEFAULT 'ACTIVO',

  tiene_heladera boolean NOT NULL DEFAULT false,
  heladera_foto_path text,

  fecha_ultima_compra timestamptz,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT clients_cod_not_blank
    CHECK (length(trim(cod)) > 0),

  CONSTRAINT clients_nombre_not_blank
    CHECK (length(trim(nombre)) > 0),

  CONSTRAINT clients_rubro_not_blank
    CHECK (length(trim(rubro)) > 0),

  CONSTRAINT clients_direccion_not_blank
    CHECK (length(trim(direccion)) > 0),

  CONSTRAINT clients_localidad_not_blank
    CHECK (length(trim(localidad)) > 0),

  CONSTRAINT clients_heladera_requires_photo
    CHECK (
      tiene_heladera IS FALSE
      OR (
        heladera_foto_path IS NOT NULL
        AND length(trim(heladera_foto_path)) > 0
      )
    )
);

CREATE UNIQUE INDEX clients_cod_lower_idx
  ON public.clients (lower(cod));

CREATE INDEX clients_zone_idx
  ON public.clients (zone_id);

CREATE INDEX clients_status_idx
  ON public.clients (estado);

CREATE INDEX clients_last_purchase_idx
  ON public.clients (fecha_ultima_compra);

COMMENT ON TABLE public.clients IS
  'Maestro de clientes comerciales. Las bajas conservan el registro y su historial.';
  CREATE TRIGGER clients_set_updated_at
BEFORE UPDATE ON public.clients
FOR EACH ROW
EXECUTE FUNCTION public.set_profiles_updated_at();


CREATE OR REPLACE FUNCTION public.prevent_client_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Los clientes no se eliminan; deben darse de baja mediante estado = BAJA'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER clients_prevent_delete
BEFORE DELETE
ON public.clients
FOR EACH ROW
EXECUTE FUNCTION public.prevent_client_delete();
ALTER TABLE public.clients
  ADD COLUMN baja_motivo text,
  ADD COLUMN baja_foto_path text,
  ADD COLUMN baja_at timestamptz,
  ADD COLUMN baja_por uuid
    REFERENCES public.profiles (id);

ALTER TABLE public.clients
  ADD CONSTRAINT clients_baja_requires_evidence
  CHECK (
    estado <> 'BAJA'
    OR (
      baja_motivo IS NOT NULL
      AND length(trim(baja_motivo)) > 0
      AND baja_foto_path IS NOT NULL
      AND length(trim(baja_foto_path)) > 0
      AND baja_at IS NOT NULL
      AND baja_por IS NOT NULL
    )
  );
  ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.clients FROM PUBLIC, anon;

GRANT SELECT ON TABLE public.clients TO authenticated;
GRANT INSERT, UPDATE ON TABLE public.clients TO authenticated;

CREATE POLICY clients_active_users_select
ON public.clients
FOR SELECT
TO authenticated
USING (
  public.is_active_user()
);

CREATE POLICY clients_admin_insert
ON public.clients
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
);

CREATE POLICY clients_admin_update
ON public.clients
FOR UPDATE
TO authenticated
USING (
  public.is_admin()
)
WITH CHECK (
  public.is_admin()
);

REVOKE DELETE ON TABLE public.clients FROM authenticated;
-- =========================================================
-- PRODUCTOS
-- =========================================================

CREATE TABLE public.products (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  codigo text NOT NULL,
  nombre text NOT NULL,

  activo boolean NOT NULL DEFAULT true,
  disponible_central boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT products_codigo_not_blank
    CHECK (length(trim(codigo)) > 0),

  CONSTRAINT products_nombre_not_blank
    CHECK (length(trim(nombre)) > 0)
);

CREATE UNIQUE INDEX products_codigo_lower_idx
  ON public.products (lower(codigo));

CREATE INDEX products_active_idx
  ON public.products (activo);

CREATE INDEX products_central_available_idx
  ON public.products (disponible_central);

COMMENT ON TABLE public.products IS
  'Maestro de productos. La disponibilidad central determina si el producto puede ofrecerse comercialmente; el stock local en cero no impide la venta.';
  CREATE TRIGGER products_set_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.set_profiles_updated_at();


CREATE OR REPLACE FUNCTION public.prevent_product_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Los productos no se eliminan; deben desactivarse mediante activo = false'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER products_prevent_delete
BEFORE DELETE
ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.prevent_product_delete();
CREATE TABLE public.product_presentations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  product_id bigint NOT NULL
    REFERENCES public.products (id),

  codigo text NOT NULL,
  nombre text NOT NULL,

  unidades integer NOT NULL DEFAULT 1,
  activa boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT product_presentations_codigo_not_blank
    CHECK (length(trim(codigo)) > 0),

  CONSTRAINT product_presentations_nombre_not_blank
    CHECK (length(trim(nombre)) > 0),

  CONSTRAINT product_presentations_unidades_positive
    CHECK (unidades > 0)
);

CREATE UNIQUE INDEX product_presentations_codigo_lower_idx
  ON public.product_presentations (lower(codigo));

CREATE INDEX product_presentations_product_idx
  ON public.product_presentations (product_id);

COMMENT ON TABLE public.product_presentations IS
  'Presentaciones comerciales de cada producto. Permite manejar unidades, packs, cajas u otras presentaciones sin duplicar el producto.';
  CREATE TRIGGER product_presentations_set_updated_at
BEFORE UPDATE ON public.product_presentations
FOR EACH ROW
EXECUTE FUNCTION public.set_profiles_updated_at();


CREATE OR REPLACE FUNCTION public.prevent_product_presentation_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Las presentaciones no se eliminan; deben desactivarse mediante activa = false'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER product_presentations_prevent_delete
BEFORE DELETE
ON public.product_presentations
FOR EACH ROW
EXECUTE FUNCTION public.prevent_product_presentation_delete();
-- =========================================================
-- PRECIOS
-- =========================================================

CREATE TABLE public.product_prices (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  presentation_id bigint NOT NULL
    REFERENCES public.product_presentations (id),

  precio numeric(14,2) NOT NULL,

  vigente_desde timestamptz NOT NULL DEFAULT now(),
  vigente_hasta timestamptz,

  creado_por uuid NOT NULL
    REFERENCES public.profiles (id),

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT product_prices_precio_non_negative
    CHECK (precio >= 0),

  CONSTRAINT product_prices_valid_period
    CHECK (
      vigente_hasta IS NULL
      OR vigente_hasta > vigente_desde
    )
);

CREATE INDEX product_prices_presentation_idx
  ON public.product_prices (presentation_id);

CREATE INDEX product_prices_period_idx
  ON public.product_prices (
    presentation_id,
    vigente_desde,
    vigente_hasta
  );

COMMENT ON TABLE public.product_prices IS
  'Historial de precios por presentación. Los precios se conservan por vigencia y no se sobrescriben.';
  CREATE OR REPLACE FUNCTION public.validate_product_price_period()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.product_prices pp
    WHERE pp.presentation_id = NEW.presentation_id
      AND pp.id IS DISTINCT FROM NEW.id
      AND tstzrange(
            pp.vigente_desde,
            pp.vigente_hasta,
            '[)'
          ) && tstzrange(
            NEW.vigente_desde,
            NEW.vigente_hasta,
            '[)'
          )
  ) THEN
    RAISE EXCEPTION
      'La presentación ya tiene un precio vigente dentro de ese período'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER product_prices_validate_period
BEFORE INSERT OR UPDATE
ON public.product_prices
FOR EACH ROW
EXECUTE FUNCTION public.validate_product_price_period();
CREATE OR REPLACE FUNCTION public.prevent_product_price_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Los precios no se eliminan; debe cerrarse su vigencia y crearse un nuevo precio'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER product_prices_prevent_delete
BEFORE DELETE
ON public.product_prices
FOR EACH ROW
EXECUTE FUNCTION public.prevent_product_price_delete();
-- =========================================================
-- PROMOCIONES
-- =========================================================

CREATE TABLE public.promotions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  nombre text NOT NULL,
  descripcion text,

  vigente_desde timestamptz NOT NULL DEFAULT now(),
  vigente_hasta timestamptz,

  activa boolean NOT NULL DEFAULT true,

  creado_por uuid NOT NULL
    REFERENCES public.profiles (id),

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT promotions_nombre_not_blank
    CHECK (length(trim(nombre)) > 0),

  CONSTRAINT promotions_valid_period
    CHECK (
      vigente_hasta IS NULL
      OR vigente_hasta > vigente_desde
    )
);

CREATE INDEX promotions_period_idx
  ON public.promotions (
    vigente_desde,
    vigente_hasta
  );

COMMENT ON TABLE public.promotions IS
  'Promociones comerciales con vigencia programable e historial.';
  CREATE TRIGGER promotions_set_updated_at
BEFORE UPDATE ON public.promotions
FOR EACH ROW
EXECUTE FUNCTION public.set_profiles_updated_at();


CREATE OR REPLACE FUNCTION public.prevent_promotion_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Las promociones no se eliminan; deben desactivarse o finalizar su vigencia'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER promotions_prevent_delete
BEFORE DELETE
ON public.promotions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_promotion_delete();
CREATE TABLE public.promotion_conditions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  promotion_id bigint NOT NULL
    REFERENCES public.promotions (id),

  presentation_id bigint NOT NULL
    REFERENCES public.product_presentations (id),

  cantidad_minima integer NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT promotion_conditions_quantity_positive
    CHECK (cantidad_minima > 0),

  CONSTRAINT promotion_conditions_unique_presentation
    UNIQUE (promotion_id, presentation_id)
);

CREATE INDEX promotion_conditions_promotion_idx
  ON public.promotion_conditions (promotion_id);

CREATE INDEX promotion_conditions_presentation_idx
  ON public.promotion_conditions (presentation_id);

COMMENT ON TABLE public.promotion_conditions IS
  'Condiciones de compra necesarias para acceder a una promoción.';
  CREATE TYPE public.promotion_benefit_type AS ENUM (
  'PRECIO_ESPECIAL',
  'DESCUENTO_PORCENTAJE',
  'BONIFICACION'
);

CREATE TABLE public.promotion_benefits (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  promotion_id bigint NOT NULL
    REFERENCES public.promotions (id),

  tipo public.promotion_benefit_type NOT NULL,

  presentation_id bigint NOT NULL
    REFERENCES public.product_presentations (id),

  precio_especial numeric(14,2),
  descuento_porcentaje numeric(5,2),
  cantidad_bonificada integer,

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT promotion_benefits_valid_values
    CHECK (
      (
        tipo = 'PRECIO_ESPECIAL'
        AND precio_especial IS NOT NULL
        AND precio_especial >= 0
        AND descuento_porcentaje IS NULL
        AND cantidad_bonificada IS NULL
      )
      OR
      (
        tipo = 'DESCUENTO_PORCENTAJE'
        AND descuento_porcentaje IS NOT NULL
        AND descuento_porcentaje > 0
        AND descuento_porcentaje <= 100
        AND precio_especial IS NULL
        AND cantidad_bonificada IS NULL
      )
      OR
      (
        tipo = 'BONIFICACION'
        AND cantidad_bonificada IS NOT NULL
        AND cantidad_bonificada > 0
        AND precio_especial IS NULL
        AND descuento_porcentaje IS NULL
      )
    )
);

CREATE INDEX promotion_benefits_promotion_idx
  ON public.promotion_benefits (promotion_id);

COMMENT ON TABLE public.promotion_benefits IS
  'Beneficios otorgados por una promoción: precio especial, descuento porcentual o unidades bonificadas.';
  CREATE OR REPLACE FUNCTION public.prevent_promotion_detail_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Los componentes de una promoción no se eliminan; debe finalizarse o desactivarse la promoción'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER promotion_conditions_prevent_delete
BEFORE DELETE
ON public.promotion_conditions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_promotion_detail_delete();

CREATE TRIGGER promotion_benefits_prevent_delete
BEFORE DELETE
ON public.promotion_benefits
FOR EACH ROW
EXECUTE FUNCTION public.prevent_promotion_detail_delete();
CREATE OR REPLACE FUNCTION public.prevent_zone_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Las zonas no se eliminan; deben desactivarse mediante activa = false'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER zones_prevent_delete
BEFORE DELETE
ON public.zones
FOR EACH ROW
EXECUTE FUNCTION public.prevent_zone_delete();
CREATE OR REPLACE FUNCTION public.guard_product_price_history()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.presentation_id IS DISTINCT FROM OLD.presentation_id
     OR NEW.precio IS DISTINCT FROM OLD.precio
     OR NEW.vigente_desde IS DISTINCT FROM OLD.vigente_desde
     OR NEW.creado_por IS DISTINCT FROM OLD.creado_por
     OR NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION
      'Un precio histórico no puede modificarse; solo puede cerrarse su vigencia'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER product_prices_guard_history
BEFORE UPDATE
ON public.product_prices
FOR EACH ROW
EXECUTE FUNCTION public.guard_product_price_history();
CREATE OR REPLACE FUNCTION public.prevent_promotion_detail_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION
    'Los componentes de una promoción no se modifican; debe finalizarse la promoción y crearse una nueva'
    USING ERRCODE = 'P0001';
END;
$$;

CREATE TRIGGER promotion_conditions_prevent_update
BEFORE UPDATE
ON public.promotion_conditions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_promotion_detail_update();

CREATE TRIGGER promotion_benefits_prevent_update
BEFORE UPDATE
ON public.promotion_benefits
FOR EACH ROW
EXECUTE FUNCTION public.prevent_promotion_detail_update();
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.products FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.products TO authenticated;

CREATE POLICY products_active_users_select
ON public.products
FOR SELECT
TO authenticated
USING (
  public.is_active_user()
);

CREATE POLICY products_admin_comercial_insert
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

CREATE POLICY products_admin_comercial_update
ON public.products
FOR UPDATE
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

REVOKE DELETE ON TABLE public.products FROM authenticated;
ALTER TABLE public.product_presentations ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.product_presentations FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.product_presentations TO authenticated;

CREATE POLICY product_presentations_active_users_select
ON public.product_presentations
FOR SELECT
TO authenticated
USING (
  public.is_active_user()
);

CREATE POLICY product_presentations_admin_comercial_insert
ON public.product_presentations
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

CREATE POLICY product_presentations_admin_comercial_update
ON public.product_presentations
FOR UPDATE
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

REVOKE DELETE ON TABLE public.product_presentations FROM authenticated;
ALTER TABLE public.product_prices ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.product_prices FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE ON TABLE public.product_prices TO authenticated;

CREATE POLICY product_prices_active_users_select
ON public.product_prices
FOR SELECT
TO authenticated
USING (
  public.is_active_user()
);

CREATE POLICY product_prices_admin_comercial_insert
ON public.product_prices
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

CREATE POLICY product_prices_admin_comercial_update
ON public.product_prices
FOR UPDATE
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

REVOKE DELETE ON TABLE public.product_prices FROM authenticated;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotion_benefits ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE
  public.promotions,
  public.promotion_conditions,
  public.promotion_benefits
FROM PUBLIC, anon;

GRANT SELECT, INSERT, UPDATE ON TABLE
  public.promotions,
  public.promotion_conditions,
  public.promotion_benefits
TO authenticated;


CREATE POLICY promotions_active_users_select
ON public.promotions
FOR SELECT
TO authenticated
USING (public.is_active_user());

CREATE POLICY promotions_admin_comercial_insert
ON public.promotions
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

CREATE POLICY promotions_admin_comercial_update
ON public.promotions
FOR UPDATE
TO authenticated
USING (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
)
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);


CREATE POLICY promotion_conditions_active_users_select
ON public.promotion_conditions
FOR SELECT
TO authenticated
USING (public.is_active_user());

CREATE POLICY promotion_conditions_admin_comercial_insert
ON public.promotion_conditions
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);


CREATE POLICY promotion_benefits_active_users_select
ON public.promotion_benefits
FOR SELECT
TO authenticated
USING (public.is_active_user());

CREATE POLICY promotion_benefits_admin_comercial_insert
ON public.promotion_benefits
FOR INSERT
TO authenticated
WITH CHECK (
  public.is_admin()
  OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND rol = 'COMERCIAL'
      AND activo IS TRUE
  )
);

REVOKE DELETE ON TABLE
  public.promotions,
  public.promotion_conditions,
  public.promotion_benefits
FROM authenticated;