"use client";

import { useFormStatus } from "react-dom";
import { logout } from "@/app/login/actions";

function LogoutSubmit() {
  const { pending } = useFormStatus();

  return (
    <button
      className="h-10 rounded-lg border border-zinc-300 px-4 text-sm font-medium text-zinc-800 disabled:opacity-60 dark:border-zinc-700 dark:text-zinc-100"
      disabled={pending}
      type="submit"
    >
      {pending ? "Saliendo…" : "Cerrar sesión"}
    </button>
  );
}

export function LogoutButton() {
  return (
    <form action={logout}>
      <LogoutSubmit />
    </form>
  );
}
