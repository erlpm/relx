#! /usr/bin/pwsh
# Test build, install, start, ping, stop, uninstall of powershell_release
$release = "powershell_release"

# Terminate on error
$ErrorActionPreference = "Stop"

# CD to script location (shelltests)
Set-Location $PSScriptRoot

# Clean all builds (continue on error)
"*** Clean"
Get-ChildItem -Path . -Filter _build -Recurse | ForEach-Object {
    "Remove $($_.FullName).."
    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
""

# Create temporary build folder for epm
"*** Build epm"
$epm_dir = "$PSScriptRoot\$(([System.Guid]::NewGuid()).Guid)"
mkdir $epm_dir | Out-Null

# Clone latest epm and build with relx as a checkout
Push-Location $epm_dir
& git clone "https://github.com/erlpm/epm" .
mkdir _checkouts | Out-Null
New-Item -ItemType SymbolicLink -Path "_checkouts\relx" -Target "$PSScriptRoot\..\..\relx" | Out-Null
(Get-Content epm.config) -replace 'relx(.*)build/default/lib/', 'relx$1checkouts' | Set-Content epm.config -Encoding ASCII
cmd /c bootstrap.bat
Pop-Location
""

# Function to run epm
function Epm() {
    & escript.exe "$epm_dir\epm" @args
    if ($LASTEXITCODE -ne 0) {
        Write-Error "epm ${args} exited with status $LASTEXITCODE"
    }
}

# Our release source
Set-Location ".\$release\"

"*** Build release"
Epm release
""

"*** Rebuild dev release (test for symlink issues)"
Epm as dev release
Epm as dev release
""

# Go to release
Set-Location "_build\default\rel\$release\bin"

"*** Install service"
& ".\$release.ps1" install
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to install service"
}
""

"*** Start service"
& ".\$release.ps1" start
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to start service"
}
""

"*** Ping service"
& ".\$release.ps1" ping
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to ping service"
}
""

"*** Stop service"
& ".\$release.ps1" stop
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to stop service"
}
""

"*** Uninstall service"
& ".\$release.ps1" uninstall
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to uninstall service"
}
""
