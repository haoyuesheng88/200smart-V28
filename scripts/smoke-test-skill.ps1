param()

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillRoot = Join-Path $repoRoot "skills\s7-200smart"

$requiredFiles = @(
  (Join-Path $skillRoot "SKILL.md"),
  (Join-Path $skillRoot "agents\openai.yaml"),
  (Join-Path $skillRoot "assets\bag-pulse-dust-collector-4bags-ob1.awl"),
  (Join-Path $skillRoot "references\bag-pulse-dust-collector-4bags.md"),
  (Join-Path $skillRoot "references\troubleshooting.md"),
  (Join-Path $skillRoot "scripts\mwsmart_v28_common.ps1"),
  (Join-Path $skillRoot "scripts\find_open_200smart_process.ps1"),
  (Join-Path $skillRoot "scripts\capture_200smart_window.ps1"),
  (Join-Path $skillRoot "scripts\read_200smart_output_window.ps1"),
  (Join-Path $skillRoot "scripts\import_and_compile_200smart_v28.ps1")
)

foreach ($file in $requiredFiles) {
  if (-not (Test-Path -LiteralPath $file)) {
    throw "Missing required file: $file"
  }
}

$psScripts = Get-ChildItem -LiteralPath (Join-Path $skillRoot "scripts") -Filter *.ps1 -File
foreach ($script in $psScripts) {
  $code = Get-Content -LiteralPath $script.FullName -Raw -Encoding UTF8
  [scriptblock]::Create($code) | Out-Null
}

$skillText = Get-Content -LiteralPath (Join-Path $skillRoot "SKILL.md") -Raw -Encoding UTF8
if ($skillText -notmatch "(?ms)^---\s*name:\s*s7-200smart") {
  throw "SKILL.md frontmatter is missing the expected skill name."
}

Write-Host "Smoke test passed for $skillRoot"
