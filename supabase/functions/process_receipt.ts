// process_receipt.ts - Supabase Edge Function
// Approves a receipt and creates cashback entry

import { serve } from 'https://deno.land/std@0.201.0/http/server.ts';
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js/+esm';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

serve(async (req: Request) => {
  try {
    if (req.method !== 'POST') return new Response('Method Not Allowed', { status: 405 });
    const body = await req.json();
    const receiptId = body.receipt_id as string | undefined;
    if (!receiptId) return new Response('Missing receipt_id', { status: 400 });

    // Fetch receipt
    const { data: receipt, error: rErr } = await supabase.from('receipts').select('*').eq('id', receiptId).single();
    if (rErr) return new Response(JSON.stringify({ error: rErr.message }), { status: 404 });
    if (!receipt) return new Response('Receipt not found', { status: 404 });

    if (receipt.status === 'approved') return new Response(JSON.stringify({ ok: true, message: 'Already approved' }), { status: 200 });

    // Cashback calculation: placeholder rule - 10% cashback for supermarket, configurable by metadata
    const rate = receipt.metadata?.cashback_rate ?? 0.1;
    const cashbackValue = Number(receipt.total_value) * Number(rate);

    // Insert cashback and update receipt in a transaction
    const { error: insErr } = await supabase.from('cashbacks').insert([
      {
        user_id: receipt.user_id,
        source: 'receipt_scan',
        amount: cashbackValue,
        status: 'released',
        metadata: { receipt_id: receipt.id }
      }
    ]);
    if (insErr) return new Response(JSON.stringify({ error: insErr.message }), { status: 500 });

    const { error: updErr } = await supabase.from('receipts').update({ status: 'approved', cashback_value: cashbackValue }).eq('id', receiptId);
    if (updErr) return new Response(JSON.stringify({ error: updErr.message }), { status: 500 });

    return new Response(JSON.stringify({ ok: true, cashback: cashbackValue }), { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ error: (err as Error).message }), { status: 500 });
  }
});
