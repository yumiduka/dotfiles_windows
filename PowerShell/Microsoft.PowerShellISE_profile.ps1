# フォント・ツールバー設定

$psISE.Options.SelectedScriptPaneState = "Top"
$psISE.Options.Fontsize = if ( & $Global:IsUHD ) { 9 } else { 6 }
$psISE.Options.FontName = $DefaultFont
$psISE.Options.ShowToolBar = $false

# scratchとプロファイルをISEで開く

psEdit ((Join-Path $ProfileRoot 'scratch.ps1'), $PROFILE.CurrentUserAllHosts, $PROFILE, $WorkplaceProfile) -ErrorAction SilentlyContinue
