# IMP — Intent Management Protocol

> 一套让人与 AI 协作时「意图不丢失、骨架不失控、上下文不断层」的工作协议。

---

## 为什么需要 IMP

过去一年深度使用 AI Coding 工具的过程中，我反复遇到同一类问题——

不是 AI 不够聪明，而是**意图在传递过程中不断衰减**。

你说了一个需求，AI 理解了一个版本，执行了另一个版本，验证了第三个版本。每一步都有偏差，叠加起来就是「做了很多，但方向偏了」。

更深层的问题是：**人与 AI 之间的协作，本质上是一个意图管理问题。**

- 人的意图往往是模糊的、渐进的——很多时候是「越做越明白」
- AI 的理解是有噪音和丢失的——上下文窗口有限，每次对话都是新的起点
- 任务的复杂度是分层的——改一行 bug 和改数据模型是完全不同量级的事

IMP 就是为了解决这三件事：**把意图管理、分层治理、状态持久化，做成一套可以在任意项目上运行的协议。**

---

## 核心理念

### 一、意图是一切的起点

在任何工作开始前，最重要的问题不是「怎么做」，而是「要做什么、为什么做、做到什么程度算完」。

意图管理包含三个层面：

- **意图对齐**：人和 AI 对同一件事的理解是否一致
- **意图涌现**：很多意图在执行过程中才会变清晰，框架要允许这个过程，而不是强迫一开始就锁死
- **意图完备度**：意图不是越详细越好，也不是越简单越好——大事要讲清楚，小事点到即止

IMP 的 `imp-intent` Skill 将这个过程结构化为三个阶段：描述 → 细化 → 可行性验证，并用三维度评估（横向冲突 × 纵向兼容 × 意图完备度）防止意图未成熟就开始执行。

### 二、骨与皮要分开治理

任何软件项目都有两种性质不同的变更：

- **骨**（Skeleton）：数据模型、架构边界、部署拓扑、核心接口——一旦破坏代价极高
- **皮**（Feature）：在稳定骨架上叠加的功能——可以快速迭代、频繁变更

这两类变更混在一起处理，是功能迭代破坏架构的根本原因。

IMP 强制区分这两类变更，骨架级改动必须经过影响分析和人工确认，不允许 AI 自行推进。功能级改动则在骨架约束下自由发挥。

### 三、保底不封顶

框架的职责是**划定底线，而不是设置天花板**。

IMP 的规则只做两件事：
1. 保证某些关键动作一定会发生（意图对齐、骨架确认、落地验证）
2. 保证某些危险动作一定不会发生（未确认就改骨架、做完不验证）

在这个底线之上，AI 有完全的自主判断空间——意图日志写多详细、验证方式选哪种、任务怎么拆分，都由 AI 根据具体情况自决。

**规则越少越好，但必须守住。**

这也意味着 IMP 不用枚举所有场景。级别判定本身是递归的：骨架级任务拆解后，每个子任务重新判级；功能级执行中发现需改骨架，升级路由。大事套中事套小事，同一套判定逻辑在每个粒度上复用。用涌现代替枚举，而不是不断加 imp-xxx 来覆盖新场景。

### 四、状态持久化，上下文可恢复

AI 没有长期记忆，每次对话都是全新开始。这是结构性限制，不是 bug。

IMP 的应对方案是：**把需要跨对话保留的状态，以结构化 Markdown 文件的形式存在项目里**。每次对话开始时读取，结束前写入。

这样无论换了什么 AI、什么机器、什么时间，只要打开项目，上下文就在那里。

---

## 框架结构

IMP 仓库采用「核心协议 + agent 部署脚本」架构，无 build 步骤，无产物目录：

```
core/              核心协议（平台无关，唯一修改源）
  global-rules.md     入口路由器
  imp-*.md            7 个 skill（含 frontmatter）
  imp-trace-spec.md   trace 事件规范

agents/            agent 部署脚本（每个 agent 一个薄脚本）
  _common.ps1         共享函数（解析 core、写文件、upsert）
  windsurf.ps1        部署到 ~/.codeium/windsurf/
  dsh.ps1             部署到 ~/.dsh/
  claude-code.ps1     部署到 ~/.claude/
  codex.ps1           部署到 ~/.codex/ + ~/.agents/
  cursor.ps1          部署到 <项目>/.cursor/rules/
  devin.ps1           部署到 <项目>/.devin/skills/
  dsh-extras/         DSH 平台额外文件（preset、tool-mapping）
  README.md           如何添加新 agent

install.ps1        唯一入口：scan / all / specific agent
scripts/           discover-projects.ps1（扫描本机 IMP 项目）
```

**核心设计**：`core/` 是唯一修改源。`install.ps1` 读 `core/`，运行时加 frontmatter，直接写到各 agent 的配置位置。没有 build 步骤，没有产物目录，没有占位符注入。

运行时三层：

```
Layer 1: Global Rules（入口路由器）
  每次对话自动加载，判断问题级别，路由到对应 Skill
  → Windsurf: ~/.codeium/windsurf/memories/global_rules.md
  → Claude Code: ~/.claude/CLAUDE.md
  → Codex: ~/.codex/AGENTS.md
  → DSH: ~/.dsh/skills/imp/SKILL.md（入口 skill）

Layer 2: Global Skills（编排逻辑）
  7 个 Skill，覆盖全部工作场景，包含完整 SOP
  → Windsurf: ~/.codeium/windsurf/skills/imp-*/SKILL.md
  → Claude Code: ~/.claude/commands/imp-*.md
  → Codex: ~/.agents/skills/imp-*/SKILL.md
  → DSH: ~/.dsh/skills/imp-*/SKILL.md

Layer 3: Project Memory（状态存储）
  4 个 Markdown 文件，持久化项目状态，跨对话保持上下文
  → 存放位置：[项目根]/.imp/memory/（跨工具统一状态根，所有 agent 共享）
```

### 7 个 Skill

| Skill | 职责 | 触发时机 |
|-------|------|----------|
| `imp-onboard` | 接手/新项目初始化，扫描项目上下文，创建 Memory 文件 | 开始新项目或接手已有项目 |
| `imp-intent` | 意图三循环——描述→细化→可行性验证，三维度评估后锁定意图 | 功能级或骨架级工作开始前 |
| `imp-feature` | 功能迭代流程——拆解任务、皮骨检查、逐任务执行+验证 | 意图锁定后，新增/修改功能 |
| `imp-architect` | 骨架变更流程——影响分析、人工确认、由下至上执行 | 需改数据模型/架构/部署时 |
| `imp-debug` | Bug 修复流程——复现→定位→皮骨检查→最小改动 | 修复已有功能错误行为 |
| `imp-verify` | 落地验证——每个工作单元完成后必须执行，输出结构化结果 | 任何工作单元完成后 |
| `imp-reflect` | 自迭代评估——汇聚本机所有项目 trace，识别模式，产出评估报告和候选改进项 | 用户说「评估 IMP」时 |

### 4 个 Memory 文件

| 文件 | 存储内容 | 更新时机 |
|------|----------|----------|
| `direction.md` | 项目骨架现状、技术栈、核心约束 | onboard 初始化 / 每次骨架变更后 |
| `intent-log.md` | 意图锚点日志，记录每次锁定的意图 | 每次 imp-intent 完成后追加 |
| `milestone-state.md` | 里程碑追加快照（最新版本在顶部，含 diff 标注） | 里程碑状态变更时追加新版本 |
| `session-state.md` | 对话断点——任务/进展/下一步 | 每次对话结束前写入 |

### 四级问题分类

| 级别 | 判定标准 | 执行路径 |
|------|----------|----------|
| 任务级 | 执行明确指令（修 bug、跑验收、小调整等），不新增能力，不改接口 | imp-debug |
| 功能级 | 新增或修改功能，骨架不动 | imp-intent → imp-feature |
| 骨架级 | 改数据模型 / 架构 / 部署 / 接口签名 | imp-intent → imp-architect |
| 新项目 | 首次接手或初始化项目 | imp-onboard |

---

## 安装

### 一键安装（推荐）

```powershell
git clone https://github.com/wang21212/IMP.git
cd IMP
pwsh install.ps1
```

installer 会：
1. 扫描本机已安装的 agent（Windsurf / DSH / Claude Code / Codex / Cursor / Devin）
2. 列出检测到的 agent，让你选择部署到全部或某一个
3. 读 `core/`，加 frontmatter，直接写到各 agent 的配置位置

### 命令行模式

```powershell
pwsh install.ps1 scan                    # 只扫描，不部署
pwsh install.ps1 all                     # 部署到所有检测到的 agent
pwsh install.ps1 windsurf                # 只部署到 Windsurf
pwsh install.ps1 windsurf dsh            # 部署到 Windsurf + DSH
pwsh install.ps1 all --dry-run           # 干跑，只显示会做什么
pwsh install.ps1 cursor --target=/path   # 项目级 agent 部署到指定项目
```

### 支持的 Agent

| Agent | 部署位置 | 类型 |
|-------|----------|------|
| Windsurf (Cascade) | `~/.codeium/windsurf/` | 全局 |
| DSH (DeepSeek Harness) | `~/.dsh/` | 全局 |
| Claude Code | `~/.claude/` | 全局 |
| Codex (OpenAI CLI) | `~/.codex/` + `~/.agents/` | 全局 |
| Cursor | `<项目>/.cursor/rules/` | 项目级 |
| Devin | `<项目>/.devin/skills/` | 项目级 |

### 初始化项目 Memory

安装 IMP 到 agent 后，在目标项目中**新开一个对话**，说「接手项目」，触发 `imp-onboard`。

AI 会自动扫描项目结构，产出接手备忘录，并在项目根目录创建 `.imp/memory/` 及 4 个 Memory 文件。

### 添加新 Agent

IMP 的 agent 定义：LLM 控制的、通过 read/write/create/delete 操作文件实现用户需求的多步骤操作实体。

添加新 agent 只需在 `agents/` 下创建一个 `<agent-name>.ps1`，实现 detect + deploy 两个 action。详见 `agents/README.md`。

---

## 日常使用

安装完成后，每次**新开对话**时 IMP 自动生效，无需手动触发。

AI 在每次对话开始会：

1. 检查 `session-state.md`——有断点则询问是否继续上次任务
2. 判断问题级别，输出 `[IMP] 级别: xxx`
3. 路由到对应 Skill，按 SOP 执行

你只需要正常描述你的需求，IMP 在背后保证流程的严谨性。

---

## 添加新 Agent

IMP 的 agent 定义：LLM 控制的、通过 read/write/create/delete 操作文件实现用户需求的多步骤操作实体。

任何工具只要具备三点就能适配：
- 全局系统提示注入（对应 Global Rules）
- 可复用的 Prompt 片段或命令（对应 Skills）
- 可读写本地 Markdown 文件（对应 Project Memory）

在 `agents/` 下创建 `<agent-name>.ps1`，实现 detect + deploy 两个 action：

```powershell
param([string]$CoreDir, [string]$AgentsDir, [switch]$DryRun, [string]$Action = "deploy")

. "$AgentsDir/_common.ps1"

switch ($Action) {
  "detect" {
    if (Test-Path "~/.your-agent") { Write-Output "found" } else { Write-Output "notfound" }
    exit 0
  }
  "deploy" {
    # 读 core，加 frontmatter，写到 agent 位置
    $globalRules = Get-CoreGlobalRules $CoreDir
    $skills = Get-CoreSkills $CoreDir
    # ... 写到 ~/.your-agent/ 的对应位置
  }
}
```

然后在 `install.ps1` 的 `$agentRegistry` 数组里加一行。详见 `agents/README.md`。

---

## 未来方向

IMP 目前是 v1，核心流程已经稳定，但有几个方向值得继续深化：

- **意图管理精进**：意图完备度评估、大事/小事自适应深化、人与 AI 之间意图传递的噪音处理
- **验证体系升级**：更细粒度的验证分级，兜底的同时给高质量验证留空间
- **多平台实现**：Claude Code、Cursor 的完整移植版本
- **AI 与 AI 协作**：多 Agent 场景下意图协议如何扩展，如何用命名空间隔离各 Agent 状态，避免状态竞争

---

## License

MIT