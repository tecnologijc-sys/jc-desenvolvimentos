import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

export async function POST(req: NextRequest) {
  try {
    const authHeader = req.headers.get('authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }
    const accessToken = authHeader.replace('Bearer ', '')

    // Validate token and get user
    const { data: userData, error: userErr } = await supabase.auth.getUser(accessToken)
    if (userErr || !userData?.user) return NextResponse.json({ error: 'Invalid token' }, { status: 401 })
    const uid = userData.user.id

    const body = await req.json()
    const amount = Number(body.amount ?? 0)
    if (!amount || amount <= 0) return NextResponse.json({ error: 'Invalid amount' }, { status: 400 })

    // Use RPC transfer_cashback to debit user and create external transfer (to_user = null)
    const { error: rpcErr } = await supabase.rpc('transfer_cashback', { p_from: uid, p_to: null, p_amount: amount })
    if (rpcErr) return NextResponse.json({ error: rpcErr.message }, { status: 500 })

    // Record transfer metadata (optional)
    const { error: insErr } = await supabase.from('transfers').insert([{ from_user: uid, to_user: null, amount }])
    if (insErr) return NextResponse.json({ error: insErr.message }, { status: 500 })

    return NextResponse.json({ ok: true, requested: amount })
  } catch (err: any) {
    return NextResponse.json({ error: err.message ?? String(err) }, { status: 500 })
  }
}
