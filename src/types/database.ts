export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      clients: {
        Row: {
          baja_at: string | null
          baja_foto_path: string | null
          baja_motivo: string | null
          baja_por: string | null
          cod: string
          created_at: string
          direccion: string
          estado: Database["public"]["Enums"]["client_status"]
          fecha_ultima_compra: string | null
          heladera_foto_path: string | null
          id: number
          localidad: string
          nombre: string
          rubro: string
          telefono: string | null
          tiene_heladera: boolean
          updated_at: string
          zone_id: number
        }
        Insert: {
          baja_at?: string | null
          baja_foto_path?: string | null
          baja_motivo?: string | null
          baja_por?: string | null
          cod: string
          created_at?: string
          direccion: string
          estado?: Database["public"]["Enums"]["client_status"]
          fecha_ultima_compra?: string | null
          heladera_foto_path?: string | null
          id?: never
          localidad: string
          nombre: string
          rubro: string
          telefono?: string | null
          tiene_heladera?: boolean
          updated_at?: string
          zone_id: number
        }
        Update: {
          baja_at?: string | null
          baja_foto_path?: string | null
          baja_motivo?: string | null
          baja_por?: string | null
          cod?: string
          created_at?: string
          direccion?: string
          estado?: Database["public"]["Enums"]["client_status"]
          fecha_ultima_compra?: string | null
          heladera_foto_path?: string | null
          id?: never
          localidad?: string
          nombre?: string
          rubro?: string
          telefono?: string | null
          tiene_heladera?: boolean
          updated_at?: string
          zone_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "clients_baja_por_fkey"
            columns: ["baja_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "clients_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          cantidad: number
          cantidad_bonificada: number
          created_at: string
          descuento_porcentaje: number | null
          id: number
          order_id: number
          precio_unitario: number
          presentation_codigo_snapshot: string
          presentation_id: number
          presentation_nombre_snapshot: string
          product_codigo_snapshot: string
          product_nombre_snapshot: string
          promotion_benefit_type_snapshot:
            | Database["public"]["Enums"]["promotion_benefit_type"]
            | null
          promotion_id: number | null
          promotion_nombre_snapshot: string | null
          subtotal: number | null
        }
        Insert: {
          cantidad: number
          cantidad_bonificada?: number
          created_at?: string
          descuento_porcentaje?: number | null
          id?: number
          order_id: number
          precio_unitario: number
          presentation_codigo_snapshot: string
          presentation_id: number
          presentation_nombre_snapshot: string
          product_codigo_snapshot: string
          product_nombre_snapshot: string
          promotion_benefit_type_snapshot?:
            | Database["public"]["Enums"]["promotion_benefit_type"]
            | null
          promotion_id?: number | null
          promotion_nombre_snapshot?: string | null
          subtotal?: number | null
        }
        Update: {
          cantidad?: number
          cantidad_bonificada?: number
          created_at?: string
          descuento_porcentaje?: number | null
          id?: number
          order_id?: number
          precio_unitario?: number
          presentation_codigo_snapshot?: string
          presentation_id?: number
          presentation_nombre_snapshot?: string
          product_codigo_snapshot?: string
          product_nombre_snapshot?: string
          promotion_benefit_type_snapshot?:
            | Database["public"]["Enums"]["promotion_benefit_type"]
            | null
          promotion_id?: number | null
          promotion_nombre_snapshot?: string | null
          subtotal?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_presentation_id_fkey"
            columns: ["presentation_id"]
            isOneToOne: false
            referencedRelation: "product_presentations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_promotion_id_fkey"
            columns: ["promotion_id"]
            isOneToOne: false
            referencedRelation: "promotions"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          alerta_precio: boolean
          client_id: number
          created_at: string
          entregado_at: string | null
          estado: Database["public"]["Enums"]["order_status"]
          fecha_entrega: string | null
          fecha_liberacion: string | null
          fecha_pedido: string
          id: number
          motivo_rechazo: string | null
          observaciones: string | null
          rechazado_at: string | null
          rechazado_por: string | null
          seller_id: string
          updated_at: string
        }
        Insert: {
          alerta_precio?: boolean
          client_id: number
          created_at?: string
          entregado_at?: string | null
          estado?: Database["public"]["Enums"]["order_status"]
          fecha_entrega?: string | null
          fecha_liberacion?: string | null
          fecha_pedido?: string
          id?: number
          motivo_rechazo?: string | null
          observaciones?: string | null
          rechazado_at?: string | null
          rechazado_por?: string | null
          seller_id: string
          updated_at?: string
        }
        Update: {
          alerta_precio?: boolean
          client_id?: number
          created_at?: string
          entregado_at?: string | null
          estado?: Database["public"]["Enums"]["order_status"]
          fecha_entrega?: string | null
          fecha_liberacion?: string | null
          fecha_pedido?: string
          id?: number
          motivo_rechazo?: string | null
          observaciones?: string | null
          rechazado_at?: string | null
          rechazado_por?: string | null
          seller_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_rechazado_por_fkey"
            columns: ["rechazado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      product_presentations: {
        Row: {
          activa: boolean
          codigo: string
          created_at: string
          id: number
          nombre: string
          product_id: number
          unidades: number
          updated_at: string
        }
        Insert: {
          activa?: boolean
          codigo: string
          created_at?: string
          id?: never
          nombre: string
          product_id: number
          unidades?: number
          updated_at?: string
        }
        Update: {
          activa?: boolean
          codigo?: string
          created_at?: string
          id?: never
          nombre?: string
          product_id?: number
          unidades?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "product_presentations_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      product_prices: {
        Row: {
          creado_por: string
          created_at: string
          id: number
          precio: number
          presentation_id: number
          vigente_desde: string
          vigente_hasta: string | null
        }
        Insert: {
          creado_por: string
          created_at?: string
          id?: never
          precio: number
          presentation_id: number
          vigente_desde?: string
          vigente_hasta?: string | null
        }
        Update: {
          creado_por?: string
          created_at?: string
          id?: never
          precio?: number
          presentation_id?: number
          vigente_desde?: string
          vigente_hasta?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "product_prices_creado_por_fkey"
            columns: ["creado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "product_prices_presentation_id_fkey"
            columns: ["presentation_id"]
            isOneToOne: false
            referencedRelation: "product_presentations"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          activo: boolean
          codigo: string
          created_at: string
          disponible_central: boolean
          id: number
          nombre: string
          updated_at: string
        }
        Insert: {
          activo?: boolean
          codigo: string
          created_at?: string
          disponible_central?: boolean
          id?: never
          nombre: string
          updated_at?: string
        }
        Update: {
          activo?: boolean
          codigo?: string
          created_at?: string
          disponible_central?: boolean
          id?: never
          nombre?: string
          updated_at?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          activo: boolean
          apellido: string
          created_at: string
          email: string
          id: string
          nombre: string
          rol: Database["public"]["Enums"]["app_role"]
          updated_at: string
        }
        Insert: {
          activo?: boolean
          apellido: string
          created_at?: string
          email: string
          id: string
          nombre: string
          rol: Database["public"]["Enums"]["app_role"]
          updated_at?: string
        }
        Update: {
          activo?: boolean
          apellido?: string
          created_at?: string
          email?: string
          id?: string
          nombre?: string
          rol?: Database["public"]["Enums"]["app_role"]
          updated_at?: string
        }
        Relationships: []
      }
      promotion_benefits: {
        Row: {
          cantidad_bonificada: number | null
          created_at: string
          descuento_porcentaje: number | null
          id: number
          precio_especial: number | null
          presentation_id: number
          promotion_id: number
          tipo: Database["public"]["Enums"]["promotion_benefit_type"]
        }
        Insert: {
          cantidad_bonificada?: number | null
          created_at?: string
          descuento_porcentaje?: number | null
          id?: never
          precio_especial?: number | null
          presentation_id: number
          promotion_id: number
          tipo: Database["public"]["Enums"]["promotion_benefit_type"]
        }
        Update: {
          cantidad_bonificada?: number | null
          created_at?: string
          descuento_porcentaje?: number | null
          id?: never
          precio_especial?: number | null
          presentation_id?: number
          promotion_id?: number
          tipo?: Database["public"]["Enums"]["promotion_benefit_type"]
        }
        Relationships: [
          {
            foreignKeyName: "promotion_benefits_presentation_id_fkey"
            columns: ["presentation_id"]
            isOneToOne: false
            referencedRelation: "product_presentations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "promotion_benefits_promotion_id_fkey"
            columns: ["promotion_id"]
            isOneToOne: false
            referencedRelation: "promotions"
            referencedColumns: ["id"]
          },
        ]
      }
      promotion_conditions: {
        Row: {
          cantidad_minima: number
          created_at: string
          id: number
          presentation_id: number
          promotion_id: number
        }
        Insert: {
          cantidad_minima: number
          created_at?: string
          id?: never
          presentation_id: number
          promotion_id: number
        }
        Update: {
          cantidad_minima?: number
          created_at?: string
          id?: never
          presentation_id?: number
          promotion_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "promotion_conditions_presentation_id_fkey"
            columns: ["presentation_id"]
            isOneToOne: false
            referencedRelation: "product_presentations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "promotion_conditions_promotion_id_fkey"
            columns: ["promotion_id"]
            isOneToOne: false
            referencedRelation: "promotions"
            referencedColumns: ["id"]
          },
        ]
      }
      promotions: {
        Row: {
          activa: boolean
          creado_por: string
          created_at: string
          descripcion: string | null
          id: number
          nombre: string
          updated_at: string
          vigente_desde: string
          vigente_hasta: string | null
        }
        Insert: {
          activa?: boolean
          creado_por: string
          created_at?: string
          descripcion?: string | null
          id?: never
          nombre: string
          updated_at?: string
          vigente_desde?: string
          vigente_hasta?: string | null
        }
        Update: {
          activa?: boolean
          creado_por?: string
          created_at?: string
          descripcion?: string | null
          id?: never
          nombre?: string
          updated_at?: string
          vigente_desde?: string
          vigente_hasta?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "promotions_creado_por_fkey"
            columns: ["creado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      user_assignments: {
        Row: {
          creado_por: string
          created_at: string
          desde: string
          hasta: string | null
          id: number
          subordinado_id: string
          superior_id: string
          tipo: Database["public"]["Enums"]["assignment_type"]
        }
        Insert: {
          creado_por: string
          created_at?: string
          desde?: string
          hasta?: string | null
          id?: never
          subordinado_id: string
          superior_id: string
          tipo: Database["public"]["Enums"]["assignment_type"]
        }
        Update: {
          creado_por?: string
          created_at?: string
          desde?: string
          hasta?: string | null
          id?: never
          subordinado_id?: string
          superior_id?: string
          tipo?: Database["public"]["Enums"]["assignment_type"]
        }
        Relationships: [
          {
            foreignKeyName: "user_assignments_creado_por_fkey"
            columns: ["creado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_assignments_subordinado_id_fkey"
            columns: ["subordinado_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_assignments_superior_id_fkey"
            columns: ["superior_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      zones: {
        Row: {
          activa: boolean
          codigo: string
          created_at: string
          id: number
          nombre: string
          updated_at: string
        }
        Insert: {
          activa?: boolean
          codigo: string
          created_at?: string
          id?: never
          nombre: string
          updated_at?: string
        }
        Update: {
          activa?: boolean
          codigo?: string
          created_at?: string
          id?: never
          nombre?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      effective_assignment: {
        Args: { p_fecha?: string; p_subordinado_id: string }
        Returns: {
          assignment_id: number
          desde: string
          hasta: string
          subordinado_id: string
          superior_id: string
          tipo: Database["public"]["Enums"]["assignment_type"]
        }[]
      }
      is_active_user: { Args: never; Returns: boolean }
      is_admin: { Args: never; Returns: boolean }
    }
    Enums: {
      app_role:
        | "ADMIN"
        | "COMERCIAL"
        | "SUPERVISOR"
        | "VENDEDOR"
        | "MONITOR"
        | "REPARTIDOR"
        | "DEPOSITO"
      assignment_type: "PERMANENTE" | "TEMPORAL"
      client_status: "ACTIVO" | "BAJA"
      order_status:
        | "BORRADOR"
        | "ALERTA"
        | "PENDIENTE"
        | "GUARDADO"
        | "ATENDIDO"
        | "RECHAZADO"
        | "ENTREGADO"
      promotion_benefit_type:
        | "PRECIO_ESPECIAL"
        | "DESCUENTO_PORCENTAJE"
        | "BONIFICACION"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: [
        "ADMIN",
        "COMERCIAL",
        "SUPERVISOR",
        "VENDEDOR",
        "MONITOR",
        "REPARTIDOR",
        "DEPOSITO",
      ],
      assignment_type: ["PERMANENTE", "TEMPORAL"],
      client_status: ["ACTIVO", "BAJA"],
      order_status: [
        "BORRADOR",
        "ALERTA",
        "PENDIENTE",
        "GUARDADO",
        "ATENDIDO",
        "RECHAZADO",
        "ENTREGADO",
      ],
      promotion_benefit_type: [
        "PRECIO_ESPECIAL",
        "DESCUENTO_PORCENTAJE",
        "BONIFICACION",
      ],
    },
  },
} as const
