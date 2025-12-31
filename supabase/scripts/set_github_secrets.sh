#!/usr/bin/env bash
# Usage:
# SUPABASE_SERVICE_ROLE_KEY="sb_secret_..." SUPABASE_PROJECT_REF="<proj_ref>" SUPABASE_URL="https://..." SUPABASE_ANON_KEY="sb_publishable_..." ./supabase/scripts/set_github_secrets.sh <owner/repo>

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <owner/repo>"
  exit 2
fi
REPO=$1

: "Ensure gh CLI is installed and you're authenticated (gh auth login)"

if [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  echo "Please set SUPABASE_SERVICE_ROLE_KEY in environment." >&2
  exit 2
fi

if [ -z "${SUPABASE_PROJECT_REF:-}" ]; then
  echo "Please set SUPABASE_PROJECT_REF in environment." >&2
  exit 2
fi

if [ -z "${SUPABASE_URL:-}" ]; then
  echo "Please set SUPABASE_URL in environment." >&2
  exit 2
fi

if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "Please set SUPABASE_ANON_KEY in environment." >&2
  exit 2
fi

echo "Setting GitHub secrets on $REPO..."

echo -n "$SUPABASE_SERVICE_ROLE_KEY" | gh secret set SUPABASE_SERVICE_ROLE_KEY --repo "$REPO"
echo -n "$SUPABASE_PROJECT_REF" | gh secret set SUPABASE_PROJECT_REF --repo "$REPO"
echo -n "$SUPABASE_URL" | gh secret set SUPABASE_URL --repo "$REPO"
echo -n "$SUPABASE_ANON_KEY" | gh secret set SUPABASE_ANON_KEY --repo "$REPO"

echo "Secrets set. Verify in GitHub UI: Settings → Secrets → Actions for $REPO"
