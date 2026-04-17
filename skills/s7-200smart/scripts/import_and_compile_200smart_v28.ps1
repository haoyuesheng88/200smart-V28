param(
  [string]$AwlPath,
  [switch]$UseBundledBagPulse4,
  [int]$MainNodeOffsetX = 93,
  [int]$MainNodeOffsetY = 263,
  [int]$ImportMenuOffsetX = 147,
  [int]$ImportMenuOffsetY = 486,
  [int]$CompileButtonOffsetX = 113,
  [int]$CompileButtonOffsetY = 78,
  [int]$WaitSeconds = 3,
  [string]$ScreenshotPath,
  [switch]$SkipImport,
  [switch]$SkipCompile
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\mwsmart_v28_common.ps1"

if ($UseBundledBagPulse4) {
  $AwlPath = Join-Path (Split-Path -Parent $PSScriptRoot) "assets\bag-pulse-dust-collector-4bags-ob1.awl"
}

if (-not $SkipImport) {
  if (-not $AwlPath) {
    throw "Provide -AwlPath or use -UseBundledBagPulse4."
  }
  if (-not (Test-Path -LiteralPath $AwlPath)) {
    throw "AWL file not found: $AwlPath"
  }
  $AwlPath = (Resolve-Path -LiteralPath $AwlPath).Path
}

$proc = Get-MWSmartProcess
$rect = Get-MWSmartRect -Handle $proc.MainWindowHandle

Set-MWSmartForeground -Handle $proc.MainWindowHandle
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Start-Sleep -Milliseconds 200

$dialogs = Get-MWSmartVisibleDialogs -ProcessId $proc.Id -ExcludeHandle $proc.MainWindowHandle
foreach ($dialog in $dialogs) {
  if (Invoke-MWSmartDialogButton -DialogHandle $dialog.Handle -NameRegex "^(否|No|N)") {
    Start-Sleep -Milliseconds 600
  }
}

$importOutput = @()
if (-not $SkipImport) {
  Set-MWSmartForeground -Handle $proc.MainWindowHandle
  Start-Sleep -Milliseconds 200
  Invoke-MWSmartClick -X ($rect.Left + $MainNodeOffsetX) -Y ($rect.Top + $MainNodeOffsetY) -RightClick
  Start-Sleep -Milliseconds 400
  Invoke-MWSmartClick -X ($rect.Left + $ImportMenuOffsetX) -Y ($rect.Top + $ImportMenuOffsetY)
  Start-Sleep -Milliseconds 900

  $importDialog = Get-MWSmartVisibleDialogs -ProcessId $proc.Id -ExcludeHandle $proc.MainWindowHandle | Select-Object -First 1
  if (-not $importDialog) {
    throw "Import dialog not found. Check offsets or active save prompts."
  }

  Set-MWSmartForeground -Handle $importDialog.Handle
  Start-Sleep -Milliseconds 200
  Set-Clipboard -Value $AwlPath
  [System.Windows.Forms.SendKeys]::SendWait("%n")
  Start-Sleep -Milliseconds 150
  [System.Windows.Forms.SendKeys]::SendWait("^a")
  Start-Sleep -Milliseconds 100
  [System.Windows.Forms.SendKeys]::SendWait("^v")
  Start-Sleep -Milliseconds 200
  [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
  Start-Sleep -Seconds $WaitSeconds

  $followupDialog = Get-MWSmartVisibleDialogs -ProcessId $proc.Id -ExcludeHandle $proc.MainWindowHandle | Select-Object -First 1
  if ($followupDialog) {
    if (-not (Invoke-MWSmartDialogButton -DialogHandle $followupDialog.Handle -NameRegex "^(确定|OK|O)")) {
      [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    }
  } else {
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
  }

  Start-Sleep -Milliseconds 800
  $importOutput = Get-MWSmartOutputWindowLines
}

$compileOutput = @()
if (-not $SkipCompile) {
  Set-MWSmartForeground -Handle $proc.MainWindowHandle
  Start-Sleep -Milliseconds 200
  [System.Windows.Forms.SendKeys]::SendWait("{ESC}")
  Start-Sleep -Milliseconds 200
  Invoke-MWSmartClick -X ($rect.Left + $CompileButtonOffsetX) -Y ($rect.Top + $CompileButtonOffsetY)
  Start-Sleep -Seconds $WaitSeconds
  $compileOutput = Get-MWSmartOutputWindowLines
}

$invalidNetworkCount = Get-MWSmartInvalidNetworkCount -MainWindowHandle $proc.MainWindowHandle

if ($ScreenshotPath) {
  Save-MWSmartWindowScreenshot -Handle $proc.MainWindowHandle -OutputPath $ScreenshotPath | Out-Null
}

$compileText = $compileOutput -join "`n"
$compileHasZeroErrors = $compileText -match "\u9519\u8BEF\u603B\u8BA1\uFF1A0|0\s*\u4E2A\u9519\u8BEF|0\s+errors?"
$importSucceeded = ($importOutput -join "`n") -match "\u5BFC\u5165\u6210\u529F|import succeeded|success"

[PSCustomObject]@{
  ProcessId = $proc.Id
  WindowTitle = $proc.MainWindowTitle
  AwlPath = $AwlPath
  ImportOutput = $importOutput
  ImportSucceeded = $importSucceeded
  CompileOutput = $compileOutput
  CompileHasZeroErrors = $compileHasZeroErrors
  InvalidNetworkCount = $invalidNetworkCount
  ScreenshotPath = $ScreenshotPath
}
