param(
  [string]$OutputPath
)

. "$PSScriptRoot\mwsmart_v28_common.ps1"

$proc = Get-MWSmartProcess

if (-not $OutputPath) {
  $OutputPath = Join-Path (Get-Location) "mwsmart_v28_window.png"
}

Save-MWSmartWindowScreenshot -Handle $proc.MainWindowHandle -OutputPath $OutputPath | Out-Null
Write-Output $OutputPath
