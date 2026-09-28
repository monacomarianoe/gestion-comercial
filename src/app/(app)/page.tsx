import { ROLE_LABELS } from "@/lib/auth/roles";
import { getCurrentProfile } from "@/lib/auth/profile";

export default async function HomePage() {
  const { profile } = await getCurrentProfile();

  if (!profile) {
    return null;
  }

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-4 py-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">
          Hola, {profile.nombre} {profile.apellido}
        </h1>
        <p className="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
          Sesión autenticada con perfil en la base de datos.
        </p>
      </div>
      <dl className="grid grid-cols-1 gap-4 rounded-2xl border border-zinc-200 p-4 text-sm sm:grid-cols-2 dark:border-zinc-800">
        <div>
          <dt className="text-zinc-500">Email</dt>
          <dd className="font-medium break-all">{profile.email}</dd>
        </div>
        <div>
          <dt className="text-zinc-500">Rol</dt>
          <dd className="font-medium">
          {ROLE_LABELS[profile.rol as keyof typeof ROLE_LABELS]} ({profile.rol})
          </dd>
        </div>
        <div>
          <dt className="text-zinc-500">Estado</dt>
          <dd className="font-medium">Activo</dd>
        </div>
        <div>
          <dt className="text-zinc-500">Alta</dt>
          <dd className="font-medium">
            {new Date(profile.created_at).toLocaleString("es-AR")}
          </dd>
        </div>
      </dl>
    </main>
  );
}
