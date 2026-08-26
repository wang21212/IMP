# IMP → Hermes (NousResearch) 部署脚本
# 入口 skill imp → ~/.hermes/skills/imp/SKILL.md (global-rules + frontmatter)
# 7 skills → ~/.hermes/skills/imp-*/SKILL.md (frontmatter: name, description, whenToUse)

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$hermesHome = Expand-Path "~/.hermes"
$skillsDst = "$hermesHome/skills"

switch ($Action) {
  "detect" {
    if (Test-Path $hermesHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Hermes ===" -ForegroundColor Cyan

    # 1. 入口 skill: imp (global-rules)
    $globalRules = Get-CoreGlobalRules $CoreDir
    $impFrontmatter = "---`nname: imp`ndescription: IMP（Intent Management Protocol）全局入口路由 — 每次对话自动加载，断点恢复 → 四级判定 → 路由到 imp-* 技能。`n---`n`n"
    $impContent = $impFrontmatter + $globalRules
    $impPath = "$skillsDst/imp/SKILL.md"
    if (-not $DryRun) {
      Write-File $impPath $impContent
    }
    Write-Host "  [entry-skill] imp → $impPath" -ForegroundColor Green

    # 2. 7 skills (keep whenToUse)
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $fm = Build-Frontmatter $skill.Frontmatter @("name", "description", "whenToUse")
      $content = $fm + $skill.Body
      $skillPath = "$skillsDst/$($skill.Name)/SKILL.md"
      if (-not $DryRun) {
        Write-File $skillPath $content
      }
      Write-Host "  [skill] $($skill.Name) → $skillPath" -ForegroundColor Green
    }

    Write-Host "Done. Hermes 自动发现 ~/.hermes/skills/ 下的 IMP 技能。" -ForegroundColor Yellow
  }
}
