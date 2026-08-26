# IMP → Claude Code 部署脚本
# global rules → ~/.claude/CLAUDE.md (upsert)
# 7 skills → ~/.claude/commands/imp-*.md (slash commands, 纯 markdown 无 frontmatter)

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$claudeHome = Expand-Path "~/.claude"
$claudeMd = "$claudeHome/CLAUDE.md"
$commandsDir = "$claudeHome/commands"

switch ($Action) {
  "detect" {
    if (Test-Path $claudeHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Claude Code ===" -ForegroundColor Cyan

    # 1. Global rules → CLAUDE.md (upsert)
    $globalRules = Get-CoreGlobalRules $CoreDir
    if (-not $DryRun) {
      Upsert-IMPContent $claudeMd $globalRules
    }
    Write-Host "  [global-rules] → $claudeMd (upsert)" -ForegroundColor Green

    # 2. Skills → commands/ (slash commands, 无 frontmatter)
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $content = $skill.Body
      $cmdPath = "$commandsDir/$($skill.Name).md"
      if (-not $DryRun) {
        Write-File $cmdPath $content
      }
      Write-Host "  [command] $($skill.Name) → $cmdPath" -ForegroundColor Green
    }

    Write-Host "Done. Claude Code 下次对话自动加载 CLAUDE.md，/imp-* 命令可用。" -ForegroundColor Yellow
  }
}
