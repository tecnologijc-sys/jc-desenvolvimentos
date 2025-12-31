-- 001_init.sql
-- Schema for Cashback+ production

-- Enable extensions
create extension if not exists "pgcrypto";

-- Profiles
create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text unique not null,
  avatar_url text,
  created_at timestamptz default now()
);

-- Cashbacks
create table if not exists cashbacks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  source text not null,
  amount numeric(12,2) not null check (amount >= 0),
  status text not null default 'pending', -- pending | released | advanced
  metadata jsonb,
  created_at timestamptz default now()
);
create index if not exists idx_cashbacks_user_id on cashbacks(user_id);
create index if not exists idx_cashbacks_status on cashbacks(status);

-- Receipts (notas fiscais)
create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  image_url text not null,
  store text,
  total_value numeric(12,2) not null check (total_value >= 0),
  cashback_value numeric(12,2) not null default 0 check (cashback_value >= 0),
  status text not null default 'processing', -- processing | approved | rejected
  metadata jsonb,
  created_at timestamptz default now()
);
create index if not exists idx_receipts_user_id on receipts(user_id);
create index if not exists idx_receipts_status on receipts(status);

-- Transfers (internal transfers between users)
create table if not exists transfers (
  id uuid primary key default gen_random_uuid(),
  from_user uuid references profiles(id) on delete set null,
  to_user uuid references profiles(id) on delete set null,
  amount numeric(12,2) not null check (amount > 0),
  note text,
  created_at timestamptz default now()
);
create index if not exists idx_transfers_from_user on transfers(from_user);
create index if not exists idx_transfers_to_user on transfers(to_user);

-- Materialized view for aggregated balance per user (available, pending, advanced)
create materialized view if not exists user_cashback_balance as
select
  user_id,
  coalesce(sum(case when status = 'released' then amount end),0) as released,
  coalesce(sum(case when status = 'pending' then amount end),0) as pending,
  coalesce(sum(case when status = 'advanced' then amount end),0) as advanced,
  coalesce(sum(amount),0) as total
from cashbacks
group by user_id;

create index if not exists idx_user_cashback_balance_user on user_cashback_balance(user_id);

-- Functions to refresh materialized view (can be called by CRON or Edge function)
create or replace function refresh_user_cashback_balance() returns void language plpgsql as $$
begin
  refresh materialized view user_cashback_balance;
end;
$$;

-- Secure transfer function (atomic): debits from sender and credits receiver
create or replace function transfer_cashback(p_from uuid, p_to uuid, p_amount numeric) returns void language plpgsql as $$
declare
  v_released numeric;
begin
  if p_amount <= 0 then
    raise exception 'amount must be positive';
  end if;

  select coalesce(sum(amount),0) into v_released from cashbacks where user_id = p_from and status = 'released';
  if v_released < p_amount then
    raise exception 'insufficient released balance';
  end if;

  -- advisory lock on sender to avoid races
  perform pg_advisory_xact_lock( ('x'||replace(p_from::text,'-',''))::bigint );

  -- Insert immutable ledger entries: debit sender
  insert into cashbacks (user_id, source, amount, status, metadata)
  values (p_from, 'transfer-debit', -p_amount, 'advanced', jsonb_build_object('to', p_to));

  -- If destination is internal user, credit them
  if p_to is not null then
    insert into cashbacks (user_id, source, amount, status, metadata)
    values (p_to, 'transfer-credit', p_amount, 'released', jsonb_build_object('from', p_from));
  end if;

  -- Record transfer (to_user may be null for external withdrawals)
  insert into transfers (from_user, to_user, amount)
  values (p_from, p_to, p_amount);
end;
$$;

-- RLS: enable row level security on sensitive tables
alter table profiles enable row level security;
alter table cashbacks enable row level security;
alter table receipts enable row level security;
alter table transfers enable row level security;

-- Policies: users can select/insert/update their own rows; service_role (supabase service key) has full access

-- Profiles
create policy "Profiles: user can select own profile" on profiles for select using (auth.uid() = id);
create policy "Profiles: user can insert own profile" on profiles for insert with check (auth.uid() = id);
create policy "Profiles: user can update own profile" on profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- Cashbacks
create policy "Cashbacks: user sees own cashbacks" on cashbacks for select using (auth.uid() = user_id);
create policy "Cashbacks: user inserts own cashback" on cashbacks for insert with check (auth.uid() = user_id);
create policy "Cashbacks: user updates own cashback status by system" on cashbacks for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Receipts
create policy "Receipts: user sees own receipts" on receipts for select using (auth.uid() = user_id);
create policy "Receipts: user inserts own receipts" on receipts for insert with check (auth.uid() = user_id);
create policy "Receipts: user updates own receipts" on receipts for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Transfers
create policy "Transfers: user sees transfers involving them" on transfers for select using (auth.uid() = from_user or auth.uid() = to_user);
create policy "Transfers: user inserts transfers from them" on transfers for insert with check (auth.uid() = from_user);

-- Admin / service role: allow full access via using (current_setting('jwt.claims.role', true) = 'supabase_admin') is NOT recommended.
-- Instead, rely on the Supabase Edge Functions using the Service Role key for privileged operations.

-- Audit table
create table if not exists audit_logs (
  id bigserial primary key,
  actor uuid,
  action text not null,
  resource text,
  payload jsonb,
  created_at timestamptz default now()
);

-- Create admin role helper (not granting keys, just a marker)
create table if not exists app_config (
  key text primary key,
  value text
);

-- Todos table for Next.js example (RLS enforced)
create table if not exists todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  title text not null,
  completed boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_todos_user_id on todos(user_id);

alter table todos enable row level security;

create policy "Todos: users can select their todos" on todos for select using (auth.uid() = user_id);
create policy "Todos: users can insert their todos" on todos for insert with check (auth.uid() = user_id);
create policy "Todos: users can update their todos" on todos for update using (auth.uid() = user_id) with check (auth.uid() = user_id);



-- Commit

