# IMP → Cursor 部署脚本
# Cursor 没有全局 rules 文件，IMP 部署到项目级：
# global rules → <项目>/.cursor/rules/imp-global.mdc (alwaysApply: true)
# 7 skills → <项目>/.cursor/rules/imp-*.mdc (alwaysApply: false, agent-requested)

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

switch ($Action) {
  "detect" {
    # Cursor CLI 或 Cursor 编辑器安装检测
    $cursorDir = Expand-Path "~/.cursor"
    if ((Test-Path $cursorDir) -or (Get-Command cursor -ErrorAction SilentlyContinue)) {
      Write-Output "found"
    } else {
      Write-Output "notfound"
    }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to Cursor (project-level: $TargetDir) ===" -ForegroundColor Cyan

    $rulesDir = "$TargetDir/.cursor/rules"
    if (-not (Test-Path $rulesDir) -and -not $DryRun) {
      New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
    }

    # 1. Global rules → imp-global.mdc (alwaysApply: true)
    $globalRules = Get-CoreGlobalRules $CoreDir
    $globalMdc = "---`ndescription: IMP 全局入口路由 — 每次对话自动加载，断点恢复 → 四级判定 → 路由到 imp-* 技能`nalwaysApply: true`n---`n`n" + $globalRules
    $globalPath = "$rulesDir/imp-global.mdc"
    if (-not $DryRun) {
      Write-File $globalPath $globalMdc
    }
    Write-Host "  [global-rules] → $globalPath (alwaysApply)" -ForegroundColor Green

    # 2. 7 skills → imp-*.mdc (agent-requested, 不 alwaysApply)
    $skills = Get-CoreSkills $CoreDir
    foreach ($skill in $skills) {
      $desc = if ($skill.Frontmatter.description) { $skill.Frontmatter.description } else { $skill.Name }
      $fm = "---`ndescription: $desc`nalwaysApply: false`n---`n`n"
      $content = $fm + $skill.Body
      $mdcPath = "$rulesDir/$($skill.Name).mdc"
      if (-not $DryRun) {
        Write-File $mdcPath $content
      }
      Write-Host "  [rule] $($skill.Name) → $mdcPath" -ForegroundColor Green
    }

    Write-Host "Done. Cursor 打开项目后自动发现 .cursor/rules/ 下的 IMP 规则。" -ForegroundColor Yellow
    Write-Host "注意：Cursor 是项目级部署，需要在每个项目中跑此脚本。" -ForegroundColor Yellow
  }
}
