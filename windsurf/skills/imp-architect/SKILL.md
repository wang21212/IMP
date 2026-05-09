---
name: imp-architect
description: IMP 骨架级变更流程 — 影响分析→强制人工书面确认→由下至上执行（数据→服务→API→前端）→更新 direction.md。最重流程，未经明确确认禁止任何代码变更。进入前已完成 imp-intent 意图锁定。
---

# IMP Architect — 骨架变更流程

## ⚠️ 强制规则：未经人工书面确认，禁止任何骨架级代码变更

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

### Step 2: 人确认（强制暂停）

输出分析报告，等用户明确回复「确认执行」，**禁止自动推断同意**。

### Step 3: 执行顺序（由下至上）

数据层 → 服务层 → API 层 → 前端层，每层完成调用 imp-verify

### Step 4: 更新 direction.md + milestone-state.md

更新 `.windsurf/memory/direction.md` 骨架现状。

若本次骨架变更产出了里程碑规划（如 M0-Mn），将里程碑列表写入 `.windsurf/memory/milestone-state.md`。每条里程碑只记：编号、一句话目标、状态（待开始/进行中/已完成/需重评）。里程碑规划是粗线条路标，不是详细 spec——后续每个里程碑开始时会重新跑意图循环。

### Step 5: 写入 session-state

更新 `.windsurf/memory/session-state.md`。

session-state 只写下次对话必须知道的最少信息，详略由 AI 自决：骨架变更影响面大，可适当多写，但不超过5行。格式：变更内容 / 执行进度（哪层完成/未完成）/ 下一步。
