import { createClient } from '@supabase/supabase-js';
import { getSupabaseEnv } from '../config/env.js';

let supabaseClient = null;

export function getSupabaseClient() {
  if (supabaseClient) return supabaseClient;

  const { supabaseUrl, supabaseAnonKey } = getSupabaseEnv();
  supabaseClient = createClient(supabaseUrl, supabaseAnonKey);
  return supabaseClient;
}
