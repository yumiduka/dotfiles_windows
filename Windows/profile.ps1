# OS判定

[string]$OS = switch -Regex ( $PSVersionTable.OS ) {
  'Darwin'  { 'macOS' }
  'Windows' { $Matches.Values }
  $null     { 'WindowsPowerShell' }
  default   { $_ }
}

# ScriptBlock変数設定

## プロンプトの表示切替
function Switch-Prompt {
  if ( $global:DisplayDate ) {
    rv DisplayDate -Scope global
  } else {
    [scriptblock]$global:DisplayDate = { (Get-Date).ToString('yyyy/MM/dd HH:mm:ss') }
  }
}

## 管理者権限確認
[scriptblock]$global:IsAdmin = {
  [Security.Principal.WindowsIdentity]::GetCurrent().Owner -eq 'S-1-5-32-544'
}

## プロンプト表示内容
[scriptblock]$global:Prompt = {
  if ( $global:DisplayDate ) {
    Write-Host ('{0}[{1}]' -f "`n", (& $global:DisplayDate)) -ForegroundColor Yellow -NoNewline
    Write-Host (' {0} ' -f $Pwd.ProviderPath.Replace($HOME,'~')) -ForegroundColor Cyan
  }
  if ( & $IsAdmin ) { '# ' } else { '> ' }
}

## UHD確認
[scriptblock]$global:IsUHD = {
  Get-CimInstance -ClassName Win32_VideoController | % {
    $_.CurrentHorizontalResolution -gt 1920 -and $_.CurrentVerticalResolution -gt 1080
  }
}

# 変数設定

[object]$global:DefaultVariable = (gv | select Name,Value)
[string[]]$global:ProgramFiles = ('C:\Tools', $env:ProgramFiles, ${env:ProgramFiles(x86)})
[string]$global:ProfileRoot = $PSScriptRoot
[string]$global:WorkplaceProfile = Join-Path $PSScriptRoot 'WorkplaceProfile.ps1'
[string]$global:DefaultFont = if ( & $global:IsUHD ) { 'Ricty Discord' } else { '恵梨沙フォント+Osaka－等幅' }
[string]$global:GitPath = '~/Git'

# エイリアス設定

(
  @{ Name = 'cd'; Value = 'Set-CurrentDirectory'; Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'which'; Value = 'WhereIs-Command'; Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'whereis'; Value = 'WhereIs-Command'; Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'time'; Value = 'Get-ScriptTime'; Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'find'; Value = 'Find-ChildItem'; Option = 'AllScope'; Scope = 'Global' }
) | % {
  sal @_
}

# Path追加

(
  (Split-Path $profile), # Profile
  (ls $ProgramFiles '*vim*' -Directory -ErrorAction SilentlyContinue | ls -Filter 'vim.exe').DirectoryName, # vim
  (ls 'C:\Windows\Microsoft.NET\Framework64' -Directory -ErrorAction SilentlyContinue | ls -Filter 'csc.exe' | sort VersionInfo)[-1].DirectoryName # .NET Framework
) | % { if ( $env:Path.Split(';') -notcontains $_ ) { $env:Path += (';' + $_) } }

# LOCAL MACHINEとCURRENT USER以外のレジストリをマウント

(
  @{ Name = 'HKCR'; PSProvider = 'Registry'; Root = 'HKEY_CLASSES_ROOT' },
  @{ Name = 'HKU';  PSProvider = 'Registry'; Root = 'HKEY_USERS' },
  @{ Name = 'HKCC'; PSProvider = 'Registry'; Root = 'HKEY_CURRENT_CONFIG' }
) | % {
  if ( Get-PSDrive $_.Name -ErrorAction SilentlyContinue ) {
    Write-Host ('ドライブレター "' + $_.Name + '" は既に使われていました。')
    return
  }
  New-PSDrive @_ > $null
}

# プロンプト設定

## ScriptBlock型の変数の内容をプロンプトとする
function prompt { & $Prompt }

## プロンプトを詳細表示に切り替える
Switch-Prompt

# ISE設定
 
## フォント・ツールバー設定
if ( $psISE ) {
  $psISE.Options.SelectedScriptPaneState = "Top"
  $psISE.Options.Fontsize = if ( & $global:IsUHD ) { 9 } else { 6 }
  $psISE.Options.FontName = $DefaultFont
  $psISE.Options.ShowToolBar = $false
}

## scratchとプロファイルをISEで開く
if ( Get-Command psEdit -ErrorAction SilentlyContinue ) {
  psEdit ((Join-Path $ProfileRoot 'scratch.ps1'), $profile.CurrentUserAllHosts, $WorkplaceProfile) -ErrorAction SilentlyContinue
}

# 環境別プロファイルを読み込み(場所により異なる設定が必要な場合に使用)

if ( Test-Path $WorkplaceProfile -ErrorAction SilentlyContinue ) {
  . $WorkplaceProfile
}
