# 関数

## ディレクトリ移動コマンド

function Set-CurrentDirectory {
  param(
    [parameter(ValueFromPipeline)]$Target
  )

  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## 引数の型により動作を変更
  [string]$Path = if ( $Target -is [Int] -and $Global:OldPwd[$Target] ) {
    ## int型で$OldPwdのn番目が存在する場合、そのパスを移動先にする
    $Global:OldPwd[$Target].Path
  } elseif ( $Target -is [string] ) {
    ## string型の場合、そのままパスを移動先にする
    $Target
  } elseif ( $Target -is [IO.DirectoryInfo] ) {
    ## DirectoryInfo型の場合、そのFullNameを移動先にする
    $Target.FullName
  } else {
    ## すべて通り抜けた場合、ホームディレクトリ移動先にする
    $HOME
  }

  ## 移動前に現在のディレクトリを$OldPwdに番号付きで格納する
  [object[]]$Global:OldPwd += Get-Location |
    select @{n='Id';e={$Global:OldPwd.Count}},
           @{n='Path';e={$_.ProviderPath}}

  ## 移動
  Set-Location $Path
}

# コマンドにパスが通っているか確認

function WhereIs-Command {
  param(
    [parameter(Mandatory, ValueFromPipeline)][string]$Name
  )

  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## 環境変数PATH直下をすべて調べる
  $Path = $env:PATH.Split($Global:PathDelimiter) |
    gci -ErrorAction SilentlyContinue |
    ? { $_.BaseName -eq $Name -or $_.Name -eq $Name }

  ## 見つかったらパスを返す、見つからなかったらエラー終了
  if ( $Path ) {
    return $Path
  } else {
    Write-Error ('{0}は見つかりませんでした。' -f $Name) -Category ObjectNotFound
  }
}

## 指定コマンドを指定回数(初期値:10)実行して、回数・平均時間・最長時間・最短時間を表示

function Get-ScriptTime {
  param(
    [Parameter(Mandatory, ValueFromPipeline)][scriptblock]$Command,
    [uint32]$Count = 10,
    [switch]$Table
  )

  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## 実行回数・平均時間・最長時間・最短時間を取得
  $Time = (1..$Count) |
    % { (Measure-Command -Expression $Command).TotalSeconds } |
    measure -Average -Maximum -Minimum |
    select Count,Average,Maximum,Minimum,@{n='Script';e={$Command}}

  ## $Tableフラグにより、表示方法を切り替え
  if ( $Table ) {
    return $Time | ft -AutoSize
  } else {
    return $Time
  }
}

## 指定ディレクトリ配下のファイル・ディレクトリの情報を取得

function Find-ChildItem {
  param(
    [switch]$File,
    [switch]$Directory,
    [switch]$Recurse = $true,
    [string]$Name,
    [string]$Parent,
    [string]$Extension,
    [string]$FullName,
    [Parameter(ValueFromPipeline)][string]$Path = (Get-Location).ProviderPath
  )

  ## エラー時終了設定
  $ErrorActionPreference = 'Stop'

  ## $Fileと$Directoryを同時に指定した場合、Get-ChildItemは何も表示しないので、どちらも$falseに変更
  if ( $File -and $Directory ) {
    $File = $Directory = $false
  }

  ## スプラッティング定義
  $Option = @{
    Path = $Path
    File = $File
    Directory = $Directory
    Recurse = $Recurse
  }

  ## Get-ChildItem実行
  $FileList = gci @Option

  ## フルパスをフィルタ(正規表現)
  if ( $FullName ) {
    $FileList = $FileList | ? FullName -match $FullName
  }

  ## ファイル名をフィルタ(正規表現)
  if ( $Name ) {
    $FileList = $FileList | ? Name -match $Name
  }

  ## 親フォルダ名をフィルタ(正規表現)
  if ( $Parent ) {
    $FileList = $FileList | ? Parent -match $Parent
  }

  ## 拡張子指定
  if ( $Extension ) {
    if ( ! $Extension.StartsWith('.') ) {
      $Extension = $Extension -replace '^','.'
    }
    $FileList = $FileList | ? Extension -eq $Extension
  }

  ## 標準出力に取得したファイル・ディレクトリを表示
  $FileList
}

# 関数公開

Export-ModuleMember -Function *
