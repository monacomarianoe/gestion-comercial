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
      delivery_sheet_orders: {
        Row: {
          activo: boolean
          created_at: string
          delivery_sheet_id: number
          id: number
          incident_id: number | null
          motivo_retiro: string | null
          numero_remito: string
          orden_ruta: number
          order_id: number
          retirado_at: string | null
          retirado_por: string | null
        }
        Insert: {
          activo?: boolean
          created_at?: string
          delivery_sheet_id: number
          id?: never
          incident_id?: number | null
          motivo_retiro?: string | null
          numero_remito: string
          orden_ruta: number
          order_id: number
          retirado_at?: string | null
          retirado_por?: string | null
        }
        Update: {
          activo?: boolean
          created_at?: string
          delivery_sheet_id?: number
          id?: never
          incident_id?: number | null
          motivo_retiro?: string | null
          numero_remito?: string
          orden_ruta?: number
          order_id?: number
          retirado_at?: string | null
          retirado_por?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "delivery_sheet_orders_delivery_sheet_id_fkey"
            columns: ["delivery_sheet_id"]
            isOneToOne: false
            referencedRelation: "delivery_sheets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "delivery_sheet_orders_incident_id_fkey"
            columns: ["incident_id"]
            isOneToOne: false
            referencedRelation: "incidents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "delivery_sheet_orders_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "delivery_sheet_orders_retirado_por_fkey"
            columns: ["retirado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      delivery_sheets: {
        Row: {
          armada_at: string | null
          asignada_at: string | null
          cerrada_at: string | null
          created_at: string
          estado: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha: string
          id: number
          inicio_reparto_at: string | null
          monitor_id: string
          numero_salida: number
          observaciones: string | null
          repartidor_id: string | null
          updated_at: string
          vehicle_id: number | null
        }
        Insert: {
          armada_at?: string | null
          asignada_at?: string | null
          cerrada_at?: string | null
          created_at?: string
          estado?: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha?: string
          id?: never
          inicio_reparto_at?: string | null
          monitor_id: string
          numero_salida?: number
          observaciones?: string | null
          repartidor_id?: string | null
          updated_at?: string
          vehicle_id?: number | null
        }
        Update: {
          armada_at?: string | null
          asignada_at?: string | null
          cerrada_at?: string | null
          created_at?: string
          estado?: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha?: string
          id?: never
          inicio_reparto_at?: string | null
          monitor_id?: string
          numero_salida?: number
          observaciones?: string | null
          repartidor_id?: string | null
          updated_at?: string
          vehicle_id?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "delivery_sheets_monitor_id_fkey"
            columns: ["monitor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "delivery_sheets_repartidor_id_fkey"
            columns: ["repartidor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "delivery_sheets_vehicle_id_fkey"
            columns: ["vehicle_id"]
            isOneToOne: false
            referencedRelation: "vehicles"
            referencedColumns: ["id"]
          },
        ]
      }
      incident_history: {
        Row: {
          accion: string
          area_anterior: Database["public"]["Enums"]["incident_area"] | null
          area_nueva: Database["public"]["Enums"]["incident_area"] | null
          created_at: string
          detalle: string | null
          estado_anterior: Database["public"]["Enums"]["incident_status"] | null
          estado_nuevo: Database["public"]["Enums"]["incident_status"] | null
          id: number
          incident_id: number
          realizado_por: string
        }
        Insert: {
          accion: string
          area_anterior?: Database["public"]["Enums"]["incident_area"] | null
          area_nueva?: Database["public"]["Enums"]["incident_area"] | null
          created_at?: string
          detalle?: string | null
          estado_anterior?:
            | Database["public"]["Enums"]["incident_status"]
            | null
          estado_nuevo?: Database["public"]["Enums"]["incident_status"] | null
          id?: number
          incident_id: number
          realizado_por: string
        }
        Update: {
          accion?: string
          area_anterior?: Database["public"]["Enums"]["incident_area"] | null
          area_nueva?: Database["public"]["Enums"]["incident_area"] | null
          created_at?: string
          detalle?: string | null
          estado_anterior?:
            | Database["public"]["Enums"]["incident_status"]
            | null
          estado_nuevo?: Database["public"]["Enums"]["incident_status"] | null
          id?: number
          incident_id?: number
          realizado_por?: string
        }
        Relationships: [
          {
            foreignKeyName: "incident_history_incident_id_fkey"
            columns: ["incident_id"]
            isOneToOne: false
            referencedRelation: "incidents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incident_history_realizado_por_fkey"
            columns: ["realizado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      incidents: {
        Row: {
          accepted_at: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at: string | null
          creada_por: string
          created_at: string
          delivery_sheet_id: number | null
          detalle: string
          estado: Database["public"]["Enums"]["incident_status"]
          id: number
          motivo_rechazo: string | null
          order_id: number | null
          resolucion: string | null
          resolved_at: string | null
          responsable_usuario_id: string | null
          tipo: string
          updated_at: string
        }
        Insert: {
          accepted_at?: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at?: string | null
          creada_por: string
          created_at?: string
          delivery_sheet_id?: number | null
          detalle: string
          estado?: Database["public"]["Enums"]["incident_status"]
          id?: number
          motivo_rechazo?: string | null
          order_id?: number | null
          resolucion?: string | null
          resolved_at?: string | null
          responsable_usuario_id?: string | null
          tipo: string
          updated_at?: string
        }
        Update: {
          accepted_at?: string | null
          area_origen?: Database["public"]["Enums"]["incident_area"]
          area_responsable?: Database["public"]["Enums"]["incident_area"]
          closed_at?: string | null
          creada_por?: string
          created_at?: string
          delivery_sheet_id?: number | null
          detalle?: string
          estado?: Database["public"]["Enums"]["incident_status"]
          id?: number
          motivo_rechazo?: string | null
          order_id?: number | null
          resolucion?: string | null
          resolved_at?: string | null
          responsable_usuario_id?: string | null
          tipo?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "incidents_creada_por_fkey"
            columns: ["creada_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incidents_delivery_sheet_id_fkey"
            columns: ["delivery_sheet_id"]
            isOneToOne: false
            referencedRelation: "delivery_sheets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incidents_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "incidents_responsable_usuario_id_fkey"
            columns: ["responsable_usuario_id"]
            isOneToOne: false
            referencedRelation: "profiles"
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
          numero_remito: string | null
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
          numero_remito?: string | null
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
          numero_remito?: string | null
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
      seller_daily_routes: {
        Row: {
          creado_por: string
          created_at: string
          fecha: string
          id: number
          seller_id: string
          zone_id: number
        }
        Insert: {
          creado_por: string
          created_at?: string
          fecha: string
          id?: never
          seller_id: string
          zone_id: number
        }
        Update: {
          creado_por?: string
          created_at?: string
          fecha?: string
          id?: never
          seller_id?: string
          zone_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "seller_daily_routes_creado_por_fkey"
            columns: ["creado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "seller_daily_routes_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "seller_daily_routes_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      supervisor_visits: {
        Row: {
          cerrado_at: string | null
          client_id: number
          creado_por: string
          created_at: string
          detalle_cierre: string | null
          estado: Database["public"]["Enums"]["supervisor_visit_status"]
          fecha_programada: string
          hora_programada: string | null
          id: number
          iniciado_at: string | null
          objetivo: string
          order_id: number | null
          origen: Database["public"]["Enums"]["supervisor_visit_origin"]
          parent_visit_id: number | null
          proxima_accion: string | null
          proxima_fecha: string | null
          requiere_incidencia_comercial: boolean
          resultado:
            | Database["public"]["Enums"]["supervisor_visit_result"]
            | null
          supervisor_id: string
          updated_at: string
        }
        Insert: {
          cerrado_at?: string | null
          client_id: number
          creado_por: string
          created_at?: string
          detalle_cierre?: string | null
          estado?: Database["public"]["Enums"]["supervisor_visit_status"]
          fecha_programada: string
          hora_programada?: string | null
          id?: never
          iniciado_at?: string | null
          objetivo: string
          order_id?: number | null
          origen: Database["public"]["Enums"]["supervisor_visit_origin"]
          parent_visit_id?: number | null
          proxima_accion?: string | null
          proxima_fecha?: string | null
          requiere_incidencia_comercial?: boolean
          resultado?:
            | Database["public"]["Enums"]["supervisor_visit_result"]
            | null
          supervisor_id: string
          updated_at?: string
        }
        Update: {
          cerrado_at?: string | null
          client_id?: number
          creado_por?: string
          created_at?: string
          detalle_cierre?: string | null
          estado?: Database["public"]["Enums"]["supervisor_visit_status"]
          fecha_programada?: string
          hora_programada?: string | null
          id?: never
          iniciado_at?: string | null
          objetivo?: string
          order_id?: number | null
          origen?: Database["public"]["Enums"]["supervisor_visit_origin"]
          parent_visit_id?: number | null
          proxima_accion?: string | null
          proxima_fecha?: string | null
          requiere_incidencia_comercial?: boolean
          resultado?:
            | Database["public"]["Enums"]["supervisor_visit_result"]
            | null
          supervisor_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "supervisor_visits_client_id_fkey"
            columns: ["client_id"]
            isOneToOne: false
            referencedRelation: "clients"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supervisor_visits_creado_por_fkey"
            columns: ["creado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supervisor_visits_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supervisor_visits_parent_visit_id_fkey"
            columns: ["parent_visit_id"]
            isOneToOne: false
            referencedRelation: "supervisor_visits"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supervisor_visits_supervisor_id_fkey"
            columns: ["supervisor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      supervisor_workday_criticalities: {
        Row: {
          criticidad: Database["public"]["Enums"]["client_criticality"]
          workday_id: number
        }
        Insert: {
          criticidad: Database["public"]["Enums"]["client_criticality"]
          workday_id: number
        }
        Update: {
          criticidad?: Database["public"]["Enums"]["client_criticality"]
          workday_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "supervisor_workday_criticalities_workday_id_fkey"
            columns: ["workday_id"]
            isOneToOne: false
            referencedRelation: "supervisor_workdays"
            referencedColumns: ["id"]
          },
        ]
      }
      supervisor_workday_zones: {
        Row: {
          workday_id: number
          zone_id: number
        }
        Insert: {
          workday_id: number
          zone_id: number
        }
        Update: {
          workday_id?: number
          zone_id?: number
        }
        Relationships: [
          {
            foreignKeyName: "supervisor_workday_zones_workday_id_fkey"
            columns: ["workday_id"]
            isOneToOne: false
            referencedRelation: "supervisor_workdays"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supervisor_workday_zones_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      supervisor_workdays: {
        Row: {
          accompanied_seller_id: string | null
          cierre_lat: number | null
          cierre_lng: number | null
          cierre_ruta_at: string | null
          creado_por: string
          created_at: string
          fecha: string
          id: number
          inicio_lat: number | null
          inicio_lng: number | null
          inicio_ruta_at: string | null
          modo: Database["public"]["Enums"]["supervisor_work_mode"]
          supervisor_id: string
        }
        Insert: {
          accompanied_seller_id?: string | null
          cierre_lat?: number | null
          cierre_lng?: number | null
          cierre_ruta_at?: string | null
          creado_por: string
          created_at?: string
          fecha: string
          id?: never
          inicio_lat?: number | null
          inicio_lng?: number | null
          inicio_ruta_at?: string | null
          modo: Database["public"]["Enums"]["supervisor_work_mode"]
          supervisor_id: string
        }
        Update: {
          accompanied_seller_id?: string | null
          cierre_lat?: number | null
          cierre_lng?: number | null
          cierre_ruta_at?: string | null
          creado_por?: string
          created_at?: string
          fecha?: string
          id?: never
          inicio_lat?: number | null
          inicio_lng?: number | null
          inicio_ruta_at?: string | null
          modo?: Database["public"]["Enums"]["supervisor_work_mode"]
          supervisor_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "supervisor_workdays_accompanied_seller_id_fkey"
            columns: ["accompanied_seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supervisor_workdays_creado_por_fkey"
            columns: ["creado_por"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "supervisor_workdays_supervisor_id_fkey"
            columns: ["supervisor_id"]
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
      vehicles: {
        Row: {
          activo: boolean
          created_at: string
          descripcion: string | null
          id: number
          patente: string
          updated_at: string
        }
        Insert: {
          activo?: boolean
          created_at?: string
          descripcion?: string | null
          id?: never
          patente: string
          updated_at?: string
        }
        Update: {
          activo?: boolean
          created_at?: string
          descripcion?: string | null
          id?: never
          patente?: string
          updated_at?: string
        }
        Relationships: []
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
      accept_delivery_sheet: {
        Args: { p_delivery_sheet_id: number }
        Returns: {
          armada_at: string | null
          asignada_at: string | null
          cerrada_at: string | null
          created_at: string
          estado: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha: string
          id: number
          inicio_reparto_at: string | null
          monitor_id: string
          numero_salida: number
          observaciones: string | null
          repartidor_id: string | null
          updated_at: string
          vehicle_id: number | null
        }
        SetofOptions: {
          from: "*"
          to: "delivery_sheets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      accept_incident: {
        Args: { p_incident_id: number }
        Returns: {
          accepted_at: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at: string | null
          creada_por: string
          created_at: string
          delivery_sheet_id: number | null
          detalle: string
          estado: Database["public"]["Enums"]["incident_status"]
          id: number
          motivo_rechazo: string | null
          order_id: number | null
          resolucion: string | null
          resolved_at: string | null
          responsable_usuario_id: string | null
          tipo: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "incidents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      add_order_to_delivery_sheet: {
        Args: {
          p_delivery_sheet_id: number
          p_orden_ruta: number
          p_order_id: number
        }
        Returns: {
          activo: boolean
          created_at: string
          delivery_sheet_id: number
          id: number
          incident_id: number | null
          motivo_retiro: string | null
          numero_remito: string
          orden_ruta: number
          order_id: number
          retirado_at: string | null
          retirado_por: string | null
        }
        SetofOptions: {
          from: "*"
          to: "delivery_sheet_orders"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      assign_delivery_sheet: {
        Args: { p_delivery_sheet_id: number }
        Returns: {
          armada_at: string | null
          asignada_at: string | null
          cerrada_at: string | null
          created_at: string
          estado: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha: string
          id: number
          inicio_reparto_at: string | null
          monitor_id: string
          numero_salida: number
          observaciones: string | null
          repartidor_id: string | null
          updated_at: string
          vehicle_id: number | null
        }
        SetofOptions: {
          from: "*"
          to: "delivery_sheets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      can_act_on_incident: { Args: { p_incident_id: number }; Returns: boolean }
      can_act_on_incident_area: {
        Args: { p_area: Database["public"]["Enums"]["incident_area"] }
        Returns: boolean
      }
      can_view_profile_in_structure: {
        Args: { p_fecha?: string; p_profile_id: string; p_viewer_id: string }
        Returns: boolean
      }
      client_current_criticality: {
        Args: { p_client_id: number; p_fecha?: string }
        Returns: Database["public"]["Enums"]["client_criticality"]
      }
      client_days_without_purchase: {
        Args: { p_client_id: number; p_fecha?: string }
        Returns: number
      }
      client_last_purchase: { Args: { p_client_id: number }; Returns: string }
      close_delivery_sheet: {
        Args: { p_delivery_sheet_id: number }
        Returns: {
          armada_at: string | null
          asignada_at: string | null
          cerrada_at: string | null
          created_at: string
          estado: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha: string
          id: number
          inicio_reparto_at: string | null
          monitor_id: string
          numero_salida: number
          observaciones: string | null
          repartidor_id: string | null
          updated_at: string
          vehicle_id: number | null
        }
        SetofOptions: {
          from: "*"
          to: "delivery_sheets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      close_incident: {
        Args: { p_incident_id: number }
        Returns: {
          accepted_at: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at: string | null
          creada_por: string
          created_at: string
          delivery_sheet_id: number | null
          detalle: string
          estado: Database["public"]["Enums"]["incident_status"]
          id: number
          motivo_rechazo: string | null
          order_id: number | null
          resolucion: string | null
          resolved_at: string | null
          responsable_usuario_id: string | null
          tipo: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "incidents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      close_supervisor_route: {
        Args: { p_lat?: number; p_lng?: number; p_workday_id: number }
        Returns: {
          accompanied_seller_id: string | null
          cierre_lat: number | null
          cierre_lng: number | null
          cierre_ruta_at: string | null
          creado_por: string
          created_at: string
          fecha: string
          id: number
          inicio_lat: number | null
          inicio_lng: number | null
          inicio_ruta_at: string | null
          modo: Database["public"]["Enums"]["supervisor_work_mode"]
          supervisor_id: string
        }
        SetofOptions: {
          from: "*"
          to: "supervisor_workdays"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_incident: {
        Args: {
          p_area_origen: Database["public"]["Enums"]["incident_area"]
          p_area_responsable: Database["public"]["Enums"]["incident_area"]
          p_delivery_sheet_id?: number
          p_detalle: string
          p_order_id?: number
          p_tipo: string
        }
        Returns: {
          accepted_at: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at: string | null
          creada_por: string
          created_at: string
          delivery_sheet_id: number | null
          detalle: string
          estado: Database["public"]["Enums"]["incident_status"]
          id: number
          motivo_rechazo: string | null
          order_id: number | null
          resolucion: string | null
          resolved_at: string | null
          responsable_usuario_id: string | null
          tipo: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "incidents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      derive_incident_to_commercial: {
        Args: { p_detalle: string; p_incident_id: number }
        Returns: {
          accepted_at: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at: string | null
          creada_por: string
          created_at: string
          delivery_sheet_id: number | null
          detalle: string
          estado: Database["public"]["Enums"]["incident_status"]
          id: number
          motivo_rechazo: string | null
          order_id: number | null
          resolucion: string | null
          resolved_at: string | null
          responsable_usuario_id: string | null
          tipo: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "incidents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
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
      finalize_delivery_sheet: {
        Args: { p_delivery_sheet_id: number }
        Returns: {
          armada_at: string | null
          asignada_at: string | null
          cerrada_at: string | null
          created_at: string
          estado: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha: string
          id: number
          inicio_reparto_at: string | null
          monitor_id: string
          numero_salida: number
          observaciones: string | null
          repartidor_id: string | null
          updated_at: string
          vehicle_id: number | null
        }
        SetofOptions: {
          from: "*"
          to: "delivery_sheets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      is_active_user: { Args: never; Returns: boolean }
      is_admin: { Args: never; Returns: boolean }
      is_effective_commercial_of_seller: {
        Args: { p_commercial_id: string; p_fecha?: string; p_seller_id: string }
        Returns: boolean
      }
      is_effective_commercial_of_supervisor: {
        Args: {
          p_commercial_id: string
          p_fecha?: string
          p_supervisor_id: string
        }
        Returns: boolean
      }
      is_effective_supervisor_of_seller: {
        Args: { p_fecha?: string; p_seller_id: string; p_supervisor_id: string }
        Returns: boolean
      }
      reject_incident: {
        Args: { p_incident_id: number; p_motivo: string }
        Returns: {
          accepted_at: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at: string | null
          creada_por: string
          created_at: string
          delivery_sheet_id: number | null
          detalle: string
          estado: Database["public"]["Enums"]["incident_status"]
          id: number
          motivo_rechazo: string | null
          order_id: number | null
          resolucion: string | null
          resolved_at: string | null
          responsable_usuario_id: string | null
          tipo: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "incidents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      resolve_incident: {
        Args: { p_incident_id: number; p_resolucion: string }
        Returns: {
          accepted_at: string | null
          area_origen: Database["public"]["Enums"]["incident_area"]
          area_responsable: Database["public"]["Enums"]["incident_area"]
          closed_at: string | null
          creada_por: string
          created_at: string
          delivery_sheet_id: number | null
          detalle: string
          estado: Database["public"]["Enums"]["incident_status"]
          id: number
          motivo_rechazo: string | null
          order_id: number | null
          resolucion: string | null
          resolved_at: string | null
          responsable_usuario_id: string | null
          tipo: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "incidents"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      start_delivery_route: {
        Args: { p_delivery_sheet_id: number }
        Returns: {
          armada_at: string | null
          asignada_at: string | null
          cerrada_at: string | null
          created_at: string
          estado: Database["public"]["Enums"]["delivery_sheet_status"]
          fecha: string
          id: number
          inicio_reparto_at: string | null
          monitor_id: string
          numero_salida: number
          observaciones: string | null
          repartidor_id: string | null
          updated_at: string
          vehicle_id: number | null
        }
        SetofOptions: {
          from: "*"
          to: "delivery_sheets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      start_supervisor_route: {
        Args: { p_lat?: number; p_lng?: number; p_workday_id: number }
        Returns: {
          accompanied_seller_id: string | null
          cierre_lat: number | null
          cierre_lng: number | null
          cierre_ruta_at: string | null
          creado_por: string
          created_at: string
          fecha: string
          id: number
          inicio_lat: number | null
          inicio_lng: number | null
          inicio_ruta_at: string | null
          modo: Database["public"]["Enums"]["supervisor_work_mode"]
          supervisor_id: string
        }
        SetofOptions: {
          from: "*"
          to: "supervisor_workdays"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      supervisor_critical_clients: {
        Args: { p_fecha?: string; p_supervisor_id: string }
        Returns: {
          client_id: number
          cod: string
          criticidad: Database["public"]["Enums"]["client_criticality"]
          dias_sin_compra: number
          fecha_ultima_compra: string
          nombre: string
          zone_id: number
        }[]
      }
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
      client_criticality: "PRIORIDAD" | "URGENCIA" | "ACCION" | "SIN_COMPRA"
      client_status: "ACTIVO" | "BAJA"
      delivery_sheet_status:
        | "BORRADOR"
        | "ARMADA"
        | "ASIGNADA"
        | "ACEPTADA"
        | "EN_REPARTO"
        | "CERRADA"
        | "CANCELADA"
      incident_area: "MONITOR" | "COMERCIAL" | "ADMIN" | "DEPOSITO"
      incident_status:
        | "PENDIENTE"
        | "ACEPTADA"
        | "RECHAZADA"
        | "RESUELTA"
        | "CERRADA"
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
      supervisor_visit_origin:
        | "COMERCIAL"
        | "SUPERVISOR"
        | "REPROGRAMACION"
        | "SEGUIMIENTO"
      supervisor_visit_result:
        | "VENTA"
        | "RESUELTO"
        | "REPROGRAMADO"
        | "SEGUIMIENTO"
        | "DERIVADO_COMERCIAL"
      supervisor_visit_status: "PENDIENTE" | "EN_CURSO" | "CERRADA"
      supervisor_work_mode: "EN_COMPANIA" | "MODO_SUPERVISION"
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
      client_criticality: ["PRIORIDAD", "URGENCIA", "ACCION", "SIN_COMPRA"],
      client_status: ["ACTIVO", "BAJA"],
      delivery_sheet_status: [
        "BORRADOR",
        "ARMADA",
        "ASIGNADA",
        "ACEPTADA",
        "EN_REPARTO",
        "CERRADA",
        "CANCELADA",
      ],
      incident_area: ["MONITOR", "COMERCIAL", "ADMIN", "DEPOSITO"],
      incident_status: [
        "PENDIENTE",
        "ACEPTADA",
        "RECHAZADA",
        "RESUELTA",
        "CERRADA",
      ],
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
      supervisor_visit_origin: [
        "COMERCIAL",
        "SUPERVISOR",
        "REPROGRAMACION",
        "SEGUIMIENTO",
      ],
      supervisor_visit_result: [
        "VENTA",
        "RESUELTO",
        "REPROGRAMADO",
        "SEGUIMIENTO",
        "DERIVADO_COMERCIAL",
      ],
      supervisor_visit_status: ["PENDIENTE", "EN_CURSO", "CERRADA"],
      supervisor_work_mode: ["EN_COMPANIA", "MODO_SUPERVISION"],
    },
  },
} as const