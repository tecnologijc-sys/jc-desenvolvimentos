// transfer.ts - Supabase Edge Function (Deno/TypeScript)
// Internal transfer between users using RPC `transfer_cashback`

import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });
    const authHeader = req.headers.get('authorization');
    if (!authHeader) return new Response('Unauthorized', { status: 401 });
    const jwt = authHeader.replace('Bearer ', '');
    const { data: jwtData, error: jwtErr } = await supabase.auth.getUser(jwt);
    if (jwtErr || !jwtData?.user) return new Response('Invalid token', { status: 401 });
    const from = jwtData.user.id;
    const body = await req.json();
    const to = body.to_user as string | null;
    const amount = Number(body.amount ?? 0);
    if (!to) return new Response('Missing to_user', { status: 400 });
    if (!amount || amount <= 0) return new Response('Invalid amount', { status: 400 });

    // Call RPC transfer_cashback
    const { data, error } = await supabase.rpc('transfer_cashback', { p_from: from, p_to: to, p_amount: amount });
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 });
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: (err as Error).message }), { status: 500 });
  }
});
