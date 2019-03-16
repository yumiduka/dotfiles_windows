# 変数

$ProfileRoot = Split-Path $PROFILE
$InitialRoot = Join-Path $PSScriptRoot 'PowerShell'

# Profile用ディレクトリ、シンボリックリンク作成

(
  @{ ItemType = 'Directory'; Path = $ProfileRoot; Force = $true },
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
