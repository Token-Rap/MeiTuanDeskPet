param([Parameter(Mandatory=$true)][int]$ExpectedBuild)
$ErrorActionPreference = 'Stop'
$oldBuild = $ExpectedBuild - 1
flutter build windows --release --dart-define=UPDATE_CHANNEL=preview --build-name 0.2.0 --build-number $oldBuild
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare lower-build updater client' }
$target = Join-Path $env:RUNNER_TEMP 'meituan-upgrade-smoke'
New-Item -ItemType Directory -Force $target | Out-Null
Copy-Item 'build/windows/x64/runner/Release/*' $target -Recurse -Force
$exe = Join-Path $target 'meituan_desk_pet.exe'
$process = Start-Process $exe -PassThru
$passed = $false
try {
  # The app must discover the release, download/verify it, run setup and restart.
  for ($attempt = 0; $attempt -lt 60; $attempt++) {
    Start-Sleep -Seconds 3
    $version = [Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
    $running = Get-Process meituan_desk_pet -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
    if ($version.FilePrivatePart -eq $ExpectedBuild -and $running) {
      $passed = $true
      break
    }
  }
  if (-not $passed) { throw 'Automatic GitHub download/install/restart did not finish within 180 seconds' }
  Write-Output "Verified automatic upgrade from build $oldBuild to $ExpectedBuild with application restart."
} finally {
  Get-Process meituan_desk_pet -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe } | Stop-Process -Force
  Get-ChildItem $env:TEMP -Directory -Filter 'meituan-update-*' -ErrorAction SilentlyContinue | ForEach-Object {
    Get-ChildItem $_.FullName -Filter '*.log' -ErrorAction SilentlyContinue | Get-Content -Tail 20
  }
}
