---
name: imp-feature
description: IMP 功能级迭代流程 — 读取项目上下文，任务拆解（3-7个），皮骨可行性检查，逐任务执行并验证，更新里程碑状态。进入前已完成 imp-intent 意图锁定。
---

# IMP Feature — 功能迭代流程

## 适用范围

N→N.1 迭代，骨架不动，新增或修改一个功能单元。
（进入此 Skill 前已完成 imp-intent，意图已锁定）

## 流程

### Step 1: 读取项目上下文 + 对当前里程碑重新判级

读 `direction.md`（目标与约束）、`milestone-state.md`（所属里程碑）。

若当前里程碑标记为 `[需重评]` 或前序里程碑的完成改变了当前前提，先对本里程碑重新跑意图循环（递归回 imp-intent），不盲目继续上次的计划。

### Step 2: 任务拆解（3-7 个可独立验证单元）

基于锁定意图，拆解任务列表，输出供用户确认。

### Step 3: 皮骨可行性检查

- 需改数据模型？→ 标记 [需骨架评估]，升级至 imp-architect，退出此流程
- 骨架能支撑？→ 否则暂停
- 通过 → 继续

### Step 4: 逐任务执行 + 逐任务调用 imp-verify

每个任务完成后立即验证，不积累到最后。

### Step 5: 更新 milestone-state.md，写入 session-state

更新 `.windsurf/memory/milestone-state.md`：将当前里程碑标记为「已完成」，记录实际完成内容。若本次完成改变了后续里程碑的前提假设，将受影响的里程碑标注 `[需重评]`。

更新 `.windsurf/memory/session-state.md`。

session-state 只写下次对话必须知道的最少信息，详略由 AI 自决：简单任务一行，复杂任务不超过5行。格式：任务 / 当前进展 / 下一步。
