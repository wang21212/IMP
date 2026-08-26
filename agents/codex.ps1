# IMP → Codex (OpenAI Codex CLI) 部署脚本
# global rules → ~/.codex/AGENTS.md (upsert)
# 7 skills → ~/.agents/skills/imp-*/SKILL.md (Codex 的 skills 目录)

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$codexHome = Expand-Path "~/.codex"
$agentsMd = "$codexHome/AGENTS.md"
$skillsDir = Expand-Path "~/.agents/skills"

switch ($Action) {
  "detect" {
    if (Test-Path $codexHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Codex ===" -ForegroundColor Cyan

    # 1. Global rules → AGENTS.md (upsert)
    $globalRules = Get-CoreGlobalRules $CoreDir
    if (-not $DryRun) {
      Upsert-IMPContent $agentsMd $globalRules
    }
    Write-Host "  [global-rules] → $agentsMd (upsert)" -ForegroundColor Green

    # 2. Skills → ~/.agents/skills/ (Codex 的 skills 目录)
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $fm = Build-Frontmatter $skill.Frontmatter @("name", "description", "whenToUse")
      $content = $fm + $skill.Body
      $skillPath = "$skillsDir/$($skill.Name)/SKILL.md"
      if (-not $DryRun) {
        Write-File $skillPath $content
      }
      Write-Host "  [skill] $($skill.Name) → $skillPath" -ForegroundColor Green
    }

    Write-Host "Done. Codex 下次对话自动加载 AGENTS.md，skills 自动发现。" -ForegroundColor Yellow
  }
}
