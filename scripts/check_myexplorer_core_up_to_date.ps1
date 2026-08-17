# Verifies the vendored myexplorer_core.dll matches the locally built one.
# Exits 0 when nothing was built locally (e.g. a fresh CI checkout) or when the
# vendored dll is current; exits 1 with instructions when a Rust build exists
# but was not copied into third_party/myexplorer_core/windows/.
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $PSScriptRoot
$built = Join-Path $here "rust\myexplorer_core\target\release\myexplorer_core.dll"
$vendored = Join-Path $here "third_party\myexplorer_core\windows\myexplorer_core.dll"

if (-not (Test-Path $built)) {
  Write-Host "no local myexplorer_core build; nothing to check"
  exit 0
}

if (-not (Test-Path $vendored)) {
  Write-Host "ERROR: vendored myexplorer_core.dll is missing: $vendored"
  exit 1
}

$builtHash = (Get-FileHash $built -Algorithm SHA256).Hash
$vendoredHash = (Get-FileHash $vendored -Algorithm SHA256).Hash

if ($builtHash -ne $vendoredHash) {
  Write-Host "ERROR: vendored myexplorer_core.dll is out of date."
  Write-Host "Run: scripts\build_myexplorer_core_windows.ps1"
  exit 1
}

Write-Host "vendored myexplorer_core.dll is up to date"