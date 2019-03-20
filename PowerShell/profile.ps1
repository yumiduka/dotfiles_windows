# OS判定

[String]$OS = if ( $IsMacOS ) {
  'macOS'
} elseif ( $IsLinux ) {
  'Linux'
} else {
  'Windows'
}

# ScriptBlock変数設定

## プロンプトの表示切替
function Switch-Prompt {
  if ( $Global:DisplayDate ) {
    rv DisplayDate -Scope Global
  } else {
    [ScriptBlock]$Global:DisplayDate = { (Get-Date).ToString('yyyy/MM/dd HH:mm:ss') }
  }
}

## 管理者権限確認
if ( $OS -eq 'Windows' ) {
  [ScriptBlock]$Global:IsAdmin = { [Security.Principal.WindowsIdentity]::GetCurrent().Owner -eq 'S-1-5-32-544' }
} else {
  [ScriptBlock]$Global:IsAdmin = { (whoami) -match 'root' }
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
  switch ( $OS ) {
    'Windows' {
      $Horizontal, $Vertical = Get-CimInstance -ClassName Win32_VideoController | % { $_.CurrentHorizontalResolution, $_.CurrentVerticalResolution }
    }
    'macOS' {
      $Display = /usr/sbin/system_profiler SPDisplaysDataType | ? { $_.Split(':')[0].Trim() -eq 'UI Looks like' } | % { $_.Trim().Split(':')[1].Trim() }
      $Horizontal = $Display.Split()[0] | Sort-Object -Unique | select -Last 1
      $Vertical = $Display.Split()[2] | Sort-Object -Unique | select -Last 1
    }
    'Linux' {
      $Horizontal = 2560
      $Vertical = 1440 
    }
  }
  $Horizontal -gt 1920 -and $Vertical -gt 1080
}

# 変数設定

[String[]]$Global:ProgramFiles = ($env:ProgramFiles, ${env:ProgramFiles(x86)})
[String]$Global:ProfileRoot = Split-Path $PROFILE
[String]$Global:WorkplaceProfile = Join-Path $ProfileRoot 'WorkplaceProfile.ps1'
[String]$Global:DefaultFont = if ( & $Global:IsUHD ) { 'Ricty Discord' } else { '恵梨沙フォント+Osaka－等幅' }
[String]$Global:GitPath = '~/Git'
[String]$Global:PathDelimiter = if ( $env:PSModulePath -match ';' ) { ';' } else { ':' }

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

## クリップボード格納コマンド統一
switch ( $OS ) {
  'macOS' { sal -Name 'scb' -Value 'pbcopy' -Option AllScope -Scope Global }
  'Linux' { sal -Name 'scb' -Value 'xsel -bi' -Option AllScope -Scope Global }
}

# PATH初期値設定

if ( (Split-Path -Leaf $env:SHELL) -eq 'pwsh' ) {
  switch ( $OS ) {
    'macOS' {
      ## PowerShellのディレクトリを先頭にする
      $env:PATH = $env:PATH.Split($PathDelimiter)[0]
      ## bash用PATH初期値設定コマンドから初期値を末尾に追加
      $env:PATH = ($env:PATH, (((/usr/libexec/path_helper) -split '"')[1] -replace $env:PATH)) -join $PathDelimiter
      ## 両端のパス区切り文字を除外
      $env:PATH = $env:PATH.Trim($PathDelimiter)
    }
    'Linux' {
      # Linuxの環境が用意できたら追加予定。
    }
  }
}

# PATH追加

& {
  $ErrorActionPreference = 'SilentlyContinue'
  (
    (Split-Path $PROFILE), # Profile
    ($ProgramFiles | gci -Directory | ? Name -match 'vim' | gci | ? Name -match '^vim').DirectoryName, # vim
    ('C:\Windows\Microsoft.NET\Framework64' | gci -Directory | gci | ? Name -eq 'csc.exe' | Sort-Object VersionInfo)[-1].DirectoryName # .NET Framework
  ) | % {
    if ( $env:PATH.Split($PathDelimiter) -notcontains $_ ) {
      $env:PATH += ($PathDelimiter + $_)
    }
  }
}

# LOCAL MACHINEとCURRENT USER以外のレジストリをマウント

(
  @{ Name = 'HKCR'; PSProvider = 'Registry'; Root = 'HKEY_CLASSES_ROOT' },
  @{ Name = 'HKU';  PSProvider = 'Registry'; Root = 'HKEY_USERS' },
  @{ Name = 'HKCC'; PSProvider = 'Registry'; Root = 'HKEY_CURRENT_CONFIG' }
) | % {
  ## Windows以外でレジストリの場合はスキップ
  if ( $OS -ne 'Windows' -and $_.PSProvider -eq 'Registry' ) {
    return
  }

  ## なければ追加
  if ( ! (Test-Path ('{0}:' -f $_.Name)) ) {
    New-PSDrive @_ > $null
  }
}

# プロンプト設定

## ScriptBlock型の変数の内容をプロンプトとする
function prompt { & $Prompt }

## プロンプトを詳細表示に切り替える
Switch-Prompt

# 環境別プロファイルを読み込み(場所により異なる設定が必要な場合に使用)

if ( Test-Path $WorkplaceProfile -ErrorAction SilentlyContinue ) {
  . $WorkplaceProfile
}
