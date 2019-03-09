# 変数

$ProfileRoot = (Split-Path $profile)
$InitialRoot = (Join-Path $PSScriptRoot 'Windows')

# Profile用ディレクトリ作成

if ( ! (Test-Path $ProfileRoot) ) {
  mkdir $ProfileRoot -Force
}

# Profile用ディレクトリ、シンボリックリンク作成

(
  @{ ItemType = 'Directory'; Path = $ProfileRoot },
  @{ ItemType = 'SymbolicLink'; Path = $env:PSModulePath.Split(';')[0]; Value = (Join-Path $InitialRoot 'Modules') },
  @{ ItemType = 'SymbolicLink'; Path = (Join-Path $ProfileRoot 'Microsoft.PowerShell_profile.ps1'); Value = (Join-Path $InitialRoot 'profile.ps1') },
  @{ ItemType = 'SymbolicLink'; Path = (Join-Path $ProfileRoot 'Microsoft.PowerShellISE_profile.ps1'); Value = (Join-Path $InitialRoot 'profile.ps1') },
  @{ ItemType = 'SymbolicLink'; Path = '~\.fontlist'; Value = (Join-Path $PSScriptRoot '.fontlist') }
) | % {
  ## 既に存在したら終了
  if ( Test-Path $_.Path ) {
    return
  }

  ## アイテムを作成
  ni @_
}

# エクスプローラーの3Dオブジェクト削除

ri 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}' -ErrorAction SilentlyContinue

# CapsLock -> LeftCtrl

[byte[]]$RegValue = @()
('00','00','00','00','00','00','00','00','02','00','00','00','1d','00','3a','00','00','00','00','00') | % { $RegValue += [Byte]('0x' + $_) }
sp -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -Name 'Scancode Map' -Value $RegValue

# PackageProvider追加

(
  @{ Name = 'Chocolatey'; Force = $true }
) | % {
  if ( ! (Get-PackageProvider @_ -ErrorAction SilentlyContinue) ) { 
    Install-PackageProvider @_
  }
}

# アプリ追加

(
  @{ Name = 'Git'; ProviderName = 'Chocolatey'; Force = $true },
  @{ Name = 'GoogleJapaneseInput'; ProviderName = 'Chocolatey'; Force = $true },
  @{ Name = '7zip'; ProviderName = 'Chocolatey'; Force = $true },
  @{ Name = 'Vivaldi'; ProviderName = 'Chocolatey'; Force = $true },
  @{ Name = 'steam'; ProviderName = 'Chocolatey'; Force = $true },
  @{ Name = 'mpc-hc'; ProviderName = 'Chocolatey'; Force = $true }
) | % {
  if ( ! (Get-Package @_ -ErrorAction SilentlyContinue) ) {
    Install-Package @_
  }
}
