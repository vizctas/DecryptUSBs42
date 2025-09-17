# Extract a provided Lua zip and run tests
$zip = 'C:\Users\joshg\Downloads\lua-5.1.5_Win32_dll17_lib.zip'
$out = Join-Path $env:TEMP 'lua_from_user'

Write-Output "Using zip: $zip"
if (-not (Test-Path $zip)) {
    Write-Error "ZIP not found: $zip"
    exit 10
}

if (Test-Path $out) { Remove-Item -Recurse -Force $out -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $out | Out-Null

try {
    Expand-Archive -Path $zip -DestinationPath $out -Force -ErrorAction Stop
} catch {
    Write-Error "Extraction failed: $_"
    exit 2
}

$exe = Get-ChildItem -Path $out -Recurse -Include 'lua.exe','lua51.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    Write-Error "No lua.exe found inside the zip"
    exit 3
}

$exePath = $exe.FullName
Write-Output "Found lua executable: $exePath"

Write-Output '--- Version ---'
& $exePath -v 2>&1 | ForEach-Object { Write-Output $_ }

Write-Output '--- Running context_menu_test.lua ---'
& $exePath 'Scripts\tests\context_menu_test.lua' 2>&1 | ForEach-Object { Write-Output $_ }

Write-Output '--- Running elite_system_test.lua ---'
& $exePath 'Scripts\tests\elite_system_test.lua' 2>&1 | ForEach-Object { Write-Output $_ }
