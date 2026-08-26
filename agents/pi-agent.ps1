# IMP → Pi Agent 部署脚本
# Pi Agent 用 ~/.pi/agent/rules/ 下的 .md 文件作为规则
# global rules → ~/.pi/agent/rules/imp-global.md
# 7 skills → ~/.pi/agent/rules/imp-*.md

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$piHome = Expand-Path "~/.pi"
$rulesDir = "$piHome/agent/rules"

switch ($Action) {
  "detect" {
    if (Test-Path $piHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Pi Agent ===" -ForegroundColor Cyan

    # 1. Global rules → imp-global.md
    $globalRules = Get-CoreGlobalRules $CoreDir
    $globalPath = "$rulesDir/imp-global.md"
    if (-not $DryRun) {
      Write-File $globalPath $globalRules
    }
    Write-Host "  [global-rules] → $globalPath" -ForegroundColor Green

    # 2. 7 skills → imp-*.md (纯 markdown)
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $content = $skill.Body
      $skillPath = "$rulesDir/$($skill.Name).md"
      if (-not $DryRun) {
        Write-File $skillPath $content
      }
      Write-Host "  [rule] $($skill.Name) → $skillPath" -ForegroundColor Green
    }

    Write-Host "Done. Pi Agent 自动加载 ~/.pi/agent/rules/ 下的 IMP 规则。" -ForegroundColor Yellow
  }
}
