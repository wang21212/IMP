# IMP Installer — 一键部署 IMP 到本机所有 agent
#
# 用法：
#   pwsh install.ps1              # 交互模式：扫描 → 选择 → 部署
#   pwsh install.ps1 scan         # 只扫描，显示已安装的 agent
#   pwsh install.ps1 all          # 部署到所有检测到的 agent
#   pwsh install.ps1 windsurf     # 只部署到指定 agent
#   pwsh install.ps1 windsurf dsh # 部署到多个 agent
#   pwsh install.ps1 --dry-run    # 干跑，只显示会做什么
#   pwsh install.ps1 cursor --target=/path/to/project  # 项目级 agent 部署
#
# 跨平台：Windows (powershell/pwsh) + macOS/Linux (pwsh)

$ErrorActionPreference = "Stop"

# 路径解析（跨平台用 /）
if ($PSScriptRoot) {
  $repoRoot = $PSScriptRoot -replace '\\','/'
} else {
  $repoRoot = (Get-Location).Path -replace '\\','/'
}

$coreDir = "$repoRoot/core"
$agentsDir = "$repoRoot/agents"

if (-not (Test-Path $coreDir)) {
  Write-Error "core/ not found: $coreDir"
  exit 1
}
if (-not (Test-Path $agentsDir)) {
  Write-Error "agents/ not found: $agentsDir"
  exit 1
}

# ── Agent 注册表 ──────────────────────────────────────────────
$agentRegistry = @(
  @{ Name = "windsurf";    Script = "windsurf.ps1";    DisplayName = "Windsurf (Cascade)";     IsGlobal = $true  }
  @{ Name = "dsh";         Script = "dsh.ps1";         DisplayName = "DSH (DeepSeek Harness)";  IsGlobal = $true  }
  @{ Name = "claude-code"; Script = "claude-code.ps1"; DisplayName = "Claude Code";            IsGlobal = $true  }
  @{ Name = "codex";       Script = "codex.ps1";       DisplayName = "Codex (OpenAI CLI)";     IsGlobal = $true  }
  @{ Name = "hermes";      Script = "hermes.ps1";      DisplayName = "Hermes (NousResearch)";  IsGlobal = $true  }
  @{ Name = "openclaw";    Script = "openclaw.ps1";    DisplayName = "OpenClaw";               IsGlobal = $true  }
  @{ Name = "pi-agent";    Script = "pi-agent.ps1";    DisplayName = "Pi Agent";               IsGlobal = $true  }
  @{ Name = "workbuddy";   Script = "workbuddy.ps1";   DisplayName = "WorkBuddy (腾讯)";        IsGlobal = $true  }
  @{ Name = "cursor";      Script = "cursor.ps1";      DisplayName = "Cursor";                 IsGlobal = $false }
  @{ Name = "devin";       Script = "devin.ps1";       DisplayName = "Devin";                  IsGlobal = $false }
)

# ── 参数解析 ──────────────────────────────────────────────────
$command = $null
$agentNames = @()
$localDryRun = $false
$targetDir = "."

foreach ($arg in $args) {
  switch -Regex ($arg) {
    "^scan$" { $command = "scan" }
    "^all$" { $command = "all" }
    "^--dry-run$" { $localDryRun = $true }
    "^--target=(.+)$" { $targetDir = $matches[1] }
    default { $agentNames += $arg }
  }
}

if ($agentNames.Count -gt 0 -and -not $command) {
  $command = "specific"
}

# ── 扫描已安装的 agent ────────────────────────────────────────
function Scan-Agents {
  Write-Host ""
  Write-Host "Scanning for installed agents..." -ForegroundColor Cyan
  Write-Host ""

  $found = @()

  foreach ($agent in $agentRegistry) {
    $scriptPath = "$agentsDir/$($agent.Script)"
    if (-not (Test-Path $scriptPath)) {
      Write-Host "  [SKIP] $($agent.DisplayName) — script not found" -ForegroundColor DarkGray
      continue
    }

    # 调用 agent 脚本的 detect 模式
    $result = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $scriptPath -CoreDir $coreDir -AgentsDir $agentsDir -Action detect 2>$null).Trim()

    if ($result -eq "found") {
      $scope = if ($agent.IsGlobal) { "global" } else { "project" }
      Write-Host "  [FOUND] $($agent.DisplayName) ($scope)" -ForegroundColor Green
      $found += $agent
    } else {
      Write-Host "  [----] $($agent.DisplayName) — not detected" -ForegroundColor DarkGray
    }
  }

  Write-Host ""
  Write-Host "Found $($found.Count) agent(s)." -ForegroundColor Cyan
  return $found
}

# ── 部署到指定 agent ──────────────────────────────────────────
function Deploy-ToAgent {
  param([hashtable]$Agent)

  $scriptPath = "$agentsDir/$($agent.Script)"
  if (-not (Test-Path $scriptPath)) {
    Write-Warning "Script not found: $scriptPath"
    return
  }

  $deployArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath,
                  "-CoreDir", $coreDir, "-AgentsDir", $agentsDir, "-Action", "deploy")
  if ($localDryRun) { $deployArgs += "-DryRun" }
  if (-not $Agent.IsGlobal) { $deployArgs += @("-TargetDir", $targetDir) }

  & pwsh @deployArgs
}

# ── 管理员权限检测 ────────────────────────────────────────────
function Test-IsAdmin {
  # macOS/Linux 检测
  if ($env:HOME -and $env:HOME -notmatch '^[A-Z]:') {
    sudo -n true 2>$null
    return ($LASTEXITCODE -eq 0)
  }
  # Windows — 用 Security.Principal 检测
  try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch {
    return $false
  }
}

$isAdmin = Test-IsAdmin
if (-not $isAdmin) {
  Write-Host ""
  Write-Host "⚠️  当前非管理员/非 sudo 运行。" -ForegroundColor Yellow
  Write-Host "   IMP installer 需要扫描本机各 agent 的安装目录，" -ForegroundColor Yellow
  Write-Host "   部分目录可能需要管理员权限才能读取。" -ForegroundColor Yellow
  Write-Host "   如果扫描结果不完整，请用管理员权限重新运行：" -ForegroundColor Yellow
  Write-Host "     Windows: 以管理员身份打开 PowerShell → pwsh install.ps1" -ForegroundColor Yellow
  Write-Host "     macOS:   sudo pwsh install.ps1" -ForegroundColor Yellow
  Write-Host ""
}

# ── 主逻辑 ────────────────────────────────────────────────────

Write-Host ""
Write-Host "IMP Installer" -ForegroundColor Cyan
Write-Host "  repo: $repoRoot"
Write-Host "  core: $coreDir"
if ($localDryRun) { Write-Host "  mode: DRY RUN (不写文件)" -ForegroundColor Yellow }
Write-Host ""

switch ($command) {
  "scan" {
    Scan-Agents | Out-Null
  }

  "all" {
    $found = Scan-Agents
    if ($found.Count -eq 0) {
      Write-Host "No agents detected. Install an agent first, or use 'pwsh install.ps1 <agent-name>' to force deploy." -ForegroundColor Yellow
      return
    }
    Write-Host "Deploying to all $($found.Count) agent(s)..." -ForegroundColor Cyan
    foreach ($agent in $found) {
      Deploy-ToAgent $agent
      Write-Host ""
    }
    Write-Host "=== All deployments complete ===" -ForegroundColor Cyan
  }

  "specific" {
    foreach ($name in $agentNames) {
      $agent = $agentRegistry | Where-Object { $_.Name -eq $name }
      if (-not $agent) {
        Write-Warning "Unknown agent: $name"
        Write-Host "  Available: $($agentRegistry.Name -join ', ')"
        continue
      }
      Deploy-ToAgent $agent
      Write-Host ""
    }
    Write-Host "=== Deployment complete ===" -ForegroundColor Cyan
  }

  default {
    # 交互模式：扫描 → 选择
    $found = Scan-Agents
    if ($found.Count -eq 0) {
      Write-Host "No agents detected." -ForegroundColor Yellow
      Write-Host "You can force deploy with: pwsh install.ps1 <agent-name>"
      Write-Host "Available agents: $($agentRegistry.Name -join ', ')"
      return
    }

    Write-Host "Options:"
    Write-Host "  [a] Deploy to ALL detected agents"
    for ($i = 0; $i -lt $found.Count; $i++) {
      Write-Host "  [$($i+1)] $($found[$i].DisplayName)"
    }
    Write-Host ""
    $choice = Read-Host "Choose (a/1-$($found.Count))"

    if ($choice -eq "a" -or $choice -eq "A") {
      foreach ($agent in $found) {
        Deploy-ToAgent $agent
        Write-Host ""
      }
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $found.Count) {
      Deploy-ToAgent $found[[int]$choice - 1]
    } else {
      Write-Host "Invalid choice." -ForegroundColor Red
      return
    }
    Write-Host "=== Deployment complete ===" -ForegroundColor Cyan
  }
}
