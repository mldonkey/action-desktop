Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

# 检查是否以管理员权限运行
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
    Write-Warning "请以管理员权限运行此脚本！"
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

try {
    Write-Output "正在添加中文语言支持..."
    
    # 安装中文语言包
    $languageList = Get-WinUserLanguageList
    
    # 检查是否已安装中文
    if (-not ($languageList | Where-Object LanguageTag -eq "zh-CN")) {
        $languageList.Add("zh-CN")
        Set-WinUserLanguageList $languageList -Force
        Write-Output "已添加中文语言支持"
    } else {
        Write-Output "中文语言支持已存在"
    }
    
    # 添加微软拼音输入法
    Write-Output "正在设置中文输入法..."
    $zhCN = New-WinUserLanguageList zh-CN
    $zhCN[0].InputMethodTips.Clear()
    $zhCN[0].InputMethodTips.Add('0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{00000804}') # 微软拼音
    Set-WinUserLanguageList $zhCN -Force
    
    Write-Output "中文输入法设置完成！"
    
   
}
catch {
    Write-Output "发生错误: $_"
    Exit 1
}
