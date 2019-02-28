# 二重読み込み防止

if ( Get-Command -Name (gc $PSCommandPath | sls '^function').Line[0].Split()[1] -ErrorAction SilentlyContinue ) {
  exit $true
}

# 関数設定

## timeコマンドを指定回数実行して、回数・平均時間・最長時間・最短時間を表示
function Get-ScriptTime {
  param(
    [Parameter(Mandatory)][scriptblock]$Command,
    [int32]$Count = 10,
    [switch]$Table
  )

  $Time = (1..$Count) | % { (Measure-Command -Expression $Command).TotalMilliseconds } | measure -Average -Maximum -Minimum | select Count,Average,Maximum,Minimum,@{n='Script';e={$Command}}
  if ( $Table ) { return $Time | ft -AutoSize }

  return $Time
}

## UserCSSでフォント設定を上書きするための設定をクリップボードとファイルに取得
function Get-FontFamily {
  param(
    [string]$Path = '~/Downloads/style.css',
    [string]$FontFile = '~/.fontlist',
    [string]$Encoding = 'utf8',
    [string]$FontName = '恵梨沙フォント+Osaka－等幅'
  )

  if ( $psISE ) { psEdit $FontFile }

  (gc $Path -Encoding $Encoding).Split(';').Split('}').Split('{') | ? { $_ -match "font-family" } | % { ($_ -replace 'font-family:').Split(',') -replace "'" -replace '"' -replace '!important' -replace "`t" -replace '^ *' -replace ' *$' } | sort -Unique | Out-File $FontFile -Encoding $Encoding -Append
  $Fonts = (gc $FontFile -Encoding $Encoding | sort -Unique)
  $Fonts | % { '@font-face { src: local("' + $FontName + '"); font-family: "' + $_ + '"; }' } | scb
  $Fonts | Out-File $FontFile -Encoding $Encoding
}

## 指定した二つのファイルのうち、古いものを新しいもので上書きする
function Backup-Item {
  param(
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Target
  )

  if ( (Test-Path $Base) -and (! (Test-Path $Target)) ) {
    cp -Path $Base -Destination $Target
    return
  } elseif ( (! (Test-Path $Base)) -and (Test-Path $Target) ) {
    cp -Path $Target -Destination $Base
    return
  }

  $ErrorActionPreference = 'Stop'

  ($Base, $Target) | % {
    [System.IO.FileSystemInfo[]]$Files += (ls $_)
  }

  if ( $Files[0].LastWriteTime -gt $Files[1].LastWriteTime ) {
    cp -Path $Files[0] -Destination $Files[1]
  } elseif ( $Files[0].LastWriteTime -lt $Files[1].LastWriteTime ) {
    cp -Path $Files[1] -Destination $Files[0]
  }
}

## PC稼働時間を取得する(一日の中で一番最初と一番最後にイベントログが書かれた時間を見るため、日をまたぐ稼働時間は取得できない)
function Get-WorkTime {
  param(
    [datetime]$Today = (Get-Date),
    [datetime]$TargetDay = ($Today.AddDays(-8))
  )

  $EventLogs = Get-EventLog -LogName System -After $TargetDay.Date -Before $Today

  while ( $Today.Date -gt $TargetDay.Date ) {
    $StartWork,$EndWork = $EventLogs | ? { $_.TimeGenerated.Date -eq $TargetDay.Date } | sort TimeGenerated | select TimeGenerated -First 1 -Last 1
    $TargetDay | select @{n='Date';e={$_.Date.ToString('yyyy/MM/dd')}},@{n='Start';e={$StartWork.TimeGenerated.TImeOfDay}},@{n='End';e={$EndWork.TimeGenerated.TimeOfDay}}
    $TargetDay = $TargetDay.AddDays(1)
  }
}

## Jsonファイルを読み込む
function Import-Json {
  param(
    [string]$Path,
    [string]$Encoding = 'utf8'
  )

  $ErrorActionPreference = 'Stop'

  gc $Path -Encoding $Encoding | ConvertFrom-Json
}

## 画像を切り抜き
function Cut-Image {
  param(
    [Parameter(Mandatory, ValueFromPipeline)][IO.FileInfo]$File,
    [Parameter(Mandatory)][Int32]$X,
    [Parameter(Mandatory)][Int32]$Y,
    [Int32]$Width,
    [Int32]$Height
  )

  $BackupFile = ($File.FullName -replace "$",'.org')
  if ( Test-Path $BackupFile ) {
    return ('"{0}"のバックアップファイルが既に存在します。' -f $File.Name)
  }

  cp $File.FullName $BackupFile
  [datetime[]]$TimeStamp = ($File.CreationTime, $File.LastWriteTime)

  $SourceImage = New-Object System.Drawing.Bitmap($File.FullName)
  if ( ! $Width ) { $Width = $SourceImage.Width }
  if ( ! $Height ) { $Height = $SourceImage.Height }
  $Size = New-Object System.Drawing.Rectangle($X, $Y, $Width, $Height)
  $DestImage = $SourceImage.Clone($Size, $SourceImage.PixelFormat)
  $SourceImage.Dispose()
  $DestImage.Save($File.FullName, [System.Drawing.Imaging.ImageFormat]::($File.Extension.Replace('.','')))
  $DestImage.Dispose() 

  Set-ItemProperty $File -Name CreationTime -Value $TimeStamp[0]
  Set-ItemProperty $File -Name LastWriteTime -Value $TimeStamp[1]

  ls $File.FullName $BackupFile
}

## cdを改良
if ( gal cd -ErrorAction SilentlyContinue ) { rm alias:cd }
function cd {
  param(
    [parameter(ValueFromPipeline)]$Target
  )

  $ErrorActionPreference = 'Stop'

  [string]$Path = if ( $Target -is [Int] -and $OldPwd[$Target] ) {
    $OldPwd[$Target].Path
  } elseif ( $Target -is [string] ) {
    $Target
  } elseif ( $Target -is [IO.DirectoryInfo] ) {
    $Target.FullName
  } else {
    $HOME
  }

  [object[]]$global:OldPwd += Get-Location | select @{n='Id';e={$global:OldPwd.Count}},@{n='Path';e={$_.ProviderPath}}

  Set-Location $Path
}

## whichコマンド
function which {
  param(
    [parameter(Mandatory, ValueFromPipeline)][string]$Name
  )

  $env:Path.Split(';') | % {
    ls $_ -ErrorAction SilentlyContinue | ? { $_.BaseName -eq $Name -or $_.Name -eq $Name }
  }
}

## プロンプトの表示切替
function Switch-Prompt {
  if ( $global:DisplayDate ) {
    rv DisplayDate -Scope global
  } else {
    $global:DisplayDate = (Get-Date).ToString('yyyy/MM/dd hh:mm:ss')
  }
}

# 変数設定

[object]$global:DefaultVariable = (gv | select Name,Value)
[string[]]$global:ProgramFiles = ('C:\Tools', $env:ProgramFiles, ${env:ProgramFiles(x86)})
[string]$global:ProfileRoot = $PSScriptRoot
[string]$global:WorkplaceProfile = Join-Path $PSScriptRoot 'WorkplaceProfile.ps1'
[string]$global:DefaultFont = '恵梨沙フォント+Osaka－等幅'
[string]$global:GitPath = '~/Git'
[scriptblock]$global:IsAdmin = { [Security.Principal.WindowsIdentity]::GetCurrent().Owner -eq 'S-1-5-32-544' }
[scriptblock]$global:Prompt = {
  if ( $global:DisplayDate ) {
    Write-Host ('{0}[{1}]' -f "`n", $global:DisplayDate) -ForegroundColor Yellow -NoNewline
    Write-Host (' {0} ' -f $Pwd.ProviderPath.Replace($HOME,'~')) -ForegroundColor Cyan
  }
  if ( & $IsAdmin ) { '# ' } else { '> ' }
}

# Path追加

(
  (Split-Path $profile), # Profile
  (ls $ProgramFiles '*vim*' -Directory -ErrorAction SilentlyContinue | ls -Filter 'vim.exe').DirectoryName, # vim
  (ls 'C:\Windows\Microsoft.NET\Framework64' -Directory -ErrorAction SilentlyContinue | ls -Filter 'csc.exe' | sort VersionInfo)[-1].DirectoryName # .NET Framework
) | % { if ( $env:Path.Split(';') -notcontains $_ ) { $env:Path += (';' + $_) } }

# LOCAL MACHINEとCURRENT USER以外のレジストリをマウント

(
  @{ Name = 'HKCR'; PSProvider = 'Registry'; Root = 'HKEY_CLASSES_ROOT' },
  @{ Name = 'HKU';  PSProvider = 'Registry'; Root = 'HKEY_USERS' },
  @{ Name = 'HKCC'; PSProvider = 'Registry'; Root = 'HKEY_CURRENT_CONFIG' }
) | % {
  if ( Get-PSDrive $_.Name -ErrorAction SilentlyContinue ) {
    Write-Host ('ドライブレター "' + $_.Name + '" は既に使われていました。')
    return
  }
  New-PSDrive @_ > $null
}

# プロンプト設定

## ScriptBlock型の変数の内容をプロンプトとする
function prompt { & $Prompt }

## プロンプトを詳細表示に切り替える
Switch-Prompt

# 環境別プロファイルを読み込み(場所により異なる設定が必要な場合に使用)

if ( Test-Path $WorkplaceProfile -ErrorAction SilentlyContinue ) {
  . $WorkplaceProfile
}

# ISEでない場合はここで終了

if ( ! $psISE ) { exit $true }

# フォント・ツールバー設定

$psISE.Options.SelectedScriptPaneState = "Top"
$psISE.Options.Fontsize = 6
$psISE.Options.FontName = $DefaultFont
$psISE.Options.ShowToolBar = $false

# scratchとプロファイルをISEで開く

psEdit ((Join-Path $ProfileRoot 'scratch.ps1'), $profile, $WorkplaceProfile) -ErrorAction SilentlyContinue
