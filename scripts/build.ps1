# IMP build script - inject core/ into platform adaptor shells
param([string]$Platform)

$ErrorActionPreference = "Stop"

# Resolve repo root
if ($PSScriptRoot) {
  $repoRoot = Split-Path -Parent $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
  $repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
} else {
  $repoRoot = (Get-Location).Path
}

$coreDir = "$repoRoot\core"
$adaptorsDir = "$repoRoot\adaptors"

if (-not (Test-Path $coreDir)) {
  Write-Error "core/ not found: $coreDir"
  exit 1
}

# Determine platforms to build
if ($Platform) {
  $platforms = @($Platform)
} else {
  $platforms = @(Get-ChildItem $adaptorsDir -Directory | Select-Object -ExpandProperty Name)
}

if ($platforms.Count -eq 0) {
  Write-Error "No adaptor platforms found in: $adaptorsDir"
  exit 1
}

# Injection function: replace <!-- IMP-CORE-INJECT: xxx --> with core/xxx.md content
function Invoke-Injection {
  param([string]$Content, [string]$CoreDirPath)
  $pattern = '<!--\s*IMP-CORE-INJECT:\s*(\S+)\s*-->'
  $matches = [regex]::Matches($Content, $pattern)
  $result = $Content
  $count = 0
  for ($i = $matches.Count - 1; $i -ge 0; $i--) {
    $m = $matches[$i]
    $coreName = $m.Groups[1].Value
    $coreFile = "$CoreDirPath\$coreName.md"
    if (Test-Path $coreFile) {
      $coreContent = (Get-Content $coreFile -Raw -Encoding UTF8).TrimEnd()
      $result = $result.Substring(0, $m.Index) + $coreContent + $result.Substring($m.Index + $m.Length)
      $count++
    } else {
      Write-Warning "Core file not found: $coreFile"
    }
  }
  return @{ Content = $result; InjectionCount = $count }
}

$totalFiles = 0
$totalInjections = 0

foreach ($plat in $platforms) {
  $platDir = "$adaptorsDir\$plat"
  if (-not (Test-Path $platDir)) {
    Write-Warning "Platform dir not found, skipping: $platDir"
    continue
  }

  Write-Host ""
  Write-Host "=== Building: $plat ===" -ForegroundColor Cyan

  $outputDir = "$repoRoot\$plat"
  if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
  }

  # 1. global-rules shell (windsurf has one, dsh uses skills/imp/SKILL.md as entry)
  $globalRulesShell = "$platDir\global-rules.shell.md"
  if (Test-Path $globalRulesShell) {
    $outputPath = "$outputDir\global_rules.md"
    $shellContent = Get-Content $globalRulesShell -Raw -Encoding UTF8
    $result = Invoke-Injection $shellContent $coreDir
    Set-Content -Path $outputPath -Value $result.Content -Encoding UTF8 -NoNewline
    $totalFiles++
    $totalInjections += $result.InjectionCount
    Write-Host "  [global-rules] -> global_rules.md ($($result.InjectionCount) injections)" -ForegroundColor Green
  }

  # 2. skills/
  $skillsDir = "$platDir\skills"
  if (Test-Path $skillsDir) {
    $skillShells = Get-ChildItem $skillsDir -Recurse -Filter "SKILL.md"
    foreach ($shell in $skillShells) {
      $relativePath = $shell.FullName.Substring($skillsDir.Length).TrimStart('\','/')
      $outputPath = "$outputDir\skills\$relativePath"
      $outputParent = Split-Path -Parent $outputPath
      if (-not (Test-Path $outputParent)) {
        New-Item -ItemType Directory -Force -Path $outputParent | Out-Null
      }
      $shellContent = Get-Content $shell.FullName -Raw -Encoding UTF8
      $result = Invoke-Injection $shellContent $coreDir
      Set-Content -Path $outputPath -Value $result.Content -Encoding UTF8 -NoNewline
      $totalFiles++
      $totalInjections += $result.InjectionCount
      Write-Host "  [skill] $relativePath ($($result.InjectionCount) injections)" -ForegroundColor Green
    }
  }
}

Write-Host ""
Write-Host "=== Build complete ===" -ForegroundColor Cyan
Write-Host "Files generated: $totalFiles"
Write-Host "Total injections: $totalInjections"
