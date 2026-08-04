# Builds the native waydir_core helper (Rust, release) on Windows and
# vendors waydir_core.dll and pdfium.dll into third_party/waydir_core/windows/
# so the Windows CMake bundling step ships them next to the executable.
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $PSScriptRoot
$crate = Join-Path $here "rust\waydir_core"
$dest = Join-Path $here "third_party\waydir_core\windows"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# --- waydir_core ---
$pubspec = Get-Content (Join-Path $here "pubspec.yaml")
$verLine = $pubspec | Where-Object { $_ -match '^version:' } | Select-Object -First 1
if ($verLine -match '([0-9]+\.[0-9]+\.[0-9]+)') { $env:WAYDIR_VERSION = $Matches[1] }

cargo build --release --manifest-path (Join-Path $crate "Cargo.toml")

$out = Join-Path $crate "target\release\waydir_core.dll"
Copy-Item -Force $out (Join-Path $dest "waydir_core.dll")
Write-Host "vendored: $dest\waydir_core.dll"

# --- pdfium (PDF preview) ---
$pdfiumZip = Join-Path $here ".cowork-temp\pdfium.tgz"
New-Item -ItemType Directory -Force -Path (Split-Path $pdfiumZip) | Out-Null

if (-not (Test-Path (Join-Path $dest "pdfium.dll"))) {
  Write-Host "downloading pdfium..."
  $pdfiumUrl = "https://github.com/bblanchon/pdfium-binaries/releases/latest/download/pdfium-win-x64.tgz"
  Invoke-WebRequest -Uri $pdfiumUrl -OutFile $pdfiumZip -UseBasicParsing
  tar xzf $pdfiumZip -C (Split-Path $pdfiumZip)
  $pdfiumDll = Get-ChildItem (Split-Path $pdfiumZip) -Recurse -Filter pdfium.dll | Select-Object -First 1
  Copy-Item -Force $pdfiumDll.FullName (Join-Path $dest "pdfium.dll")
  Write-Host "vendored: $dest\pdfium.dll"
}
