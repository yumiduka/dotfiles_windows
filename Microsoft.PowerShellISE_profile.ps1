# 通常プロファイルパス定義

$NormalProfile = $profile.Replace('ISE','')

# 通常profile読み込み

. $NormalProfile

# ISE設定

$psISE.Options.Fontsize = 6
$psISE.Options.FontName = $DefaultFont
$psISE.Options.ShowToolBar = $false

# プロファイル

psEdit ($NormalProfile, $profile, (Join-Path $ProfileRoot 'draft.ps1'))
