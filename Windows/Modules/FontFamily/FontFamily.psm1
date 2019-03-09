# 関数設定

## UserCSSでフォント設定を上書きするための設定をクリップボードとファイルに取得

function Get-FontFamily {
  param(
    [Parameter(ValueFromPipeline)][string]$Path = '~/Downloads/style.css',
    [string]$FontFile = '~/.fontlist',
    [string]$Encoding = 'utf8',
    [string]$FontName
  )

  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## ISEならフォントリストファイルを開いておく
  if ( $psISE ) {
    psEdit $FontFile
  }

  ## スタイルシートからfont-familyの設定値だけを取り出してフォントリストファイルに追記(ゴミが混ざりがち)
  (gc $Path -Encoding $Encoding).Split(';').Split('}').Split('{') |
    ? { $_ -match "font-family" } |
    % { ($_ -replace 'font-family:').Split(',') -replace "'" -replace '"' -replace '!important' -replace "`t" -replace '^ *' -replace ' *$' } |
    sort -Unique |
    Out-File $FontFile -Encoding $Encoding -Append

  ## フォントリストを取得
  $Fonts = (gc $FontFile -Encoding $Encoding | sort -Unique)

  ## UserCSSのフォント乗っ取り用設定として書き出してクリップボードに書き出し(Stylus等の画面に貼り付けるため)
  $Fonts |
    % { '@font-face { src: local("' + $FontName + '"); font-family: "' + $_ + '"; }' } |
    scb
  
  ## フォントリストをあらためてフォントリストファイルとして作成
  $Fonts | Out-File $FontFile -Encoding $Encoding
}

# 関数公開

Export-ModuleMember -Function *
