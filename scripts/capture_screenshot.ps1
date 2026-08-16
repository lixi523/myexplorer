$ErrorActionPreference = 'Stop'
$exe = 'D:\Documents\VS Code\MyExplorer-main\build\windows\x64\runner\Release\MyExplorer.exe'
$outDir = 'D:\Documents\VS Code\MyExplorer-main\docs\screenshots'

$proc = Start-Process -FilePath $exe -PassThru
try {
  $hwnd = [IntPtr]::Zero
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500
    $proc.Refresh()
    if ($proc.HasExited) { throw "MyExplorer exited early with code $($proc.ExitCode)" }
    $hwnd = $proc.MainWindowHandle
    if ($hwnd -ne [IntPtr]::Zero) { break }
  }
  if ($hwnd -eq [IntPtr]::Zero) { throw 'No main window within 20s' }
  Start-Sleep -Seconds 3

  Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Win32Cap {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
'@
  [Win32Cap]::SetForegroundWindow($hwnd) | Out-Null
  Start-Sleep -Seconds 2

  $rect = New-Object Win32Cap+RECT
  [Win32Cap]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
  $w = $rect.R - $rect.L
  $h = $rect.B - $rect.T
  if ($w -le 0 -or $h -le 0) { throw "Bad window rect ${w}x${h}" }

  Add-Type -AssemblyName System.Drawing
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $dc = $g.GetHdc()
  [Win32Cap]::PrintWindow($hwnd, $dc, 2) | Out-Null
  $g.ReleaseHdc($dc)
  $g.Dispose()

  if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
  $file = Join-Path $outDir 'hero.png'
  $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output "SAVED $file ${w}x${h}"
} finally {
  if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
}