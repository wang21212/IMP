# IMP → Devin 部署脚本
# Devin 是云端 agent，skills 在项目级 .devin/skills/ 下发现
# global rules → .devin/skills/imp/SKILL.md (入口 skill，含 global-rules)
# 7 skills → .devin/skills/imp-*/SKILL.md

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

switch ($Action) {
  "detect" {
    # Devin CLI 检测
    if ((Get-Command devin -ErrorAction SilentlyContinue) -or (Test-Path (Expand-Path "~/.config/devin"))) {
      Write-Output "found"
    } else {
      Write-Output "notfound"
    }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Devin (project-level: $TargetDir) ===" -ForegroundColor Cyan

    $skillsDir = "$TargetDir/.devin/skills"

    # 1. 入口 skill: imp (global-rules 内容)
    $globalRules = Get-CoreGlobalRules $CoreDir
    $impFrontmatter = "---`nname: imp`ndescription: IMP（Intent Management Protocol）全局入口路由 — 每次对话自动加载，断点恢复 → 四级判定 → 路由到 imp-* 技能。`n---`n`n"
    $impContent = $impFrontmatter + $globalRules
    $impPath = "$skillsDir/imp/SKILL.md"
    if (-not $DryRun) {
      Write-File $impPath $impContent
    }
    Write-Host "  [entry-skill] imp → $impPath" -ForegroundColor Green

    # 2. 7 skills
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $fm = Build-Frontmatter $skill.Frontmatter @("name", "description")
      $content = $fm + $skill.Body
      $skillPath = "$skillsDir/$($skill.Name)/SKILL.md"
      if (-not $DryRun) {
        Write-File $skillPath $content
      }
      Write-Host "  [skill] $($skill.Name) → $skillPath" -ForegroundColor Green
    }

    Write-Host "Done. Devin 在此项目中自动发现 .devin/skills/ 下的 IMP 技能。" -ForegroundColor Yellow
    Write-Host "注意：Devin 是项目级部署，需要在每个项目中跑此脚本。" -ForegroundColor Yellow
  }
}
