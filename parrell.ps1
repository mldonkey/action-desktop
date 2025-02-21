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
# $scripts=@("./1.ps1","./2.ps1","./3.ps1","./4.ps1")

Write-Host "准备执行的脚本列表："
$scripts | ForEach-Object { Write-Host $_ }

# 获取所有 PS1 文件
foreach ($script in $scripts) {
    $scriptName = Split-Path $script -Leaf
    Write-Host "`n开始处理脚本: $scriptName" -ForegroundColor Cyan
    
    # 创建包装脚本块
    $ScriptBlock = {
        param($scriptPath, $scriptName)
        
        try {
            Write-Host "[$scriptName] 开始执行"
            
            # 检查文件是否存在
            if (-not (Test-Path $scriptPath)) {
                throw "找不到脚本文件: $scriptPath"
            }
            
            # 读取并执行脚本
            $scriptContent = Get-Content -Path $scriptPath -Raw
            Write-Host "[$scriptName] 已读取脚本内容，长度: $($scriptContent.Length) 字符"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            & $scriptBlock | ForEach-Object {
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
    
    # 添加参数时使用完整路径
    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($script)
    Write-Host "使用完整路径: $fullPath"
    [void]$PowerShell.AddArgument($fullPath)
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