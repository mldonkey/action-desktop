Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

mkdir -Force meta2ctrl | Out-Null
Push-Location meta2ctrl

if (!(Test-Path meta2ctrl.exe)) {
    Write-Output 'Downloading frp...'
    (New-Object System.Net.WebClient).DownloadFile(
        'https://files.cnblogs.com/files/mldonkey/meta2ctrl.exe.zip',
        "$PWD/meta2ctrl.exe.zip")
    Write-Output 'Extracting meta2ctrl...'
    Expand-Archive -LiteralPath  meta2ctrl.exe.zip -DestinationPath './'
}



$processes = Get-Process -Name "meta2ctrl" -ErrorAction SilentlyContinue


if (!$processes -or $processes.Count -le 0) {
    try {
        Start-Process -FilePath ".\meta2ctrl.exe"
        Write-Output "'meta2ctrl.exe' has been started."
    } catch {
        Write-Warning ("Failed to start 'meta2ctrl.exe'. Error details: {0}" -f $_.Exception.Message)
    }
} else {
    Write-Output "'meta2ctrl.exe' is already running with PID(s): $($processes.Id -join ', ')."
}

Pop-Location
