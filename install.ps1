# Bootstrapper for the cross-platform Node installer (Windows PowerShell).
# All real work lives in install.mjs — this just locates Node and runs it.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Error "Node.js (>=18) is required to run the installer. Install it from https://nodejs.org/ and re-run .\install.ps1"
  exit 1
}
node install.mjs @args
exit $LASTEXITCODE
