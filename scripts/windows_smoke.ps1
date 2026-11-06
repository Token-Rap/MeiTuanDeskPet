$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path 'build/windows/x64/runner/Release/meituan_desk_pet.exe').Path
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class PetNative {
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
