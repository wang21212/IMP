# IMP → WorkBuddy (腾讯) 部署脚本
# global rules → ~/.codebuddy/CODEBUDDY.md (upsert)
# 7 skills → ~/.codebuddy/skills/imp-*/SKILL.md (frontmatter: name, description)
#
# 注：产品名为 WorkBuddy（腾讯云代码助手），配置目录为 ~/.codebuddy/

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$wbHome = Expand-Path "~/.codebuddy"
$codebuddyMd = "$wbHome/CODEBUDDY.md"
$skillsDst = "$wbHome/skills"

switch ($Action) {
  "detect" {
    if (Test-Path $wbHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to WorkBuddy (腾讯) ===" -ForegroundColor Cyan

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

    Write-Host "Done. WorkBuddy 自动加载 CODEBUDDY.md，skills 自动发现。" -ForegroundColor Yellow
  }
}
