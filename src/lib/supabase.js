import { createClient } from '@supabase/supabase-js'
import { ENV } from './constants'

if (!ENV.supabase.url || !ENV.supabase.anonKey) {
  throw new Error(
    'Missing Supabase environment variables. Copy .env.example to .env and fill in your project values.',
  )
}

export const supabase = createClient(ENV.supabase.url, ENV.supabase.anonKey)
