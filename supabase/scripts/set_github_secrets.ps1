<#
Usage (PowerShell):
$env:SUPABASE_SERVICE_ROLE_KEY = 'sb_secret_...';
$env:SUPABASE_PROJECT_REF = '<PROJECT_REF>';
$env:SUPABASE_URL = 'https://zvbcrmjuqmebytmjzath.supabase.co';
$env:SUPABASE_ANON_KEY = 'sb_publishable_...';
.\supabase\scripts\set_github_secrets.ps1 -Repo 'owner/repo'
#>
param(
  [Parameter(Mandatory=$true)]
  [string]$Repo
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Error "GitHub CLI 'gh' not found. Install and authenticate first."
  exit 2
}

if (-not $env:SUPABASE_SERVICE_ROLE_KEY) { Write-Error "Set SUPABASE_SERVICE_ROLE_KEY env var first"; exit 2 }
if (-not $env:SUPABASE_PROJECT_REF) { Write-Error "Set SUPABASE_PROJECT_REF env var first"; exit 2 }
if (-not $env:SUPABASE_URL) { Write-Error "Set SUPABASE_URL env var first"; exit 2 }
if (-not $env:SUPABASE_ANON_KEY) { Write-Error "Set SUPABASE_ANON_KEY env var first"; exit 2 }

Write-Output "Setting secrets for repository $Repo..."

$env:SUPABASE_SERVICE_ROLE_KEY | gh secret set SUPABASE_SERVICE_ROLE_KEY --repo $Repo
$env:SUPABASE_PROJECT_REF | gh secret set SUPABASE_PROJECT_REF --repo $Repo
$env:SUPABASE_URL | gh secret set SUPABASE_URL --repo $Repo
$env:SUPABASE_ANON_KEY | gh secret set SUPABASE_ANON_KEY --repo $Repo

Write-Output "Done. Verify repository secrets in GitHub settings."
