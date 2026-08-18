---
name: imp-architect
description: IMP 骨架级变更流程 — 影响分析→强制人工书面确认→由下至上执行（数据→服务→API→前端）→更新 direction.md。最重流程，未经明确确认禁止任何代码变更。DHS 版强制要求 ask_user_question 或明确书面确认。进入前已完成 imp-intent 意图锁定。
whenToUse: 由 imp-intent 锁定骨架级意图后；涉及数据模型/部署拓扑/核心模块边界/配置结构变更时。
---

# IMP Architect — 骨架变更流程

## ⚠️ 强制规则：未经人工确认（DHS 优先经 plan mode 获批），禁止任何骨架级代码变更

## 适用范围

改数据模型 / 改部署拓扑 / 改核心模块边界 / 改配置结构
（进入此 Skill 前已完成 imp-intent，意图已锁定）

## 流程

### Step 1: 变更影响分析（产出报告）

```
## 骨架变更影响分析
### 变更内容：
### 影响范围：
  - 数据层（Model/Migration/Schema）：
  - 服务层（Service/Repository/Worker）：
  - API 层（接口签名变化）：
  - 部署层（docker-compose/config）：
  - 前端层（组件/类型定义）：
### 不可逆风险：
### 回滚方案：
```

### Step 2: 人确认（强制暂停，DHS 用 plan mode 兜底）

输出分析报告，**禁止自动推断同意**。DHS 中确认分两级：

1. **首选（DHS 原生强制确认）**：请用户将会话切换到 **plan mode**，然后在 plan mode 中把「骨架变更计划」（即 Step 1 的影响分析报告 + 执行顺序 + 回滚方案）通过 `exit_plan_mode` 提交审批。plan mode 是平台底层机制——计划获批前模型物理上无法修改文件，比文字约定硬一个数量级。**仅当 plan 获批（exit_plan_mode 返回 approved）后**，才退出 plan mode 进入 Step 3 执行。
2. **回退（用户不切换 plan mode 时）**：等用户明确回复「确认执行」；可用 ask_user_question 发起正式确认。用户未明确确认前，不得进入 Step 3。

> Windsurf 等无 plan mode 的平台继续使用纯文字确认（明确回复「确认执行」）。

### Step 3: 执行顺序（由下至上）

数据层 → 服务层 → API 层 → 前端层，每层完成调用 imp-verify。

### Step 4: 更新 direction.md + milestone-state.md

更新 <state-root>/direction.md 骨架现状。

若本次骨架变更产出了里程碑规划（如 M0-Mn），在 <state-root>/milestone-state.md **文件顶部追加一个完整版本快照**。里程碑规划是粗线条路标，不是详细 spec——后续每个里程碑开始时会重新跑意图循环。

milestone-state.md 采用**追加快照模式**（最新版本在文件最上方）：

```
---
# [v1] {日期} — {本次变更摘要}

| 编号 | 目标 | 状态 | 备注 |
|------|------|------|------|
| M0 | {一句话目标} | ⏳ 待开始 | |
| M1 | {一句话目标} | ⏳ 待开始 | |
...
```

- 每条里程碑记：编号、一句话目标、状态（⏳ 待开始 / 🔄 进行中 / ✅ 已完成 / 🔁 需重评）、备注
- 有变化的行在备注列标注 diff: {变化说明}
- AI 平时只读最新版本（文件顶部到第一个 --- 分隔线），需要回溯时才往下看历史版本

### Step 5: 写入 session-state

更新 <state-root>/session-state.md。

session-state 只写下次对话必须知道的最少信息，详略由 AI 自决：骨架变更影响面大，可适当多写，但不超过5行。格式：变更内容 / 执行进度（哪层完成/未完成）/ 下一步。