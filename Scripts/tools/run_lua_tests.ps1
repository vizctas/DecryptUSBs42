# Download a portable Lua zip, extract, find lua.exe and run tests
$dl = Join-Path $env:TEMP 'lua_portable.zip'
$out = Join-Path $env:TEMP 'lua_portable'

if (Test-Path $dl) { Remove-Item $dl -Force -ErrorAction SilentlyContinue }
if (Test-Path $out) { Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue }

$url = 'https://sourceforge.net/projects/luabinaries/files/5.1.5/Windows%20w32%20bin/lua-5.1.5_Win32_bin.zip/download'
Write-Output "Downloading $url"
try {
    Invoke-WebRequest -Uri $url -OutFile $dl -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Error "Download failed: $_"
    exit 2
}

try {
    Expand-Archive -Path $dl -DestinationPath $out -Force
} catch {
    Write-Error "Extraction failed: $_"
    exit 3
}

$exe = Get-ChildItem -Path $out -Recurse -Filter 'lua.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    Write-Error "No lua.exe found after extraction"
    exit 4
}

$exePath = $exe.FullName
Write-Output "Found lua.exe: $exePath"

Write-Output '--- Version ---'
& $exePath -v 2>&1 | ForEach-Object { Write-Output $_ }

Write-Output '--- Running context_menu_test.lua ---'
& $exePath 'Scripts\tests\context_menu_test.lua' 2>&1 | ForEach-Object { Write-Output $_ }

Write-Output '--- Running elite_system_test.lua ---'
& $exePath 'Scripts\tests\elite_system_test.lua' 2>&1 | ForEach-Object { Write-Output $_ }
