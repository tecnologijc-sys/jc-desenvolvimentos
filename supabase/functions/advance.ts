// advance.ts - Supabase Edge Function (Deno/TypeScript)
// Adiantamento (advance) do saldo: cobra taxa, marca como advanced e cria registro de adiantamento

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

    const uid = jwtData.user.id;
    const body = await req.json();
    const amount = Number(body.amount ?? 0);
    if (!amount || amount <= 0) return new Response('Invalid amount', { status: 400 });

    // Fee configuration: production can use DB-configured fee; default 2.5%
    const FEE_RATE = Number(Deno.env.get('ADVANCE_FEE_RATE') ?? 0.025);
    const fee = Math.round((amount * FEE_RATE + Number.EPSILON) * 100) / 100;
    const net = Math.round((amount - fee + Number.EPSILON) * 100) / 100;

    // Check released balance
    const { data: balance } = await supabase.from('user_cashback_balance').select('released').eq('user_id', uid).single();
    const released = Number(balance?.released ?? 0);
    if (released < amount) return new Response(JSON.stringify({ error: 'Insufficient released balance' }), { status: 400 });

    // Perform atomic ledger entries via RPC transfer_cashback: debit user and create transfer record to external (to_user = null)
    const { error: rpcErr } = await supabase.rpc('transfer_cashback', { p_from: uid, p_to: null, p_amount: amount });
    if (rpcErr) return new Response(JSON.stringify({ error: rpcErr.message }), { status: 500 });

    // Record adiantamento metadata (could be used to send to payout provider)
    const { error: insErr } = await supabase.from('transfers').insert([{ from_user: uid, to_user: null, amount: amount, note: JSON.stringify({ type: 'advance', fee, net }) }]);
    if (insErr) return new Response(JSON.stringify({ error: insErr.message }), { status: 500 });

    return new Response(JSON.stringify({ ok: true, requested: amount, fee, net }), { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: (err as Error).message }), { status: 500 });
  }
});
