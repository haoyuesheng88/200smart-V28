if (-not ("MWSmartNative" -as [type])) {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  Add-Type -AssemblyName UIAutomationClient
  Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public class MWSmartNative {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out MWSmartRect rect);
  [DllImport("user32.dll")] public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extra);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder text, int count);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, StringBuilder lParam);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);
}

public struct MWSmartRect {
  public int Left;
  public int Top;
  public int Right;
  public int Bottom;
}
'@
}

function Get-MWSmartProcess {
  param(
    [string[]]$ProcessName = @("MWSmart")
  )

  foreach ($name in $ProcessName) {
    $proc = Get-Process -Name $name -ErrorAction SilentlyContinue |
      Where-Object { $_.MainWindowHandle -ne 0 } |
      Select-Object -First 1
    if ($proc) {
      return $proc
    }
  }

  throw "STEP 7-Micro/WIN SMART V2.8 is not running. Tried process names: $($ProcessName -join ', ')"
}

function Get-MWSmartRect {
  param(
    [Parameter(Mandatory = $true)]
    [IntPtr]$Handle
  )

  [MWSmartRect]$rect = New-Object MWSmartRect
  [void][MWSmartNative]::GetWindowRect($Handle, [ref]$rect)
  return $rect
}

function Set-MWSmartForeground {
  param(
    [Parameter(Mandatory = $true)]
    [IntPtr]$Handle
  )

  [void][MWSmartNative]::SetForegroundWindow($Handle)
}

function Invoke-MWSmartClick {
  param(
    [Parameter(Mandatory = $true)]
    [int]$X,
    [Parameter(Mandatory = $true)]
    [int]$Y,
    [switch]$RightClick
  )

  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($X, $Y)
  if ($RightClick) {
    [MWSmartNative]::mouse_event(0x0008, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 80
    [MWSmartNative]::mouse_event(0x0010, 0, 0, 0, [UIntPtr]::Zero)
  } else {
    [MWSmartNative]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 80
    [MWSmartNative]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
  }
}

function Get-MWSmartVisibleDialogs {
  param(
    [Parameter(Mandatory = $true)]
    [int]$ProcessId,
    [IntPtr]$ExcludeHandle = [IntPtr]::Zero
  )

  $results = New-Object System.Collections.Generic.List[object]

  $callback = [MWSmartNative+EnumWindowsProc]{
    param($hWnd, $lParam)

    if (-not [MWSmartNative]::IsWindowVisible($hWnd)) {
      return $true
    }

    if ($hWnd -eq $ExcludeHandle) {
      return $true
    }

    [uint32]$windowProcessId = 0
    [void][MWSmartNative]::GetWindowThreadProcessId($hWnd, [ref]$windowProcessId)
    if ($windowProcessId -ne $ProcessId) {
      return $true
    }

    $classBuilder = New-Object System.Text.StringBuilder 128
    $titleBuilder = New-Object System.Text.StringBuilder 256
    [void][MWSmartNative]::GetClassName($hWnd, $classBuilder, $classBuilder.Capacity)
    [void][MWSmartNative]::GetWindowText($hWnd, $titleBuilder, $titleBuilder.Capacity)

    $className = $classBuilder.ToString()
    if ($className -ne "#32770") {
      return $true
    }

    $results.Add([PSCustomObject]@{
      Handle = $hWnd
      ClassName = $className
      Title = $titleBuilder.ToString()
    })

    return $true
  }

  [void][MWSmartNative]::EnumWindows($callback, [IntPtr]::Zero)
  return $results
}

function Get-MWSmartOutputWindowLines {
  $root = [System.Windows.Automation.AutomationElement]::RootElement
  $condition = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::AutomationIdProperty,
    "20260"
  )
  $element = $root.FindFirst([System.Windows.Automation.TreeScope]::Subtree, $condition)
  if (-not $element) {
    return @()
  }

  $handle = [IntPtr]$element.Current.NativeWindowHandle
  $count = [MWSmartNative]::SendMessage($handle, 0x018B, [IntPtr]::Zero, [IntPtr]::Zero).ToInt32()
  $lines = New-Object System.Collections.Generic.List[string]
  for ($i = 0; $i -lt $count; $i++) {
    $length = [MWSmartNative]::SendMessage($handle, 0x018A, [IntPtr]$i, [IntPtr]::Zero).ToInt32()
    $builder = New-Object System.Text.StringBuilder ($length + 2)
    [void][MWSmartNative]::SendMessage($handle, 0x0189, [IntPtr]$i, $builder)
    $lines.Add($builder.ToString())
  }

  return $lines.ToArray()
}

function Save-MWSmartWindowScreenshot {
  param(
    [Parameter(Mandatory = $true)]
    [IntPtr]$Handle,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
  )

  $rect = Get-MWSmartRect -Handle $Handle
  $width = $rect.Right - $rect.Left
  $height = $rect.Bottom - $rect.Top
  $bitmap = New-Object System.Drawing.Bitmap $width, $height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
  } finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }

  return $OutputPath
}

function Get-MWSmartInvalidNetworkCount {
  param(
    [Parameter(Mandatory = $true)]
    [IntPtr]$MainWindowHandle
  )

  $root = [System.Windows.Automation.AutomationElement]::FromHandle($MainWindowHandle)
  $all = $root.FindAll(
    [System.Windows.Automation.TreeScope]::Subtree,
    [System.Windows.Automation.Condition]::TrueCondition
  )

  $count = 0
  foreach ($element in $all) {
    $name = $element.Current.Name
    if ($name -match "无效程序段|Invalid network|invalid network") {
      $count++
    }
  }

  return $count
}

function Invoke-MWSmartDialogButton {
  param(
    [Parameter(Mandatory = $true)]
    [IntPtr]$DialogHandle,
    [Parameter(Mandatory = $true)]
    [string]$NameRegex
  )

  $dialog = [System.Windows.Automation.AutomationElement]::FromHandle($DialogHandle)
  $buttons = $dialog.FindAll(
    [System.Windows.Automation.TreeScope]::Descendants,
    (New-Object System.Windows.Automation.PropertyCondition(
      [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
      [System.Windows.Automation.ControlType]::Button
    ))
  )

  foreach ($button in $buttons) {
    $name = $button.Current.Name
    if ($name -match $NameRegex) {
      $invokePattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
      $invokePattern.Invoke()
      return $true
    }
  }

  return $false
}
