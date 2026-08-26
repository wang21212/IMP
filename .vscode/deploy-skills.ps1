# IMP → Windsurf Skills 部署（自动先 build）
$ErrorActionPreference = 'Stop'

$repoRoot = (Split-Path -Parent $PSScriptRoot) -replace '\\','/'

# --- 0. 先 build，确保 windsurf/ 产物最新 ---
$buildScript = "$repoRoot/scripts/build.ps1"
if (Test-Path $buildScript) {
  Write-Host "[deploy] building windsurf platform..." -ForegroundColor Cyan
  & $buildScript -Platform windsurf
} else {
  Write-Warning "build.ps1 not found at $buildScript, skipping rebuild"
}

# --- 1. 从 build 产物取 skills ---
$skillsSrc = "$repoRoot/windsurf/skills"
if (-not (Test-Path $skillsSrc)) { throw "skills build output not found: $skillsSrc" }

$skillsDst = Join-Path $env:USERPROFILE ".codeium\windsurf\skills"

if (-not (Test-Path $skillsDst)) {
    New-Item -ItemType Directory -Path $skillsDst | Out-Null
}

Get-ChildItem -Path $skillsSrc -Directory | ForEach-Object {
    $dst = Join-Path $skillsDst $_.Name
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    New-Item -ItemType Directory -Path $dst | Out-Null
    Copy-Item -Path (Join-Path $_.FullName "*") -Destination $dst -Recurse -Force
    Write-Host "Deployed: $($_.Name)"
}

Write-Host "Done. Restart Windsurf to pick up changes."
