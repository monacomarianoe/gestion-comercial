import { redirect } from "next/navigation";
import { getCurrentProfile } from "@/lib/auth/profile";
import { LogoutButton } from "./logout-button";

export default async function AppLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const { userId, profile } = await getCurrentProfile();

  if (!userId) {
    redirect("/login");
  }

  if (!profile) {
    return (
      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col justify-center gap-4 px-4 py-10">
        <h1 className="text-xl font-semibold">Perfil no encontrado</h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          Tu usuario de autenticación no tiene un perfil asociado. Pedile a un
          administrador que revise el alta en la base de datos.
        </p>
        <LogoutButton />
      </main>
    );
  }

  if (!profile.activo) {
    return (
      <main className="mx-auto flex w-full max-w-lg flex-1 flex-col justify-center gap-4 px-4 py-10">
        <h1 className="text-xl font-semibold">Cuenta inactiva</h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          {profile.nombre} {profile.apellido}, tu cuenta todavía no está
          habilitada para operar. Un administrador debe activarla.
        </p>
        <LogoutButton />
      </main>
    );
  }

  return (
    <div className="flex min-h-full flex-1 flex-col">
      <header className="flex items-center justify-between gap-3 border-b border-zinc-200 px-4 py-3 dark:border-zinc-800">
        <p className="truncate text-sm font-medium text-zinc-900 dark:text-zinc-50">
          Gestión comercial
        </p>
        <LogoutButton />
      </header>
      {children}
    </div>
  );
}
