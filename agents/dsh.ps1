# IMP → DHS (DeepSeek Harness) 部署脚本
# 入口 skill imp → ~/.dsh/skills/imp/SKILL.md (global-rules + tool-mapping + frontmatter)
# 7 skills → ~/.dsh/skills/imp-*/SKILL.md (frontmatter: name, description, whenToUse)
# preset → ~/.dsh/.agent-presets/imp/

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

$dshHome = Expand-Path "~/.dsh"
$skillsDst = "$dshHome/skills"
$presetsDst = "$dshHome/.agent-presets"
$extrasDir = "$AgentsDir/dsh-extras"

switch ($Action) {
  "detect" {
    if (Test-Path $dshHome) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to DHS ===" -ForegroundColor Cyan

    # 1. 入口 skill: imp (global-rules + tool-mapping)
    $globalRules = Get-CoreGlobalRules $CoreDir
    $toolMapping = ""
    $tmPath = "$extrasDir/tool-mapping.md"
    if (Test-Path $tmPath) {
      $toolMapping = (Get-Content $tmPath -Raw -Encoding UTF8).TrimEnd()
    }
    $impFrontmatter = "---`nname: imp`ndescription: IMP（Intent Management Protocol）全局入口路由 — 每次对话/每个新任务先按此执行：断点恢复 → 四级问题分类（任务级/功能级/骨架级/新项目）→ 路由到 imp-* 技能，保证意图不丢失、骨架不失控、上下文不断层。`nwhenToUse: 每次对话开始或收到新的开发协作请求时必读；用户提及「IMP」「意图管理」「接手项目」「继续上次」「评估 IMP」时优先触发。`n---`n`n"
    $impContent = $impFrontmatter + "# IMP 全局入口规则（DHS 版）`n`n" + $globalRules + "`n`n" + $toolMapping
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

    # 3. preset
    $presetSrc = "$extrasDir/preset"
    if (Test-Path $presetSrc) {
      $presetDst = "$presetsDst/imp"
      if (-not $DryRun) {
        if (Test-Path $presetDst) { Remove-Item $presetDst -Recurse -Force }
        Copy-Item $presetSrc $presetDst -Recurse -Force
      }
      Write-Host "  [preset] → $presetDst" -ForegroundColor Green
    }

    Write-Host "Done. 新开会话或重启 DSH Web 生效。" -ForegroundColor Yellow
  }
}
