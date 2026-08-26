<#
.SYNOPSIS
  IMP 项目发现脚本 — 扫描本机常见工作目录，找出所有含 .imp/memory/ 的项目，
  自动补登记到 IMP 仓库的 .imp/projects-registry.md。

.DESCRIPTION
  imp-reflect 评估时若注册表缺失或需要补充新项目，调用此脚本。
  扫描范围：CascadeProjects、codeM、PodBase、AskEverython 等本机常见工作目录。
  可通过 -SearchRoots 自定义扫描根目录列表。

.PARAMETER ImpHome
  IMP 源仓库路径。默认 $env:IMP_HOME 或 C:\Users\WangShuXuan\CascadeProjects\IMP

.PARAMETER SearchRoots
  要扫描的父目录列表（逗号分隔）。默认本机常见工作目录。

.EXAMPLE
  .\scripts\discover-projects.ps1
  .\scripts\discover-projects.ps1 -SearchRoots "C:\Users\WangShuXuan\CascadeProjects,C:\Users\WangShuXuan\codeM"
#>
param(
  [string]$ImpHome,
  [string]$SearchRoots
)

$ErrorActionPreference = "Stop"

# 定位 IMP 源仓库
if (-not $ImpHome) {
  $ImpHome = $env:IMP_HOME
}
if (-not $ImpHome) {
  $ImpHome = "C:\Users\WangShuXuan\CascadeProjects\IMP"
}
if (-not (Test-Path $ImpHome)) {
  Write-Error "IMP 源仓库不存在: $ImpHome。请设置 -ImpHome 或环境变量 IMP_HOME"
  exit 1
}

$registryPath = Join-Path $ImpHome ".imp\projects-registry.md"
$registryDir = Split-Path -Parent $registryPath
if (-not (Test-Path $registryDir)) {
  New-Item -ItemType Directory -Force -Path $registryDir | Out-Null
}

# 扫描根目录
if (-not $SearchRoots) {
  $userHome = $env:USERPROFILE
  $SearchRoots = @(
    "$userHome\CascadeProjects"
    "$userHome\codeM"
    "$userHome\PodBase"
    "$userHome\AskEverython"
    "$userHome\codeM\sub"
  ) -join ","
}
$searchRootList = $SearchRoots -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and (Test-Path $_) }

Write-Host "扫描根目录:" -ForegroundColor Cyan
foreach ($r in $searchRootList) { Write-Host "  $r" }

# 读取现有注册表（若存在），避免重复登记
$existingPaths = @{}
if (Test-Path $registryPath) {
  $existingContent = Get-Content $registryPath -Raw -Encoding UTF8
  $lines = $existingContent -split "`n"
  foreach ($line in $lines) {
    if ($line -match '^\|\s*(.+?)\s*\|\s*(.+?)\s*\|') {
      $p = $matches[2].Trim()
      if ($p -ne '路径' -and $p -ne '------' -and $p -notmatch '^---') {
        $existingPaths[$p] = $true
      }
    }
  }
}

# 扫描各根目录下含 .imp/memory/ 的项目
$discovered = @()
foreach ($root in $searchRootList) {
  # 扫描两层深度
  $candidates = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue
  foreach ($c in $candidates) {
    $impMemPath = Join-Path $c.FullName ".imp\memory"
    if (Test-Path $impMemPath) {
      if (-not $existingPaths.ContainsKey($c.FullName)) {
        $discovered += [PSCustomObject]@{
          Name = $c.Name
          Path = $c.FullName
          Date = Get-Date -Format "yyyy-MM-dd"
        }
        Write-Host "  发现: $($c.Name) -> $($c.FullName)" -ForegroundColor Green
      }
    }
    # 第二层
    $subCandidates = Get-ChildItem $c.FullName -Directory -ErrorAction SilentlyContinue
    foreach ($sc in $subCandidates) {
      $subImpMem = Join-Path $sc.FullName ".imp\memory"
      if (Test-Path $subImpMem) {
        if (-not $existingPaths.ContainsKey($sc.FullName)) {
          $discovered += [PSCustomObject]@{
            Name = $sc.Name
            Path = $sc.FullName
            Date = Get-Date -Format "yyyy-MM-dd"
          }
          Write-Host "  发现: $($sc.Name) -> $($sc.FullName)" -ForegroundColor Green
        }
      }
    }
  }
}

if ($discovered.Count -eq 0) {
  Write-Host "未发现新项目（所有含 .imp/memory/ 的项目已在注册表中，或本机无此类项目）" -ForegroundColor Yellow
  exit 0
}

# 追加到注册表
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
Write-Host "=== 发现完成 ===" -ForegroundColor Cyan
Write-Host "新登记项目数: $($discovered.Count)"
Write-Host "注册表路径: $registryPath"
