# 関数

## CSVの内容をタブ区切りの文字列として変換

function Csv2Excel {
  param(
    [parameter(ValueFromPipeline)][IO.FileInfo]$File,
    [string]$Encoding,
    [object[]]$Text,
    [string[]]$Header,
    [string[]]$Filter
  )
  
  begin {
    ## エラー時終了設定
    $ErrorActionPreference = 'Stop'

    ## CSV読み込み時のヘッダ行を無視するための値
    [int]$Skip = 0
  }

  process {
    ## ファイル内容取得
    if ( $File ) {
      $Text = $File | Get-Content -Encoding $Encoding
    }

    ## ヘッダが指定されていない場合、ファイルの一行目からヘッダ定義を作成
    if ( ! $Header ) {
      $Header = $Text[0].Split(',') | % {
        if ( $_.StartsWith('"') -and $_.EndsWith('"') ) {
          $_ -replace '^"' -replace '"$'
        } elseif ( $_.StartsWith("'") -and $_.EndsWith("'") ) {
          $_ -replace "^'" -replace "'$"
        }
      }
      $Skip = 1
    }

    ## フィルタが指定されていない場合、ヘッダをフィルタとして定義
    if ( ! $Filter ) {
      $Filter = $Header
    }

    ## 変換するファイル名とその行数を表示して確認(noを入力で中断)
    if ( (Read-Host ('Copy "{0}[{1}]" ([Y]/N)' -f $File.Name, ($Text.Count - $Skip))) -match '^n(|o)$' ) {
      return
    }

    ## ファイルの内容をタブ区切りにして表示(各要素の余分な空白を削除)
    $Text |
      select -Skip $Skip |
      ConvertFrom-Csv -Header $Header | % {
        $Obj = $_
        ($Filter | % { if ( $Obj.($_) ) { $Obj.($_).Trim() } else { $Obj.($_) } }) -join "`t"
      }
  }
}

## タブ区切りをカンマ区切りに変換(変換後は要素をダブルクォーテーションで囲う)

filter Tsv2Csv {
  $Input.Replace("`t",'","') -replace '^','"' -replace '$','"'
}

## カンマ区切り(ダブルクォーテーション付き)をタブ区切りに変換

filter Csv2Tsv {
  $Input.Replace('","',"`t") -replace '^"' -replace '"$'
}

# 関数公開

Export-ModuleMember -Function *
