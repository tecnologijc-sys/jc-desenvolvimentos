import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { type NextRequest, NextResponse } from 'next/server'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY

export const createClient = (request: NextRequest) => {
  // Create an initial NextResponse to attach any set-cookie changes
  let supabaseResponse = NextResponse.next({ request: { headers: request.headers } })

  const supabase = createServerClient(supabaseUrl!, supabaseKey!, {
    cookies: {
      getAll() {
        return request.cookies.getAll()
      },
      setAll(cookiesToSet: Array<{ name: string; value: string; options?: CookieOptions }>) {
        // Attempt to set cookies on the incoming request (may be no-op in some runtimes)
        try {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
        } catch (err) {
          // ignore: setting cookies on the request may not be supported
        }

        // Ensure response has the cookies to send back to client
        supabaseResponse = NextResponse.next({ request: { headers: request.headers } })
        cookiesToSet.forEach(({ name, value, options }) => {
          supabaseResponse.cookies.set(name, value, options as any)
        })
      },
    },
  })

  return { supabase, supabaseResponse }
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)']
}
