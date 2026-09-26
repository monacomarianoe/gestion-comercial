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

export const ASSIGNMENT_TYPES = ["PERMANENTE", "TEMPORAL"] as const;

export type AssignmentType = (typeof ASSIGNMENT_TYPES)[number];

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

export type UserAssignment = {
  id: number;
  superior_id: string;
  subordinado_id: string;
  tipo: AssignmentType;
  desde: string;
  hasta: string | null;
  creado_por: string;
  created_at: string;
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

      user_assignments: {
        Row: UserAssignment;
        Insert: {
          id?: number;
          superior_id: string;
          subordinado_id: string;
          tipo: AssignmentType;
          desde?: string;
          hasta?: string | null;
          creado_por: string;
          created_at?: string;
        };
        Update: {
          superior_id?: string;
          subordinado_id?: string;
          tipo?: AssignmentType;
          desde?: string;
          hasta?: string | null;
          creado_por?: string;
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

      effective_assignment: {
        Args: {
          p_subordinado_id: string;
          p_fecha?: string;
        };
        Returns: {
          assignment_id: number;
          superior_id: string;
          subordinado_id: string;
          tipo: AssignmentType;
          desde: string;
          hasta: string | null;
        }[];
      };
    };

    Enums: {
      app_role: AppRole;
      assignment_type: AssignmentType;
    };

    CompositeTypes: {
      [_ in never]: never;
    };
  };
};