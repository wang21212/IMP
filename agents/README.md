# IMP Agents — 如何添加新 Agent

## Agent 定义

任何符合以下条件的工具都是 IMP 的 agent：
- LLM 控制的多步骤操作实体
- 通过 read/write/create/delete 操作文件实现用户需求
- 支持某种形式的自定义指令（全局规则或可复用 prompt 片段）

## 添加新 Agent

在 `agents/` 下创建 `<agent-name>.ps1`，实现三个函数：

```powershell
# 1. 检测：本机是否安装了该 agent
function Test-<AgentName>Installed {
  return (Test-Path "~/.<agent-dir>")
}

# 2. 部署：把 IMP core 部署到该 agent
function Deploy-<AgentName> {
  param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun)
  # 读 core 文件，加 frontmatter，写到 agent 位置
}

# 3. （可选）额外文件放 agents/<agent-name>-extras/
```

### 共享函数（dot-source _common.ps1）

| 函数 | 用途 |
|------|------|
| `Parse-CoreFile $path` | 解析 core 文件 frontmatter + body |
| `Build-Frontmatter $fm $fields` | 生成 YAML frontmatter（指定字段顺序） |
| `Get-CoreSkills $coreDir` | 获取 7 个 skill 文件 |
| `Get-CoreGlobalRules $coreDir` | 获取 global-rules.md 内容 |
| `Write-File $path $content` | 跨平台写文件（自动建目录） |
| `Expand-Path "~/..."` | 展开 ~ 路径 |
| `Upsert-IMPContent $path $content` | 以 "# IMP" 为标记 upsert |

### Frontmatter 处理

core skill 文件统一含 `name`, `description`, `whenToUse` 三个字段。
各 agent 按需选择：

| Agent | frontmatter 字段 |
|-------|-----------------|
| Windsurf | name, description（无 whenToUse） |
| DSH | name, description, whenToUse |
| Claude Code | 无 frontmatter（slash commands） |
| Codex | name, description, whenToUse |
| Hermes | name, description, whenToUse |
| OpenClaw | 无 frontmatter（AGENTS.md + 参考文件） |
| Pi Agent | 无 frontmatter（rules 目录 .md 文件） |
| WorkBuddy (腾讯) | name, description |
| Cursor | description, alwaysApply（Cursor 特有格式） |
| Devin | name, description |

### 项目级 vs 全局

- **全局 agent**（Windsurf, DSH, Claude Code, Codex）：部署到 `~/.<agent>/`，所有项目共享
- **项目级 agent**（Cursor, Devin）：部署到 `<项目>/.<agent>/`，需要每个项目单独跑
