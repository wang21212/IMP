# IMP → OpenClaw 部署脚本
# OpenClaw 用 workspace/AGENTS.md 作为主要指令文件
# global rules → ~/.openclaw/workspace/AGENTS.md (upsert)
# 7 skills → ~/.openclaw/workspace/imp-skills/imp-*.md (作为参考文件)

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$openclawHome = Expand-Path "~/.openclaw"
$workspace = "$openclawHome/workspace"
$agentsMd = "$workspace/AGENTS.md"
$skillsDir = "$workspace/imp-skills"

switch ($Action) {
  "detect" {
    if (Test-Path $openclawHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to OpenClaw ===" -ForegroundColor Cyan

    # 1. Global rules → AGENTS.md (upsert)
    $globalRules = Get-CoreGlobalRules $CoreDir
    if (-not $DryRun) {
      Upsert-IMPContent $agentsMd $globalRules
    }
    Write-Host "  [global-rules] → $agentsMd (upsert)" -ForegroundColor Green

    # 2. 7 skills → imp-skills/ (纯 markdown，OpenClaw 按需读取)
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $content = $skill.Body
      $skillPath = "$skillsDir/$($skill.Name).md"
      if (-not $DryRun) {
        Write-File $skillPath $content
      }
      Write-Host "  [skill] $($skill.Name) → $skillPath" -ForegroundColor Green
    }

    Write-Host "Done. OpenClaw 每次会话自动加载 AGENTS.md，imp-skills/ 按需引用。" -ForegroundColor Yellow
  }
}
