$scriptPath = "./"
$MaxThreads = 5  # 设置最大并发数

# 创建 RunspacePool
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()

$Jobs = @()

# 创建输出流对象
$outputStream = New-Object System.Collections.ArrayList

# $sripts=Get-ChildItem -Path $scriptPath -Filter "*.ps1"
$scripts=@('./run-frpc.ps1','./install-meta2ctrl.ps1','./shurufa.ps1','./install-pac.ps1')

# 获取所有 PS1 文件
$scripts | ForEach-Object {
    $scriptName = $_.Name
    
    # 创建包装脚本块
    $ScriptBlock = {
        param($scriptPath, $scriptName)
        
        try {
            # 使用 Write-Host 进行实时输出
            Write-Host "[$scriptName] 开始执行"
            
            # 执行实际的脚本
            & $scriptPath | ForEach-Object {
                Write-Host "[$scriptName] $_"
            }
            
            Write-Host "[$scriptName] 执行完成"
        }
        catch {
            Write-Host "[$scriptName] 错误: $_" -ForegroundColor Red
        }
    }
    
    $PowerShell = [powershell]::Create().AddScript($ScriptBlock)
    $PowerShell.RunspacePool = $RunspacePool
    
    # 添加参数
    [void]$PowerShell.AddArgument($_.FullName)
    [void]$PowerShell.AddArgument($scriptName)
    
    # 设置输出流
    $PowerShell.Streams.Debug.add_DataAdded({
        param($sender, $e)
        Write-Host $sender[$e.Index]
    })
    $PowerShell.Streams.Verbose.add_DataAdded({
        param($sender, $e)
        Write-Host $sender[$e.Index]
    })
    $PowerShell.Streams.Information.add_DataAdded({
        param($sender, $e)
        Write-Host $sender[$e.Index]
    })
    $PowerShell.Streams.Error.add_DataAdded({
        param($sender, $e)
        Write-Host $sender[$e.Index] -ForegroundColor Red
    })
    
    $AsyncResult = $PowerShell.BeginInvoke()
    
    $Jobs += @{
        PowerShell = $PowerShell
        AsyncResult = $AsyncResult
        Script = $scriptName
    }
}

# 等待所有作业完成
try {
    $running = $true
    while ($running) {
        $running = $false
        foreach ($Job in $Jobs) {
            if (-not $Job.AsyncResult.IsCompleted) {
                $running = $true
                break
            }
        }
        Start-Sleep -Milliseconds 100
    }
}
finally {
    # 清理资源
    foreach ($Job in $Jobs) {
        try {
            $Job.PowerShell.EndInvoke($Job.AsyncResult)
        }
        catch {}
        finally {
            $Job.PowerShell.Dispose()
        }
    }
    $RunspacePool.Close()
    $RunspacePool.Dispose()
}