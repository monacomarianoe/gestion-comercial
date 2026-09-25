import { APP_ROLES, type AppRole } from "@/types/database";

export { APP_ROLES, type AppRole };

export const ROLE_LABELS: Record<AppRole, string> = {
  ADMIN: "Administrador",
  COMERCIAL: "Comercial",
  SUPERVISOR: "Supervisor",
  VENDEDOR: "Vendedor",
  MONITOR: "Monitor",
  REPARTIDOR: "Repartidor",
  DEPOSITO: "Depósito",
};

export function isAppRole(value: string): value is AppRole {
  return (APP_ROLES as readonly string[]).includes(value);
}
