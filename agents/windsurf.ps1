# IMP → Windsurf (Cascade) 部署脚本
# global rules → ~/.codeium/windsurf/memories/global_rules.md (upsert)
# 7 skills → ~/.codeium/windsurf/skills/imp-*/SKILL.md (frontmatter: name, description, 无 whenToUse)

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy")

. "$AgentsDir/_common.ps1"

$wsDir = Expand-Path "~/.codeium/windsurf"
$memoriesDst = "$wsDir/memories/global_rules.md"
$skillsDst = "$wsDir/skills"

switch ($Action) {
  "detect" {
    # 检测：Windsurf 目录是否存在
    if (Test-Path $wsDir) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Windsurf ===" -ForegroundColor Cyan

    # 1. Global rules (upsert)
    $globalRules = Get-CoreGlobalRules $CoreDir
    if (-not $DryRun) {
      Upsert-IMPContent $memoriesDst $globalRules
    }
    Write-Host "  [global-rules] → $memoriesDst (upsert)" -ForegroundColor Green

    # 2. Skills (strip whenToUse)
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $fm = Build-Frontmatter $skill.Frontmatter @("name", "description")
      $content = $fm + $skill.Body
      $skillPath = "$skillsDst/$($skill.Name)/SKILL.md"
      if (-not $DryRun) {
        Write-File $skillPath $content
      }
      Write-Host "  [skill] $($skill.Name) → $skillPath" -ForegroundColor Green
    }

    Write-Host "Done. Restart Windsurf to pick up changes." -ForegroundColor Yellow
  }
}
