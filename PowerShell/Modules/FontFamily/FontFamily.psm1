# 関数設定

## フォント上書き設定文を出力する

function Write-FontFace {
  param(
    [Parameter(Mandatory)][String]$LocalFont,
    [Parameter(Mandatory, ValueFromPipeline)][String]$SpecifiedFont
  )

  begin {
    ## エラー時終了設定
    $ErrorActionPreference = 'Stop'
  }

  process {
    ## font-face設定を出力
    ('@font-face { src: local("' + $LocalFont + '"); font-family: "' + $SpecifiedFont + '"; }')
  }
}

## CSSからフォント名を抜き出す

function Get-FontFamily {
  param(
    [Parameter(ValueFromPipeline)][String]$Path,
    [String]$FontFile,
    [String]$Encoding
  )

  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## 現在のフォントリストを取得
  [String[]]$Fonts = [String[]]$BeforeFonts = gc -Path $FontFile -Encoding $Encoding

  ## スタイルシートからfont-familyの設定値の内、既存のフォントリストに存在しないものだけを抽出
  [String[]]$AddFonts = (gc -Path $Path -Encoding $Encoding) -split '[;{}<>()]' -match 'font-family *:' -replace '(font-family *:|!important)' -split ',' |
    % { $_.Trim().Trim('"').Trim("'").Trim() } |
    Sort-Object -Unique |
    ? { $_ -notin $Fonts }

  ## 新規フォントがない場合、終了
  if ( ! $AddFonts ) {
    Write-Host '新しいフォントはありません。'
    return
  }

  ## 新規フォントを表示
  $AddFonts

  ## 更新確認
  while ( $Reply -notmatch '^y(|es)$' ) {
    $Reply = Read-Host -Prompt 'これらのフォントを追加してよろしいですか？ (Y/N)'
    if ( $Reply -match '^n(|o)$' ) {
      return
    }
  }

  ## 重複した行を削除
  $Fonts = $($Fonts; $AddFonts) | Sort-Object -Unique

  ## 新しいフォントリストをファイルに保存
  $Fonts | Out-File -FilePath $FontFile -Encoding $Encoding -Force

  ## フォントのリストを出力
  $Fonts
}

## font-face設定文をクリップボードに取得

function Get-FontFace {
  param(
    [Parameter(ValueFromPipeline)][String]$Path = '~/Downloads/style.css',
    [String]$FontFile = '~/.fontlist',
    [String]$Encoding = 'utf8',
    [String]$FontName = $Global:DefaultFont
  )
    
  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## フォント指定がない場合、エラー終了
  if ( ! $FontName ) {
    Write-Error -Message 'フォント指定がありません。' -Category 'NotSpecified'
  }

  ## UserCSSのフォント乗っ取り設定として書き出して、クリップボードに入れる
  $Path |
    Get-FontFamily -FontFile $FontFile -Encoding $Encoding |
    Write-FontFace -LocalFont $FontName |
    scb
}

# 関数公開

Export-ModuleMember -Function Write-FontFace
Export-ModuleMember -Function Get-FontFace
