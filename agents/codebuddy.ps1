# IMP → CodeBuddy (腾讯 WorkBuddy) 部署脚本
# global rules → ~/.codebuddy/CODEBUDDY.md (upsert)
# 7 skills → ~/.codebuddy/skills/imp-*/SKILL.md (frontmatter: name, description)

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$cbHome = Expand-Path "~/.codebuddy"
$codebuddyMd = "$cbHome/CODEBUDDY.md"
$skillsDst = "$cbHome/skills"

switch ($Action) {
  "detect" {
    if (Test-Path $cbHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to CodeBuddy (腾讯 WorkBuddy) ===" -ForegroundColor Cyan

    # 1. Global rules → CODEBUDDY.md (upsert)
    $globalRules = Get-CoreGlobalRules $CoreDir
    if (-not $DryRun) {
      Upsert-IMPContent $codebuddyMd $globalRules
    }
    Write-Host "  [global-rules] → $codebuddyMd (upsert)" -ForegroundColor Green

    # 2. 7 skills → ~/.codebuddy/skills/ (frontmatter: name, description)
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

    Write-Host "Done. CodeBuddy 自动加载 CODEBUDDY.md，skills 自动发现。" -ForegroundColor Yellow
  }
}
