---
name: imp
description: IMP（Intent Management Protocol）全局入口路由 — 每次对话/每个新任务先按此执行：断点恢复 → 四级问题分类（任务级/功能级/骨架级/新项目）→ 路由到 imp-* 技能，保证意图不丢失、骨架不失控、上下文不断层。
whenToUse: 每次对话开始或收到新的开发协作请求时必读；用户提及「IMP」「意图管理」「接手项目」「继续上次」时优先触发。
---

# IMP 全局入口规则（DHS 版）

IMP = Intent Management Protocol（意图管理协议）。本技能是 DHS 中的 Layer 1「入口路由器」，与 Windsurf 版 global_rules.md 同源（仓库 windsurf/global_rules.md），仅把工具与状态路径映射到 DHS。

## 状态位置（Layer 3）

项目级 Memory 文件存放在 **<项目根>/.imp/memory/**（协议统一状态根：Windsurf / DHS / 其他平台读写同一份，换工具不丢上下文）：

| 文件 | 内容 | 更新时机 |
|------|------|----------|
| direction.md | 骨架现状、技术栈、核心约束 | onboard 初始化 / 每次骨架变更后 |
| intent-log.md | 意图锚点日志 | 每次 imp-intent 锁定后追加 |
| milestone-state.md | 里程碑追加快照（最新在顶部） | 里程碑状态变更时 |
| session-state.md | 对话断点（任务/进展/下一步） | 每次对话结束前 |

- 未找到 .imp/memory/ 时，先查项目根的 .windsurf/memory/；存在则按 imp-onboard 的导入流程迁移。
- 当前会话未落在具体项目目录时，把状态根落在会话工作区根（pwd 目录）下。

## Step 0: 断点恢复（每次对话必执行）

用 read 检查 <state-root>/session-state.md：

- 存在 → 读取，回复开头输出：
  [IMP] 上次断点: {任务} | 层级: {级别} | 进展: {描述} | 下一步: {描述}
  然后问：「继续上次 / 开始新任务？」
- 不存在 → 进入 Step 1

## Step 1: 问题级别判定（收到请求后，执行前必判）

输出一行（禁止跳过）：
[IMP] 级别: [任务级/功能级/骨架级/新项目] → 意图三循环: [需要/跳过]

| 级别 | 触发条件 | 意图三循环 | 路由 Skill |
|------|----------|-----------|-----------|
| 任务级 | 执行明确指令（修 bug、跑验收、小调整等），不新增能力，不改接口 | 可跳过 | imp-debug |
| 功能级 | 新增/修改功能；可能改 API 但不改核心模型/架构 | 必须执行 | imp-intent → imp-feature |
| 骨架级 | 改数据模型/部署拓扑/核心模块边界/配置结构 | 必须执行 | imp-intent → imp-architect |
| 新项目 | 无 state-root 或用户说「接手/新项目」 | 包含在 onboard 内 | imp-onboard |

级别判定是**递归的**：骨架级任务拆解后每个子任务重新判级；功能级执行中发现需改骨架则升级路由。大事套中事套小事，同一套判定逻辑在每个粒度复用，无需新增 Skill。

三个执行 Skill（imp-debug / imp-feature / imp-architect）是同一套「皮骨检查 → 执行 → 验证」逻辑在不同粒度上的实例。

## Step 2: 强制约束（任何级别均适用）

1. **骨架级禁令**：判定为骨架级后，禁止直接执行任何代码变更，必须先完成 imp-intent + 影响分析 + 人确认（DHS 中优先请用户切换 plan mode、经 exit_plan_mode 获批，见 imp-architect Step 2）。
2. **验证禁令**：任何修改完成后，禁止只说「已完成」，必须执行 imp-verify 并输出验证结果。
3. **状态同步**：每次对话结束前，自动更新 <state-root>/session-state.md。

## DHS 原生工具映射

| IMP 环节 | DHS 对应 |
|----------|----------|
| 意图锁定（跨轮长任务） | 调用 goal 工具 create_goal 建立持久目标（get_goal/update_goal 维护），同时写 intent-log.md |
| 任务拆解 | todo_write 建立结构化任务列表 |
| 细化澄清 / 关键确认 | ask_user_question 单轮提问（一次只问一组问题，遵守 imp-intent「逐轮、最多 5 问」） |
| 执行 | 文件工具（read/write/edit/glob/grep）+ pwsh |
| 验证 | 同上 + 运行测试/脚本，输出 [IMP-Verify] 结构化结果 |
| 项目扫描 | glob/grep/read 或 pwsh（git log 等） |