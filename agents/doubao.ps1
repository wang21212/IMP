# IMP → Doubao (Doubao-TUI) 部署脚本
# 豆包本地终端 coding agent，配置目录 ~/.doubao/
# 入口 skill imp → ~/.doubao/skills/imp/SKILL.md (global-rules + frontmatter)
# 7 skills → ~/.doubao/skills/imp-*/SKILL.md (frontmatter: name, description, whenToUse)
#
# 注：Doubao-TUI 自动发现 ~/.doubao/skills/ 下的 SKILL.md，无需手动注册。
#     也会自动加载 workspace-local AGENTS.md，但全局规则通过入口 skill 注入更可靠。

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$doubaoHome = Expand-Path "~/.doubao"
$skillsDst = "$doubaoHome/skills"

switch ($Action) {
  "detect" {
    if (Test-Path $doubaoHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Doubao (Doubao-TUI) ===" -ForegroundColor Cyan

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

    Write-Host "Done. Doubao-TUI 自动发现 ~/.doubao/skills/ 下的 IMP 技能。" -ForegroundColor Yellow
  }
}
