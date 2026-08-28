# Builds the native myexplorer_core helper (Rust, release) on Windows and
# vendors myexplorer_core.dll and pdfium.dll into third_party/myexplorer_core/windows/
# so the Windows CMake bundling step ships them next to the executable.
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $PSScriptRoot
$crate = Join-Path $here "rust\myexplorer_core"
$dest = Join-Path $here "third_party\myexplorer_core\windows"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

# --- myexplorer_core ---
$pubspec = Get-Content (Join-Path $here "pubspec.yaml")
$verLine = $pubspec | Where-Object { $_ -match '^version:' } | Select-Object -First 1
if ($verLine -match '([0-9]+\.[0-9]+\.[0-9]+)') { $env:MYEXPLORER_VERSION = $Matches[1] }

cargo build --release --manifest-path (Join-Path $crate "Cargo.toml")

$out = Join-Path $crate "target\release\myexplorer_core.dll"
Copy-Item -Force $out (Join-Path $dest "myexplorer_core.dll")
Write-Host "vendored: $dest\myexplorer_core.dll"

# --- pdfium (PDF preview) ---
$pdfiumZip = Join-Path $here ".cowork-temp\pdfium.tgz"
New-Item -ItemType Directory -Force -Path (Split-Path $pdfiumZip) | Out-Null

if (-not (Test-Path (Join-Path $dest "pdfium.dll"))) {
  Write-Host "downloading pdfium..."
  # Pin to a specific version to avoid supply chain risks from mutable 'latest' tag.
  $pdfiumVersion = "v134.0.7099.0"
  $pdfiumUrl = "https://github.com/bblanchon/pdfium-binaries/releases/download/$pdfiumVersion/pdfium-win-x64.tgz"
  Invoke-WebRequest -Uri $pdfiumUrl -OutFile $pdfiumZip -UseBasicParsing
  tar xzf $pdfiumZip -C (Split-Path $pdfiumZip)
  $pdfiumDll = Get-ChildItem (Split-Path $pdfiumZip) -Recurse -Filter pdfium.dll | Select-Object -First 1
  Copy-Item -Force $pdfiumDll.FullName (Join-Path $dest "pdfium.dll")
  Write-Host "vendored: $dest\pdfium.dll"
}
