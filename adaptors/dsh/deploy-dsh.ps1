# IMP → DHS (DeepSeek Harness) 一键部署脚本
# 自动先 build 再部署：1) Skills → ~/.dsh/skills/imp*/SKILL.md  2) IMP preset → ~/.dsh/.agent-presets/imp/
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy-dsh.ps1
# 或 VSCode Tasks（IMP: Deploy to DSH）。部署后重启 DSH Web 或新开会话生效。

$ErrorActionPreference = 'Stop'

# 路径解析（跨平台用 /）
$adaptorDir = $PSScriptRoot -replace '\\','/'
$repoRoot = (Split-Path -Parent (Split-Path -Parent $adaptorDir)) -replace '\\','/'

# --- 0. 先 build，确保 dsh/ 产物最新 ---
$buildScript = "$repoRoot/scripts/build.ps1"
if (Test-Path $buildScript) {
  Write-Host "[deploy] building dsh platform skills..." -ForegroundColor Cyan
  & $buildScript -Platform dsh
} else {
  Write-Warning "build.ps1 not found at $buildScript, skipping rebuild"
}

# --- 1. 从 build 产物目录取 skills ---
$skillsSrc = "$repoRoot/dsh/skills"
$presetSrc = "$adaptorDir/preset"

if (-not (Test-Path $skillsSrc)) { throw "skills build output not found: $skillsSrc (did build succeed?)" }
if (-not (Test-Path $presetSrc)) { throw "preset source not found: $presetSrc" }

$dshHome = Join-Path $env:USERPROFILE '.dsh'
$skillsDst = Join-Path $dshHome 'skills'
$presetsDst = Join-Path $dshHome '.agent-presets'

if (-not (Test-Path $skillsDst)) { New-Item -ItemType Directory -Path $skillsDst | Out-Null }
if (-not (Test-Path $presetsDst)) { New-Item -ItemType Directory -Path $presetsDst | Out-Null }

Write-Host "[deploy] skillsSrc=$skillsSrc"
Write-Host "[deploy] skillsDst=$skillsDst"

# ── 1. Skills（只枚举 imp / imp-*，防御性过滤）─────────────────────────────
$impDirs = Get-ChildItem -Path $skillsSrc -Directory | Where-Object { $_.Name -eq 'imp' -or $_.Name -like 'imp-*' }
if (-not $impDirs) { throw "no imp-* skill dirs found under $skillsSrc" }

foreach ($d in $impDirs) {
    $dst = Join-Path $skillsDst $d.Name
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item -Path $d.FullName -Destination $dst -Recurse -Force
    Write-Host "Deployed skill: $($d.Name)"
}

# ── 2. IMP preset ───────────────────────────────────────────────────────────
$presetDst = Join-Path $presetsDst 'imp'
if (Test-Path $presetDst) { Remove-Item $presetDst -Recurse -Force }
Copy-Item -Path $presetSrc -Destination $presetDst -Recurse -Force
Write-Host "Deployed preset: imp"

Write-Host ''
Write-Host 'Done. 生效方式：'
Write-Host '  - 新开会话即自动发现 skills（catalog 列出 imp / imp-intent / imp-onboard / imp-debug / imp-feature / imp-architect / imp-verify）'
Write-Host '  - 使用 IMP 模式预设：把 ~/.dsh/settings.yaml 的 agent-presets.default 改为 imp（或在新会话中选择该 preset）'
Write-Host '  - 若预设未出现在会话选择器，重启 DSH Web 服务后重试'
