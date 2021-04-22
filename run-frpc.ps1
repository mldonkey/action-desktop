Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

Write-Output "Setting the $env:USERNAME user password..."
Get-LocalUser $env:USERNAME `
    | Set-LocalUser `
        -Password (
            ConvertTo-SecureString `
                -AsPlainText `
                -Force `
                $env:RUNNER_PASSWORD
        )
        
Write-Output 'Running frpc...'
./frp/frpc -c frpc-windows.ini 2>&1 | Select-Object {$_ -replace '[0-9\.]+:6969','***:6969'}; cmd /c exit 0
