# IMP agents shared functions — 被各 agent 部署脚本 dot-source
# 跨平台：Windows (powershell/pwsh) + macOS/Linux (pwsh)

# 解析 core 文件的 YAML frontmatter + body
# 返回 @{ Frontmatter = [hashtable]; Body = [string] }
function Parse-CoreFile {
  param([string]$Path)
  $raw = (Get-Content $Path -Raw -Encoding UTF8).TrimEnd()
  if ($raw -match '(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)') {
    $yamlBlock = $matches[1]
    $body = $matches[2].TrimStart()
    $fm = @{}
    foreach ($line in ($yamlBlock -split "`n")) {
      if ($line -match '^\s*(\w+)\s*:\s*(.*)$') {
        $fm[$matches[1]] = $matches[2].Trim()
      }
    }
    return @{ Frontmatter = $fm; Body = $body }
  }
  # 无 frontmatter
  return @{ Frontmatter = @{}; Body = $raw }
}

# 从 frontmatter hashtable 生成 YAML 字符串
# $Fields 指定要包含的字段顺序，如 @("name","description","whenToUse")
function Build-Frontmatter {
  param([hashtable]$Fm, [string[]]$Fields)
  $lines = @()
  foreach ($key in $Fields) {
    if ($Fm.ContainsKey($key) -and $Fm[$key]) {
      $lines += "$key`: $($Fm[$key])"
    }
  }
  if ($lines.Count -eq 0) { return "" }
  return "---`n$($lines -join "`n")`n---`n`n"
}

# 读取 core 目录下所有 skill 文件（含 frontmatter）
# 返回数组：@{ Name; File; Frontmatter; Body }
function Get-CoreSkills {
  param([string]$CoreDir)
  $skillFiles = @(
    "imp-onboard", "imp-intent", "imp-feature", "imp-architect",
    "imp-debug", "imp-verify", "imp-reflect"
  )
  $skills = @()
  foreach ($name in $skillFiles) {
    $path = "$CoreDir/$name.md"
    if (-not (Test-Path $path)) { continue }
    $parsed = Parse-CoreFile $path
    $skills += @{
      Name = $name
      File = $path
      Frontmatter = $parsed.Frontmatter
      Body = $parsed.Body
    }
  }
  return $skills
}

# 读取 global-rules.md（无 frontmatter，纯内容）
function Get-CoreGlobalRules {
  param([string]$CoreDir)
  $path = "$CoreDir/global-rules.md"
  if (-not (Test-Path $path)) { throw "global-rules.md not found: $path" }
  return (Get-Content $path -Raw -Encoding UTF8).TrimEnd()
}

# 跨平台写文件（自动创建目录）
function Write-File {
  param([string]$Path, [string]$Content)
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::UTF8)
}

# 跨平台 home 目录
function Get-HomeDir {
  if ($env:HOME) { return $env:HOME }
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  return (Get-Location).Path
}

# 展开 ~ 路径
function Expand-Path {
  param([string]$Path)
  if ($Path -match '^~(.*)') {
    return (Get-HomeDir) + $matches[1]
  }
  return $Path -replace '\\','/'
}

# upsert IMP 内容到已有文件（以 "# IMP" 为标记，替换标记后所有内容）
function Upsert-IMPContent {
  param([string]$TargetPath, [string]$NewContent)
  $marker = "# IMP"
  if (Test-Path $TargetPath) {
    $existing = Get-Content $TargetPath -Raw -Encoding UTF8
    $idx = $existing.IndexOf($marker)
    if ($idx -ge 0) {
      $before = $existing.Substring(0, $idx).TrimEnd()
      if ($before.Length -gt 0) {
        $merged = $before + "`n`n" + $newContent.TrimStart()
      } else {
        $merged = $newContent
      }
    } else {
      $merged = $existing.TrimEnd() + "`n`n" + $newContent.TrimStart()
    }
    Write-File $TargetPath $merged
  } else {
    Write-File $TargetPath $newContent
  }
}

# 列出所有 agent 脚本（agents/ 下的 .ps1，排除 _common.ps1）
function Get-AgentScripts {
  param([string]$AgentsDir)
  return Get-ChildItem $AgentsDir -Filter "*.ps1" | Where-Object { $_.Name -ne "_common.ps1" }
}
