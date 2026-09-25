# Gestión comercial

Aplicación interna de gestión comercial y distribución (Next.js 16, App Router, Supabase Auth).

No hay registro público. Las contraseñas viven solo en Supabase Auth.

## Requisitos

- Node.js 20+
- Proyecto de Supabase con Auth
- Variables públicas en `.env.local` (no commitear ese archivo):

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
```

Si el proyecto todavía usa la clave anon pública, se puede definir `NEXT_PUBLIC_SUPABASE_ANON_KEY` en su lugar. Nunca pongas `service_role` ni secretos en el cliente ni en el repositorio.

## Base de datos (manual)

La migración `supabase/migrations/20260925200000_profiles_auth.sql` **no se aplica sola**. Hay que ejecutarla en el SQL Editor del proyecto (o `supabase db push` cuando se autorice).

Efectos:

- Crea `public.profiles` (1:1 con `auth.users`)
- Alta de perfil con `activo = false` (nunca ADMIN por defecto)
- RLS + protección del último ADMIN activo
- Sincroniza email desde Auth hacia `profiles`

En Authentication del dashboard:

1. Desactivar el registro público / sign-up abierto.
2. Confirmar que Site URL y Redirect URLs incluyen `http://localhost:3000`.

## Primer ADMIN (bootstrap controlado)

1. Crear el usuario en **Authentication → Users** (invite o alta manual).
2. El trigger crea el perfil **inactivo** y con un rol no ADMIN.
3. En SQL Editor, una sola vez:

```sql
UPDATE public.profiles
SET
  rol = 'ADMIN',
  activo = true,
  nombre = 'Nombre',
  apellido = 'Apellido'
WHERE email = 'admin@tu-dominio.com';
```

Sin este paso, el usuario puede autenticarse pero la app lo trata como cuenta inactiva.

Los usuarios posteriores también nacen inactivos. En esta etapa no hay ABM: la activación y el rol se ajustan en SQL.

## Desarrollo

```bash
npm run dev
```

Abrir [http://localhost:3000](http://localhost:3000). Sin sesión se redirige a `/login`.

## Fuera de alcance (todavía)

Asignaciones jerárquicas, organigrama, ABM de usuarios, módulos comerciales y PWA.
