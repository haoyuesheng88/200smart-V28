. "$PSScriptRoot\mwsmart_v28_common.ps1"

$proc = Get-MWSmartProcess
$rect = Get-MWSmartRect -Handle $proc.MainWindowHandle

[PSCustomObject]@{
  ProcessName = $proc.ProcessName
  Id = $proc.Id
  MainWindowTitle = $proc.MainWindowTitle
  MainWindowHandle = $proc.MainWindowHandle
  Path = $proc.Path
  Left = $rect.Left
  Top = $rect.Top
  Right = $rect.Right
  Bottom = $rect.Bottom
}
