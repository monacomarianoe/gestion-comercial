import type { Database } from "@/types/database";

export type AppRole =
  Database["public"]["Enums"]["app_role"];

export const APP_ROLES: AppRole[] = [
  "ADMIN",
  "COMERCIAL",
  "SUPERVISOR",
  "VENDEDOR",
  "MONITOR",
  "REPARTIDOR",
  "DEPOSITO",
];

export const ROLE_LABELS: Record<AppRole, string> = {
  ADMIN: "Administrador",
  COMERCIAL: "Comercial",
  SUPERVISOR: "Supervisor",
  VENDEDOR: "Vendedor",
  MONITOR: "Monitor",
  REPARTIDOR: "Repartidor",
  DEPOSITO: "Depósito",
};

export function isAppRole(value: unknown): value is AppRole {
  return (
    typeof value === "string" &&
    APP_ROLES.includes(value as AppRole)
  );
}