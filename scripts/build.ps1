<#
.SYNOPSIS
  IMP 构建脚本 — 把 core/ 核心协议注入各平台适配壳，生成最终 skill 文件。

.DESCRIPTION
  扫描 adaptors/<platform>/ 下的壳文件（含 <!-- IMP-CORE-INJECT: xxx --> 标记），
  把 core/xxx.md 全文替换到标记位置，输出到 <platform>/ 对应路径。
  core/ 是唯一修改源，生成的 windsurf/ 和 dsh/ 是产物，禁止手改。

.PARAMETER Platform
  指定只构建某个平台（windsurf / dsh）。不指定则构建全部。

.EXAMPLE
  .\scripts\build.ps1
  .\scripts\build.ps1 -Platform windsurf
#>
param(
  [string]$Platform
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$coreDir = Join-Path $repoRoot "core"
$adaptorsDir = Join-Path $repoRoot "adaptors"

if (-not (Test-Path $coreDir)) {
  Write-Error "core/ 目录不存在: $coreDir"
  exit 1
}

if ($Platform) {
  $platforms = @($Platform)
} else {
  $platforms = Get-ChildItem $adaptorsDir -Directory | Select-Object -ExpandProperty Name
}

if ($platforms.Count -eq 0) {
  Write-Error "未找到任何平台适配目录: $adaptorsDir"
  exit 1
}

# 注入函数：把壳内容中的 <!-- IMP-CORE-INJECT: xxx --> 替换为 core/xxx.md 全文
function Invoke-Injection {
  param([string]$Content, [string]$CoreDir)
  $pattern = '<!--\s*IMP-CORE-INJECT:\s*(\S+)\s*-->'
  $matches = [regex]::Matches($Content, $pattern)
  $result = $Content
  $count = 0
  # 从后往前替换，避免索引偏移
  for ($i = $matches.Count - 1; $i -ge 0; $i--) {
    $m = $matches[$i]
    $coreName = $m.Groups[1].Value
    $coreFile = Join-Path $CoreDir "$coreName.md"
    if (Test-Path $coreFile) {
      $coreContent = (Get-Content $coreFile -Raw -Encoding UTF8).TrimEnd()
      $result = $result.Substring(0, $m.Index) + $coreContent + $result.Substring($m.Index + $m.Length)
      $count++
    } else {
      Write-Warning "核心文件不存在: $coreFile"
    }
  }
  return @{ Content = $result; InjectionCount = $count }
}

$totalFiles = 0
$totalInjections = 0

foreach ($plat in $platforms) {
  $platDir = Join-Path $adaptorsDir $plat
  if (-not (Test-Path $platDir)) {
    Write-Warning "平台目录不存在，跳过: $platDir"
    continue
  }

  Write-Host ""
  Write-Host "=== 构建平台: $plat ===" -ForegroundColor Cyan

  $outputDir = Join-Path $repoRoot $plat
  if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
  }

  # 1. global-rules（windsurf 有独立 shell，dsh 入口在 skills/imp/SKILL.md）
  $globalRulesShell = Join-Path $platDir "global-rules.shell.md"
  if (Test-Path $globalRulesShell) {
    $outputPath = Join-Path $outputDir "global_rules.md"
    $shellContent = Get-Content $globalRulesShell -Raw -Encoding UTF8
    $result = Invoke-Injection $shellContent $coreDir
    Set-Content -Path $outputPath -Value $result.Content -Encoding UTF8 -NoNewline
    $totalFiles++
    $totalInjections += $result.InjectionCount
    Write-Host "  [global-rules] -> global_rules.md ($($result.InjectionCount) 注入)" -ForegroundColor Green
  }

  # 2. skills/
  $skillsDir = Join-Path $platDir "skills"
  if (Test-Path $skillsDir) {
    $skillShells = Get-ChildItem $skillsDir -Recurse -Filter "SKILL.md"
    foreach ($shell in $skillShells) {
      $relativePath = $shell.FullName.Substring($skillsDir.Length).TrimStart('\','/')
      $outputPath = Join-Path $outputDir "skills"
      $outputPath = Join-Path $outputPath $relativePath
      $outputParent = Split-Path -Parent $outputPath
      if (-not (Test-Path $outputParent)) {
        New-Item -ItemType Directory -Force -Path $outputParent | Out-Null
      }
      $shellContent = Get-Content $shell.FullName -Raw -Encoding UTF8
      $result = Invoke-Injection $shellContent $coreDir
      Set-Content -Path $outputPath -Value $result.Content -Encoding UTF8 -NoNewline
      $totalFiles++
      $totalInjections += $result.InjectionCount
      Write-Host "  [skill] $relativePath ($($result.InjectionCount) 注入)" -ForegroundColor Green
    }
  }
}

Write-Host ""
Write-Host "=== 构建完成 ===" -ForegroundColor Cyan
Write-Host "生成文件: $totalFiles"
Write-Host "总注入数: $totalInjections"
