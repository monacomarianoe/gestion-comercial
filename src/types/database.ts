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

export const CLIENT_STATUSES = ["ACTIVO", "BAJA"] as const;
export type ClientStatus = (typeof CLIENT_STATUSES)[number];

export const PROMOTION_BENEFIT_TYPES = [
  "PRECIO_ESPECIAL",
  "DESCUENTO_PORCENTAJE",
  "BONIFICACION",
] as const;

export type PromotionBenefitType =
  (typeof PROMOTION_BENEFIT_TYPES)[number];

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

export type Zone = {
  id: number;
  codigo: string;
  nombre: string;
  activa: boolean;
  created_at: string;
  updated_at: string;
};

export type Client = {
  id: number;
  cod: string;
  nombre: string;
  rubro: string;
  direccion: string;
  localidad: string;
  telefono: string | null;
  zone_id: number;
  estado: ClientStatus;
  tiene_heladera: boolean;
  heladera_foto_path: string | null;
  fecha_ultima_compra: string | null;
  created_at: string;
  updated_at: string;
  baja_motivo: string | null;
  baja_foto_path: string | null;
  baja_at: string | null;
  baja_por: string | null;
};

export type Product = {
  id: number;
  codigo: string;
  nombre: string;
  activo: boolean;
  disponible_central: boolean;
  created_at: string;
  updated_at: string;
};

export type ProductPresentation = {
  id: number;
  product_id: number;
  codigo: string;
  nombre: string;
  unidades: number;
  activa: boolean;
  created_at: string;
  updated_at: string;
};

export type ProductPrice = {
  id: number;
  presentation_id: number;
  precio: number;
  vigente_desde: string;
  vigente_hasta: string | null;
  creado_por: string;
  created_at: string;
};

export type Promotion = {
  id: number;
  nombre: string;
  descripcion: string | null;
  vigente_desde: string;
  vigente_hasta: string | null;
  activa: boolean;
  creado_por: string;
  created_at: string;
  updated_at: string;
};

export type PromotionCondition = {
  id: number;
  promotion_id: number;
  presentation_id: number;
  cantidad_minima: number;
  created_at: string;
};

export type PromotionBenefit = {
  id: number;
  promotion_id: number;
  tipo: PromotionBenefitType;
  presentation_id: number;
  precio_especial: number | null;
  descuento_porcentaje: number | null;
  cantidad_bonificada: number | null;
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

      zones: {
        Row: Zone;
        Insert: {
          id?: number;
          codigo: string;
          nombre: string;
          activa?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          codigo?: string;
          nombre?: string;
          activa?: boolean;
          updated_at?: string;
        };
        Relationships: [];
      };

      clients: {
        Row: Client;
        Insert: {
          id?: number;
          cod: string;
          nombre: string;
          rubro: string;
          direccion: string;
          localidad: string;
          telefono?: string | null;
          zone_id: number;
          estado?: ClientStatus;
          tiene_heladera?: boolean;
          heladera_foto_path?: string | null;
          fecha_ultima_compra?: string | null;
          created_at?: string;
          updated_at?: string;
          baja_motivo?: string | null;
          baja_foto_path?: string | null;
          baja_at?: string | null;
          baja_por?: string | null;
        };
        Update: {
          cod?: string;
          nombre?: string;
          rubro?: string;
          direccion?: string;
          localidad?: string;
          telefono?: string | null;
          zone_id?: number;
          estado?: ClientStatus;
          tiene_heladera?: boolean;
          heladera_foto_path?: string | null;
          fecha_ultima_compra?: string | null;
          updated_at?: string;
          baja_motivo?: string | null;
          baja_foto_path?: string | null;
          baja_at?: string | null;
          baja_por?: string | null;
        };
        Relationships: [];
      };

      products: {
        Row: Product;
        Insert: {
          id?: number;
          codigo: string;
          nombre: string;
          activo?: boolean;
          disponible_central?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          codigo?: string;
          nombre?: string;
          activo?: boolean;
          disponible_central?: boolean;
          updated_at?: string;
        };
        Relationships: [];
      };

      product_presentations: {
        Row: ProductPresentation;
        Insert: {
          id?: number;
          product_id: number;
          codigo: string;
          nombre: string;
          unidades?: number;
          activa?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          product_id?: number;
          codigo?: string;
          nombre?: string;
          unidades?: number;
          activa?: boolean;
          updated_at?: string;
        };
        Relationships: [];
      };

      product_prices: {
        Row: ProductPrice;
        Insert: {
          id?: number;
          presentation_id: number;
          precio: number;
          vigente_desde?: string;
          vigente_hasta?: string | null;
          creado_por: string;
          created_at?: string;
        };
        Update: {
          presentation_id?: number;
          precio?: number;
          vigente_desde?: string;
          vigente_hasta?: string | null;
          creado_por?: string;
        };
        Relationships: [];
      };

      promotions: {
        Row: Promotion;
        Insert: {
          id?: number;
          nombre: string;
          descripcion?: string | null;
          vigente_desde?: string;
          vigente_hasta?: string | null;
          activa?: boolean;
          creado_por: string;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          nombre?: string;
          descripcion?: string | null;
          vigente_desde?: string;
          vigente_hasta?: string | null;
          activa?: boolean;
          creado_por?: string;
          updated_at?: string;
        };
        Relationships: [];
      };

      promotion_conditions: {
        Row: PromotionCondition;
        Insert: {
          id?: number;
          promotion_id: number;
          presentation_id: number;
          cantidad_minima: number;
          created_at?: string;
        };
        Update: {
          promotion_id?: number;
          presentation_id?: number;
          cantidad_minima?: number;
        };
        Relationships: [];
      };

      promotion_benefits: {
        Row: PromotionBenefit;
        Insert: {
          id?: number;
          promotion_id: number;
          tipo: PromotionBenefitType;
          presentation_id: number;
          precio_especial?: number | null;
          descuento_porcentaje?: number | null;
          cantidad_bonificada?: number | null;
          created_at?: string;
        };
        Update: {
          promotion_id?: number;
          tipo?: PromotionBenefitType;
          presentation_id?: number;
          precio_especial?: number | null;
          descuento_porcentaje?: number | null;
          cantidad_bonificada?: number | null;
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
      client_status: ClientStatus;
      promotion_benefit_type: PromotionBenefitType;
    };

    CompositeTypes: {
      [_ in never]: never;
    };
  };
};