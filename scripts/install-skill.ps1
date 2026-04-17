param(
  [string]$TargetRoot,
  [switch]$NoBackup
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceSkill = Join-Path $repoRoot "skills\s7-200smart"

if (-not (Test-Path -LiteralPath $sourceSkill)) {
  throw "Packaged skill not found: $sourceSkill"
}

if (-not $TargetRoot) {
  if ($env:CODEX_HOME) {
    $TargetRoot = $env:CODEX_HOME
  } else {
    $TargetRoot = Join-Path $HOME ".codex"
  }
}

$targetSkillsRoot = Join-Path $TargetRoot "skills"
$destination = Join-Path $targetSkillsRoot "s7-200smart"

New-Item -ItemType Directory -Force -Path $targetSkillsRoot | Out-Null

if (Test-Path -LiteralPath $destination) {
  if (-not $NoBackup) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$destination.bak-$timestamp"
    Move-Item -LiteralPath $destination -Destination $backup
    Write-Host "Backed up existing skill to $backup"
  } else {
    Remove-Item -LiteralPath $destination -Recurse -Force
  }
}

Copy-Item -LiteralPath $sourceSkill -Destination $destination -Recurse -Force

Write-Host "Installed s7-200smart to $destination"
