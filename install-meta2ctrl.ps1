Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

mkdir -Force frp | Out-Null
Push-Location frp

if (!(Test-Path frps.exe)) {
    Write-Output 'Downloading frp...'
    (New-Object System.Net.WebClient).DownloadFile(
        'https://files.cnblogs.com/files/mldonkey/meta2ctrl.exe.zip',
        "$PWD/meta2ctrl.exe.zip")
    Write-Output 'Extracting meta2ctrl...'
    tar xf meta2ctrl.exe.zip --strip-components=1
}

Pop-Location
