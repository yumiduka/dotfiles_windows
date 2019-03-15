# OS判定

[String]$OS = switch -Regex ( $PSVersionTable.OS ) {
  'Darwin'  { 'macOS' }
  'Windows' { $Matches.Values }
  $null     { 'WindowsPowerShell' }
  default   { $_ }
}

# ScriptBlock変数設定

## プロンプトの表示切替
function Switch-Prompt {
  if ( $Global:DisplayDate ) {
    rv DisplayDate -Scope global
  } else {
    [ScriptBlock]$Global:DisplayDate = { (Get-Date).ToString('yyyy/MM/dd HH:mm:ss') }
  }
}

## 管理者権限確認
[ScriptBlock]$Global:IsAdmin = {
  switch -Regex -CaseSensitive ( $OS ) {
    '^Windows' { [Security.Principal.WindowsIdentity]::GetCurrent().Owner -eq 'S-1-5-32-544' }
    default    { (whoami) -match 'root' }
  }
}

## プロンプト表示内容
[ScriptBlock]$Global:Prompt = {
  if ( $Global:DisplayDate ) {
    Write-Host ('{0}[{1}]' -f "`n", (& $Global:DisplayDate)) -ForegroundColor Yellow -NoNewline
    Write-Host (' {0} ' -f $Pwd.ProviderPath.Replace($HOME,'~')) -ForegroundColor Cyan
  }
  if ( & $IsAdmin ) { '# ' } else { '> ' }
}

## UHD確認
[ScriptBlock]$Global:IsUHD = {
  switch -Regex -CaseSensitive ( $OS ) {
    '^Windows' {
      Get-CimInstance -ClassName Win32_VideoController | % {
        $Horizontal = $_.CurrentHorizontalResolution
        $Vertical = $_.CurrentVerticalResolution
      }
    }
    '^macOS$' {
      $Display = /usr/sbin/system_profiler SPDisplaysDataType | ? { $_.Split(':')[0].Trim() -eq 'UI Looks like' } | % { $_.Trim().Split(':')[1].Trim() }
      $Horizontal = $Display.Split()[0] | Sort-Object -Unique | select -Last 1
      $Vertical = $Display.Split()[2] | Sort-Object -Unique | select -Last 1
    }
    default {
      $Horizontal = 2560
      $Vertical = 1440 
    }
  }
  $Horizontal -gt 1920 -and $Vertical -gt 1080
}

# 変数設定

[String[]]$Global:ProgramFiles = ($env:ProgramFiles, ${env:ProgramFiles(x86)})
[String]$Global:ProfileRoot = $PSScriptRoot
[String]$Global:WorkplaceProfile = Join-Path $PSScriptRoot 'WorkplaceProfile.ps1'
[String]$Global:DefaultFont = if ( & $global:IsUHD ) { 'Ricty Discord' } else { '恵梨沙フォント+Osaka－等幅' }
[String]$Global:GitPath = '~/Git'

# エイリアス設定

(
  @{ Name = 'cd';      Value = 'Set-CurrentDirectory'; Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'which';   Value = 'WhereIs-Command';      Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'whereis'; Value = 'WhereIs-Command';      Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'time';    Value = 'Get-ScriptTime';       Option = 'AllScope'; Scope = 'Global' },
  @{ Name = 'find';    Value = 'Find-ChildItem';       Option = 'AllScope'; Scope = 'Global' }
) | % {
  sal @_
}

# Path追加

& {
  $ErrorActionPreference = 'SilentlyContinue'
  (
    (Split-Path $profile), # Profile
    ($ProgramFiles | gci -Directory | ? Name -match 'vim' | gci | ? Name -match '^vim').DirectoryName, # vim
    ('C:\Windows\Microsoft.NET\Framework64' | gci -Directory | gci | ? Name -eq 'csc.exe' | sort VersionInfo)[-1].DirectoryName # .NET Framework
  ) | % {
    switch -Regex -CaseSensitive ( $OS ) { 
      'Windows' { $Delimiter = ';' }
      default   { $Delimiter = ':' }
    }

    if ( $env:PATH.Split($Delimiter) -notcontains $_ ) { $env:PATH += ($Delimiter + $_) }
  }
}

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
  $psISE.Options.Fontsize = if ( & $Global:IsUHD ) { 9 } else { 6 }
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
