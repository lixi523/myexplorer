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
if ($LASTEXITCODE -ne 0) { throw "cargo build failed with exit code $LASTEXITCODE" }

$out = Join-Path $crate "target\release\myexplorer_core.dll"
Copy-Item -Force $out (Join-Path $dest "myexplorer_core.dll")
Write-Host "vendored: $dest\myexplorer_core.dll"

# --- pdfium (PDF preview) ---
$pdfiumZip = Join-Path $here ".cowork-temp\pdfium.tgz"
New-Item -ItemType Directory -Force -Path (Split-Path $pdfiumZip) | Out-Null

if (-not (Test-Path (Join-Path $dest "pdfium.dll"))) {
  Write-Host "downloading pdfium..."
  # Pin to a specific version to avoid supply chain risks from mutable 'latest' tag.
  # Version format: chromium/<build> (e.g., chromium/8021).
  $pdfiumVersion = "chromium/8021"
  $pdfiumUrl = "https://github.com/bblanchon/pdfium-binaries/releases/download/$pdfiumVersion/pdfium-win-x64.tgz"

  # 已知的 SHA256 校验值（pdfium-win-x64.tgz，chromium/8021 版本）
  $expectedHash = "ADAC8CE034015427B5DAA81F8EEDDFCC8E84BC2A9F036F007890FF18BD4388C4"

  Invoke-WebRequest -Uri $pdfiumUrl -OutFile $pdfiumZip -UseBasicParsing

  # 校验下载文件的完整性，防范供应链攻击
  $actualHash = (Get-FileHash -Path $pdfiumZip -Algorithm SHA256).Hash
  if ($actualHash -ne $expectedHash) {
    Remove-Item -Force $pdfiumZip
    throw "SHA256 mismatch for pdfium.tgz!`nExpected: $expectedHash`nActual:   $actualHash"
  }
  Write-Host "SHA256 verified: $actualHash"

  tar xzf $pdfiumZip -C (Split-Path $pdfiumZip)
  if ($LASTEXITCODE -ne 0) { throw "tar extraction failed with exit code $LASTEXITCODE" }
  $pdfiumDll = Get-ChildItem (Split-Path $pdfiumZip) -Recurse -Filter pdfium.dll | Select-Object -First 1
  Copy-Item -Force $pdfiumDll.FullName (Join-Path $dest "pdfium.dll")
  Write-Host "vendored: $dest\pdfium.dll"
}
