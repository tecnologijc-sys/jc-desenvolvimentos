// resgatar.ts - Supabase Edge Function (Deno/TypeScript)
// Redeem (resgatar) workflow: checks user's released balance and creates an external withdrawal record

import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  global: { headers: { 'x-edge-runtime': '1' } }
});

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });

    const authHeader = req.headers.get('authorization');
    if (!authHeader) return new Response('Unauthorized', { status: 401 });

    // Validate JWT to get user id
    const jwt = authHeader.replace('Bearer ', '');
    const { data: jwtData, error: jwtErr } = await supabase.auth.getUser(jwt);
    if (jwtErr || !jwtData?.user) return new Response('Invalid token', { status: 401 });

    const uid = jwtData.user.id;
    const body = await req.json();
    const amount = Number(body.amount ?? 0);
    const external_meta = body.external_meta ?? null;

    if (!amount || amount <= 0) return new Response('Invalid amount', { status: 400 });

    // Calculate released balance
    const { data: balanceRows, error: balanceErr } = await supabase.rpc('refresh_user_cashback_balance');
    // We call materialized view directly
    const { data, error } = await supabase
      .from('user_cashback_balance')
      .select('released')
      .eq('user_id', uid)
      .limit(1)
      .single();

    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 500 });

    const released = Number(data?.released ?? 0);
    if (released < amount) return new Response(JSON.stringify({ error: 'Insufficient released balance' }), { status: 400 });

    // Atomic operation: insert a debit cashback (ledger entry) and create a transfer to external
    const tx = await supabase.rpc('transfer_cashback', {
      p_from: uid,
      p_to: null,
      p_amount: amount
    });

    // NOTE: transfer_cashback expects p_to uuid; for external withdrawals we record transfer with to_user = null
    // If RPC cannot accept null, create entries manually.

    if (tx.error) {
      // fallback: manual insertion transaction
      const { error: insErr } = await supabase.from('cashbacks').insert([
        { user_id: uid, source: 'withdrawal', amount: -amount, status: 'advanced', metadata: { external: true, external_meta } }
      ]);
      if (insErr) return new Response(JSON.stringify({ error: insErr.message }), { status: 500 });
      const { error: trErr } = await supabase.from('transfers').insert([{ from_user: uid, to_user: null, amount }]);
      if (trErr) return new Response(JSON.stringify({ error: trErr.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: (err as Error).message }), { status: 500 });
  }
});
