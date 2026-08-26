# IMP project discovery script - scan local machine for projects using IMP
# Cross-platform: works on Windows (powershell/pwsh) and macOS/Linux (pwsh)
param(
  [string]$ImpHome,
  [string]$SearchRoots
)

$ErrorActionPreference = "Stop"

# Locate IMP repo
if (-not $ImpHome) { $ImpHome = $env:IMP_HOME }
if (-not $ImpHome) { $ImpHome = "$env:USERPROFILE/CascadeProjects/IMP" }
if (-not (Test-Path $ImpHome)) {
  # Try common mac path
  $macPath = "$env:HOME/CascadeProjects/IMP"
  if (Test-Path $macPath) { $ImpHome = $macPath }
}
if (-not (Test-Path $ImpHome)) {
  Write-Error "IMP repo not found. Set -ImpHome or env var IMP_HOME"
  exit 1
}

$registryPath = "$ImpHome/.imp/projects-registry.md"
$registryDir = Split-Path -Parent $registryPath
if (-not (Test-Path $registryDir)) {
  New-Item -ItemType Directory -Force -Path $registryDir | Out-Null
}

# Determine search roots: user home + common project directories
if (-not $SearchRoots) {
  $home2 = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
  # Scan user home directly + known project parent dirs
  $SearchRoots = @(
    $home2
    "$home2/CascadeProjects"
    "$home2/codeM"
    "$home2/SynologyDrive"
  ) -join ","
}
$searchRootList = $SearchRoots -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and (Test-Path $_) }

Write-Host "Scanning roots:" -ForegroundColor Cyan
foreach ($r in $searchRootList) { Write-Host "  $r" }

# Read existing registry to avoid duplicates
$existingPaths = @{}
if (Test-Path $registryPath) {
  $existingContent = Get-Content $registryPath -Raw -Encoding UTF8
  $lines = $existingContent -split "`n"
  foreach ($line in $lines) {
    if ($line -match '^\|\s*(.+?)\s*\|\s*(.+?)\s*\|') {
      $p = $matches[2].Trim()
      if ($p -ne 'Path' -and $p -ne '------' -and $p -notmatch '^-+' -and $p -notmatch '路径') {
        $existingPaths[$p] = $true
      }
    }
  }
}

# Scan for projects with .imp/memory/ OR .windsurf/memory/ (legacy)
$discovered = @()
$seenPaths = @{}

foreach ($root in $searchRootList) {
  # Scan root itself + 2 levels deep
  $allDirs = @(Get-ChildItem $root -Directory -ErrorAction SilentlyContinue)
  foreach ($d in $allDirs) {
    # Check this directory
    $impMem = "$($d.FullName)/.imp/memory"
    $legacyMem = "$($d.FullName)/.windsurf/memory"
    $hasImp = (Test-Path $impMem) -or (Test-Path $legacyMem)
    if ($hasImp -and -not $existingPaths.ContainsKey($d.FullName) -and -not $seenPaths.ContainsKey($d.FullName)) {
      $seenPaths[$d.FullName] = $true
      $discovered += [PSCustomObject]@{
        Name = $d.Name
        Path = $d.FullName
        Date = Get-Date -Format "yyyy-MM-dd"
        Legacy = (Test-Path $legacyMem) -and -not (Test-Path $impMem)
      }
      $tag = if (Test-Path $legacyMem) { " (legacy .windsurf/)" } else { "" }
      Write-Host "  Found: $($d.Name) -> $($d.FullName)$tag" -ForegroundColor Green
    }
    # Check one level deeper
    $subDirs = Get-ChildItem $d.FullName -Directory -ErrorAction SilentlyContinue
    foreach ($sd in $subDirs) {
      $subImpMem = "$($sd.FullName)/.imp/memory"
      $subLegacyMem = "$($sd.FullName)/.windsurf/memory"
      $subHasImp = (Test-Path $subImpMem) -or (Test-Path $subLegacyMem)
      if ($subHasImp -and -not $existingPaths.ContainsKey($sd.FullName) -and -not $seenPaths.ContainsKey($sd.FullName)) {
        $seenPaths[$sd.FullName] = $true
        $discovered += [PSCustomObject]@{
          Name = $sd.Name
          Path = $sd.FullName
          Date = Get-Date -Format "yyyy-MM-dd"
          Legacy = (Test-Path $subLegacyMem) -and -not (Test-Path $subImpMem)
        }
        $tag = if (Test-Path $subLegacyMem) { " (legacy .windsurf/)" } else { "" }
        Write-Host "  Found: $($sd.Name) -> $($sd.FullName)$tag" -ForegroundColor Green
      }
    }
  }
}

if ($discovered.Count -eq 0) {
  Write-Host "No new projects found (all projects with .imp/memory/ already registered, or none exist)" -ForegroundColor Yellow
  exit 0
}

# Append to registry
if (-not (Test-Path $registryPath)) {
  $header = @"
# 本机使用 IMP 的项目注册表

> imp-onboard 执行时往这里追加一行；imp-reflect 按此表扫描各项目 trace。
> 老项目首次跑 imp-reflect 时由 scripts/discover-projects.ps1 自动补登记。

| 项目名 | 路径 | 登记时间 | 最近活跃 |
|--------|------|----------|----------|
"@
  Set-Content -Path $registryPath -Value $header -Encoding UTF8
}

$appendLines = @()
foreach ($d in $discovered) {
  $appendLines += "| $($d.Name) | $($d.Path) | $($d.Date) | $($d.Date) |"
}
Add-Content -Path $registryPath -Value ($appendLines -join "`n") -Encoding UTF8

Write-Host ""
Write-Host "=== Discovery complete ===" -ForegroundColor Cyan
Write-Host "New projects registered: $($discovered.Count)"
$legacyCount = ($discovered | Where-Object { $_.Legacy }).Count
if ($legacyCount -gt 0) {
  Write-Host "  (of which $legacyCount use legacy .windsurf/memory/ — run dsh/migrate-memory.ps1 to migrate)"
}
Write-Host "Registry: $registryPath"
