---
name: imp
description: IMP（Intent Management Protocol）全局入口路由 — 每次对话/每个新任务先按此执行：断点恢复 → 四级问题分类（任务级/功能级/骨架级/新项目）→ 路由到 imp-* 技能，保证意图不丢失、骨架不失控、上下文不断层。
whenToUse: 每次对话开始或收到新的开发协作请求时必读；用户提及「IMP」「意图管理」「接手项目」「继续上次」「评估 IMP」时优先触发。
---

# IMP 全局入口规则（DHS 版）

# IMP 全局入口规则（核心协议）

> 状态根统一为 `<项目根>/.imp/memory/`（跨工具共享：Windsurf / DHS / Devin / WorkBuddy / 豆包 / 其他平台读写同一份）。旧版 `.windsurf/memory/` 状态请用 `dsh/migrate-memory.ps1` 迁移。

## Step 0: 断点恢复（每次对话必执行）
检查 `.imp/memory/session-state.md`：
- 存在 → 读取，回复开头输出：
  "[IMP] 上次断点: {任务} | 层级: {级别} | 进展: {描述} | 下一步: {描述}"
  然后问：「继续上次 / 开始新任务？」
- 不存在 → 进入 Step 1

## Step 1: 问题级别判定（收到请求后，执行前必判）
输出一行（禁止跳过）：
  "[IMP] 级别: [任务级/功能级/骨架级/新项目] → 意图三循环: [需要/跳过]"

判定标准：
| 级别   | 触发条件                                        | 意图三循环  | 路由 Skill      |
|--------|------------------------------------------------|------------|------------------|
| 任务级  | 执行明确指令（修 bug、跑验收、小调整等），不新增能力，不改接口  | 可跳过      | imp-debug       |
| 功能级  | 新增/修改功能；可能改 API 但不改核心模型/架构      | 必须执行    | imp-intent → imp-feature |
| 骨架级  | 改数据模型/部署拓扑/核心模块边界/配置结构         | 必须执行    | imp-intent → imp-architect |
| 新项目  | 无 .imp/memory/ 或用户说「接手/新项目」      | 包含在 onboard 内 | imp-onboard |

级别判定是**递归的**：一个骨架级任务拆解后，每个子任务重新判级；功能级任务执行中若发现需改骨架，升级路由。大事套中事套小事，同一套判定逻辑在每个粒度上复用，无需新增 Skill。

三个执行 Skill（imp-debug / imp-feature / imp-architect）是同一套「皮骨检查 → 执行 → 验证」逻辑在不同粒度上的实例，不是三条平行独立的路径。

## Step 2: 强制约束（任何级别均适用）
1. 骨架级禁令：判定为骨架级后，禁止直接执行任何代码变更，必须先完成 imp-intent + 影响分析 + 人确认
2. 验证禁令：任何修改完成后，禁止只说「已完成」，必须执行 imp-verify 并输出验证结果
3. 状态同步：每次对话结束前，自动更新 `.imp/memory/session-state.md`

## Step 3: 自迭代回路（IMP 自身）
当 cwd 为 IMP 源仓库本身时，IMP 走自身流程迭代自身（自举）：
- IMP 仓库根的 `.imp/memory/` 存 IMP 自身的项目状态（direction/intent-log/milestone/session）
- 各项目（含 IMP 仓库自身）的 IMP 执行事件流写入各自的 `.imp/trace/events.ndjson`
- 用户说「评估 IMP」时触发 imp-reflect，汇聚本机所有项目 trace，产出评估报告和候选改进项
- 候选改进项写入 IMP 仓库 `.imp/memory/intent-log.md`，等用户拍板后走 imp-intent → imp-architect/imp-feature 迭代 IMP 自身
- 迭代 IMP 自身时，`core/` 是唯一修改源，禁止直接改 `windsurf/` 或 `dsh/` 下的生成文件

## Step 4: 自迭代评估入口（元回路，不走级别判定）
当用户说「评估 IMP」「imp-reflect」「回看 IMP」「迭代 IMP」时，**跳过 Step 1 级别判定**，直接路由到 imp-reflect。imp-reflect 不是开发任务，是 IMP 对自身的元评估，不属于四级问题分类。imp-reflect 产出的候选改进项才是开发任务，那些改进项再走标准 Step 1 级别判定。

## DHS 原生工具映射

| IMP 环节 | DHS 对应 |
|----------|----------|
| 意图锁定（跨轮长任务） | 调用 goal 工具 create_goal 建立持久目标（get_goal/update_goal 维护），同时写 intent-log.md |
| 任务拆解 | todo_write 建立结构化任务列表 |
| 细化澄清 / 关键确认 | ask_user_question 单轮提问（一次只问一组问题，遵守 imp-intent「逐轮、最多 5 问」） |
| 执行 | 文件工具（read/write/edit/glob/grep）+ pwsh |
| 验证 | 同上 + 运行测试/脚本，输出 [IMP-Verify] 结构化结果 |
| 项目扫描 | glob/grep/read 或 pwsh（git log 等） |
| 骨架级人确认 | 优先请用户切换 plan mode、经 exit_plan_mode 获批（见 imp-architect Step 2） |
