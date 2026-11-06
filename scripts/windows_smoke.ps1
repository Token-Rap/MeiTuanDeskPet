$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path 'build/windows/x64/runner/Release/meituan_desk_pet.exe').Path
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PetNative {
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
}
'@
$process = Start-Process $exe -PassThru
try {
  Start-Sleep -Seconds 8
  $process.Refresh()
  if ($process.HasExited) { throw 'App exited before tray startup' }
  $window = $process.MainWindowHandle
  if ($window -eq [IntPtr]::Zero) { throw 'App did not create a desktop window' }
  $iconPath = Join-Path (Split-Path $exe) 'data/flutter_assets/assets/icons/meituan.ico'
  foreach ($kind in @(0, 1)) {
    $handle = [PetNative]::SendMessage($window, 0x007F, [IntPtr]$kind, [IntPtr]::Zero)
    if ($handle -eq [IntPtr]::Zero) { throw "Missing live window icon $kind" }
    $actual = [Drawing.Icon]::FromHandle($handle).ToBitmap()
    $expectedIcon = [Drawing.Icon]::new($iconPath, $actual.Width, $actual.Height)
    $expected = $expectedIcon.ToBitmap()
    $different = 0
    for ($y = 0; $y -lt $actual.Height; $y++) {
      for ($x = 0; $x -lt $actual.Width; $x++) {
        $a = $actual.GetPixel($x, $y)
        $b = $expected.GetPixel($x, $y)
        if ($a.A -eq 0 -and $b.A -eq 0) { continue }
        $distance = [Math]::Abs([int]$a.R - $b.R) + [Math]::Abs([int]$a.G - $b.G) + [Math]::Abs([int]$a.B - $b.B)
        if ($distance -gt 12 -or [Math]::Abs([int]$a.A - $b.A) -gt 16) { $different++ }
      }
    }
    $area = $actual.Width * $actual.Height
    $actual.Dispose(); $expected.Dispose(); $expectedIcon.Dispose()
    if ($different -gt $area * 0.05) { throw "Live icon $kind does not match the dual-cat icon" }
  }
  Write-Output 'Both live window icons match the packaged dual-cat icon.'
  # Closing the pet should hide it to the tray, rather than end the app.
  [PetNative]::PostMessage($window, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
  Start-Sleep -Seconds 2
  $process.Refresh()
  if ($process.HasExited) { throw 'Close unexpectedly terminated tray app' }
  $second = Start-Process $exe -PassThru
  if (-not $second.WaitForExit(5000)) { Stop-Process -Id $second.Id -Force; throw 'Duplicate instance remained running' }
  $process.Refresh()
  if ($process.MainWindowHandle -eq [IntPtr]::Zero) { throw 'Second launch did not restore existing window' }
  Write-Output 'Windows startup, close-to-tray and single-instance smoke passed.'
} finally {
  if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
}
