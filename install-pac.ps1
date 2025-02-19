# 设置执行策略（仅限当前会话）
Set-ExecutionPolicy Bypass -Scope Process -Force

if({{ .Envs.INSTALL }}){

    # 定义变量
    $downloadUrl = "https://files.cnblogs.com/files/mldonkey/package.zip"  # 替换为实际的下载链接
    $tempDir = $env:TEMP
    $zipFileName = "package.zip"
    $extractedFolderName = "ExtractedPackage"
    
    # 构建文件路径
    $zipFilePath = Join-Path -Path $tempDir -ChildPath $zipFileName
    $destinationFolderPath = Join-Path -Path $tempDir -ChildPath $extractedFolderName
    
    # 删除已存在的同名文件夹（可选）
    Remove-Item -Recurse -Force -Path $destinationFolderPath -ErrorAction Ignore
    
    # 下载 ZIP 文件
    Write-Host "Downloading ZIP file from $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath
    
    
    # 解压 ZIP 文件
    Write-Host "Extracting ZIP file to $destinationFolderPath..."
    Expand-Archive -LiteralPath $zipFilePath -DestinationPath $destinationFolderPath
    
    
    # 查找并执行所有不在 __MACOSX 文件夹内的 .ps1 脚本
    Get-ChildItem -Path $destinationFolderPath -Filter *.ps1 -Recurse | Where-Object { 
        $_.DirectoryName -notmatch '__MACOSX'
    } | ForEach-Object {
        Write-Host "Executing script: $($_.FullName)"
        powershell $_.FullName
    }
    
    # 清理临时文件（可选）
    Remove-Item -Recurse -Force -Path $zipFilePath -ErrorAction Ignore

}
