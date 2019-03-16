# profile配布

& (Join-Path $PSScriptRoot 'PowerShell.ps1')

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
