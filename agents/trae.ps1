# IMP → TRAE (字节跳动，豆包官方 IDE) 部署脚本
# TRAE 是豆包的官方 IDE（前身 MarsCode），有文件式全局配置目录
#
# 全局规则 → ~/.trae-cn/user_rules/imp-global.md
# 全局技能 → ~/.trae-cn/skills/imp-*/SKILL.md (frontmatter: name, description)
#
# 注：TRAE 也支持项目级 .trae/rules/ 和 .trae/skills/，以及 .agents/skills/
#     全局部署更符合 IMP 的"装一次所有项目生效"模型
# 参考文档：https://docs.trae.ai/ide/rules / https://docs.trae.cn/ide_skills

param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy", [string]$TargetDir = ".")

. "$AgentsDir/_common.ps1"

# TRAE 国际版用 ~/.trae/，国内版用 ~/.trae-cn/
# 优先检测国内版，fallback 到国际版
$traeHome = Expand-Path "~/.trae-cn"
if (-not (Test-Path $traeHome)) {
  $traeHome = Expand-Path "~/.trae"
}
$userRulesDir = "$traeHome/user_rules"
$skillsDst = "$traeHome/skills"

switch ($Action) {
  "detect" {
    # 检测任一版本存在即可
    $found = (Test-Path (Expand-Path "~/.trae-cn")) -or (Test-Path (Expand-Path "~/.trae"))
    if ($found) { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }

  "deploy" {
    Write-Host "=== Deploying IMP to TRAE (字节跳动) ===" -ForegroundColor Cyan
    Write-Host "  配置目录: $traeHome" -ForegroundColor DarkGray

    # 1. Global rules → user_rules/imp-global.md
    $globalRules = Get-CoreGlobalRules $CoreDir
    $globalPath = "$userRulesDir/imp-global.md"
    if (-not $DryRun) {
      Write-File $globalPath $globalRules
    }
    Write-Host "  [global-rules] → $globalPath" -ForegroundColor Green

    # 2. 7 skills → ~/.trae-cn/skills/ (SKILL.md, frontmatter: name, description)
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

    Write-Host "Done. TRAE 自动发现 ~/.trae-cn/skills/ 下的 IMP 技能，全局规则自动加载。" -ForegroundColor Yellow
  }
}
