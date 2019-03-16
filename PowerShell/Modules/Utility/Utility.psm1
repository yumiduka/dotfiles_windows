# 関数設定

## PC稼働時間を取得する(一日の中で一番最初と一番最後にイベントログが書かれた時間を見るため、日をまたぐ稼働時間は取得できない)
function Get-WorkTime {
  param(
    [datetime]$Today = (Get-Date),
    [datetime]$TargetDay = ($Today.AddDays(-8))
  )

  ## 指定期間のイベントログ(システム)を取得
  $EventLogs = Get-EventLog -LogName System -After $TargetDay.Date -Before $Today

  ## 古い日付から順番に処理
  while ( $Today.Date -gt $TargetDay.Date ) {
    ## 対象日の最新、最古エントリの作成時間を取得
    $StartWork,$EndWork = $EventLogs |
      ? { $_.TimeGenerated.Date -eq $TargetDay.Date } |
      sort TimeGenerated |
      select TimeGenerated -First 1 -Last 1

    ## 日付・開始時間・終了時間を表示
    $TargetDay | select @{n='Date';e={$_.Date.ToString('yyyy/MM/dd')}},
                        @{n='Start';e={$StartWork.TimeGenerated.TImeOfDay}},
                        @{n='End';e={$EndWork.TimeGenerated.TimeOfDay}}

    ## 対象日を進める
    $TargetDay = $TargetDay.AddDays(1)
  }
}

## Jsonファイルを読み込む

function Import-Json {
  param(
    [Parameter(ValueFromPipeline)][string]$Path,
    [string]$Encoding = 'utf8'
  )

  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## ファイルの内容を読み込んでJSON解析コマンドに渡す
  gc $Path -Encoding $Encoding |
    ConvertFrom-Json
}

## 画像を切り抜き(切り抜くピクセルを数値指定)

function Cut-Image {
  param(
    [Parameter(Mandatory, ValueFromPipeline)][IO.FileInfo]$File,
    [uint32]$Top = 0,
    [uint32]$Bottom = 0,
    [uint32]$Left = 0,
    [uint32]$Right = 0,
    [string]$BackupExtension = 'org'
  )

  begin {
    ## エラー時終了設定
    $ErrorActionPreference = 'Stop'

    ## バックアップファイルの拡張子の"."処理
    if ( ! $BackupExtension.StartsWith('.') ) {
      $BackupExtension = ('.{0}' -f $BackupExtension)
    }
  }

  process {
    ## バックアップファイル名を指定
    $BackupFile = ($File.FullName -replace '$',$BackupExtension)

    ## バックアップファイルが既にあったら終了
    if ( Test-Path $BackupFile ) {
      return ('"{0}"のバックアップファイルが既に存在します。' -f $File.Name)
    }

    ## バックアップ取得
    cp $File.FullName $BackupFile

    ## 画像取得
    try {
      $SourceImage = New-Object System.Drawing.Bitmap($File.FullName)
    } catch {
      Write-Error '指定ファイルは多分画像ファイルではありません。' -Category OpenError
    }

    ## 切り取り後の画像サイズを指定
    $Size = New-Object System.Drawing.Rectangle($Left, $Top, ($SourceImage.Width - $Left - $Right), ($SourceImage.Height - $Top - $Bottom))

    ## 指定サイズに切り取った画像を生成
    $DestImage = $SourceImage.Clone($Size, $SourceImage.PixelFormat)

    ## 元画像をクローズ
    $SourceImage.Dispose()

    ## 切り取った画像を保存
    $DestImage.Save($File.FullName, [System.Drawing.Imaging.ImageFormat]::($File.Extension.Replace('.','')))

    ## 切り取り画像クローズ
    $DestImage.Dispose()

    ## バックアップファイルのタイムスタンプ取得
    $TimeStamp = gi $BackupFile | select CreationTime,LastWriteTime

    ## バックアップファイルとタイムスタンプ同期
    sp $File -Name CreationTime -Value $TimeStamp.CreationTime
    sp $File -Name LastWriteTime -Value $TimeStamp.LastWriteTime
  }
}

## C#クラス読み込み

function Read-CSharp {
  param(
    [Parameter(ValueFromPipeline)][string]$Path,
    [string]$Encoding = 'utf8'
  )

  begin {
    ## エラー時終了設定
    $ErrorActionPreference = 'Stop'
  }

  process {
    ## C#のソースファイルを読み込む
    $Source = gc $Path -Encoding $Encoding -Raw

    ## 読み込んだソースのクラスをロード
    try {
      Add-Type -TypeDefinition $Source -Language CSharp
    } catch {
      Write-Error ('{0}の読み込みに失敗しました。' -f $Path) -Category ReadError
    }
  }
}

# 関数公開

Export-ModuleMember -Function *
