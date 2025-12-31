# Cashback+

Production-ready scaffolding for Cashback Hub (Flutter + Supabase)

Structure:
- app_flutter/: Flutter app
- supabase/: DB migrations, Edge Functions, seed

IMPORTANT
 - Do not commit `SUPABASE_SERVICE_ROLE_KEY` or other secrets.
 - Use Supabase project dashboard to apply `supabase/migrations/001_init.sql`.
 
Deploy steps (high level):
1. Create Supabase project.
2. Apply `supabase/migrations/001_init.sql` via SQL editor or CLI.
3. Provision Edge Functions from `supabase/functions` (adapt to Deno deploy usage or Supabase CLI).
4. Set env vars for Edge Functions: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
5. Configure Flutter `lib/core/constants/env.dart` with `SUPABASE_URL` and `SUPABASE_ANON_KEY` for client usage.

CI / Production deploy (recommended)
1. Add the following repository secrets in GitHub: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_PROJECT_REF`, `SUPABASE_ANON_KEY`.
2. Use the GitHub Action workflow at `supabase/.github/workflows/deploy.yml` to push DB migrations and deploy Edge Functions.
3. For local deploy using `supabase` CLI, install `npm i -g supabase` and run:

```bash
# login using service role key and push migrations
supabase login --service-role <SERVICE_ROLE_KEY>
supabase db push --project-ref <PROJECT_REF>
supabase functions deploy resgatar --project-ref <PROJECT_REF>
supabase functions deploy transfer --project-ref <PROJECT_REF>
supabase functions deploy process_receipt --project-ref <PROJECT_REF>
```

Security notes:
- Never store service role keys in source. Use CI secrets or a secure vault.
- For receipts storage, create a `receipts` bucket and set appropriate RLS/storage policies; prefer signed URLs for downloads in production.


Deploy steps (high level):
1. Create Supabase project.
2. Apply `supabase/migrations/001_init.sql` via SQL editor or CLI.
3. Provision Edge Functions from `supabase/functions` (adapt to Deno deploy usage or Supabase CLI).
4. Set env vars for Edge Functions: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.
5. Configure Flutter `lib/core/constants/env.dart` with `SUPABASE_URL` and `SUPABASE_ANON_KEY` for client usage.

Security notes:
- RLS policies defined to ensure users can access only their data.
- Use Edge Functions with Service Role Key for privileged operations.

Next steps suggestions:
- Implement OTP/email-based sign-up flow using Supabase Auth.
- Integrate real partners for adiantamento (advance) and payouts.
- Harden RPC `transfer_cashback` and add rate-limits and audit hooks.
