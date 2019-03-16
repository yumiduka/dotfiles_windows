# 変数

$ProfileRoot = Split-Path $PROFILE
$InitialRoot = Join-Path $PSScriptRoot 'Windows'

# Profile用ディレクトリ、シンボリックリンク作成

(
  @{ ItemType = 'Directory';    Path = $ProfileRoot },
  @{ ItemType = 'SymbolicLink'; Path = $env:PSModulePath.Split(';')[0]; Value = (Join-Path $InitialRoot 'Modules') },
  @{ ItemType = 'SymbolicLink'; Path = $PROFILE.CurrentUserAllHosts; Value = (Join-Path $InitialRoot 'profile.ps1') },
  @{ ItemType = 'SymbolicLink'; Path = $PROFILE; Value = (Join-Path $InitialRoot (Split-Path -Leaf $PROFILE)) },
  @{ ItemType = 'SymbolicLink'; Path = '~\.fontlist'; Value = (Join-Path $PSScriptRoot '.fontlist') }
) | % {
  ## 配布先が既に存在する場合、次のエントリへ進む
  if ( Test-Path $_.Path ) {
    return
  }

  ## 配布元が存在しない場合、次のエントリへ進む(ISE用)
  if ( ! (Test-Path $_.Value) ) {
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
