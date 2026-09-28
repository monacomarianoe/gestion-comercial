import { isAppRole } from "@/lib/auth/roles";
import { createClient } from "@/lib/supabase/server";
import type { Database } from "@/types/database";

type Profile = Database["public"]["Tables"]["profiles"]["Row"];

export type SessionProfile = {
  userId: string | null;
  profile: Profile | null;
};

export async function getCurrentProfile(): Promise<SessionProfile> {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.getClaims();

  if (error || !data?.claims?.sub || typeof data.claims.sub !== "string") {
    return { userId: null, profile: null };
  }

  const userId = data.claims.sub;
  const { data: profile } = await supabase
    .from("profiles")
    .select(
      "id, nombre, apellido, email, rol, activo, created_at, updated_at",
    )
    .eq("id", userId)
    .maybeSingle();

  if (!profile || !isAppRole(profile.rol)) {
    return { userId, profile: null };
  }

  return { userId, profile };
}
