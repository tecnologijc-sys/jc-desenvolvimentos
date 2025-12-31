"use client"
import { createBrowserClient } from '@supabase/ssr'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY

// Client factory for browser usage. Use this in client components.
export const createClient = () => createBrowserClient(supabaseUrl!, supabaseKey!)
