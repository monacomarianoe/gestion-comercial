export const APP_ROLES = [
  "ADMIN",
  "COMERCIAL",
  "SUPERVISOR",
  "VENDEDOR",
  "MONITOR",
  "REPARTIDOR",
  "DEPOSITO",
] as const;

export type AppRole = (typeof APP_ROLES)[number];

export type Profile = {
  id: string;
  nombre: string;
  apellido: string;
  email: string;
  rol: AppRole;
  activo: boolean;
  created_at: string;
  updated_at: string;
};

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: {
          id: string;
          nombre: string;
          apellido: string;
          email: string;
          rol: AppRole;
          activo?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          nombre?: string;
          apellido?: string;
          email?: string;
          rol?: AppRole;
          activo?: boolean;
          updated_at?: string;
        };
        Relationships: [];
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      is_admin: {
        Args: Record<PropertyKey, never>;
        Returns: boolean;
      };
      is_active_user: {
        Args: Record<PropertyKey, never>;
        Returns: boolean;
      };
    };
    Enums: {
      app_role: AppRole;
    };
    CompositeTypes: {
      [_ in never]: never;
    };
  };
};
