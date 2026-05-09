---
name: imp-onboard
description: IMP 接手/新项目初始化 — 扫描项目上下文，产出接手备忘录，自动初始化项目级 Memory 文件（direction.md / intent-log.md / milestone-state.md / session-state.md）。
---

# IMP Onboard — 接手/新项目初始化

## 触发条件

Global Rules 判定为「新项目」或用户说「接手/断点继续/新项目」

## 执行流程

### Phase 1: 扫描（自动）

按顺序读取：

1. 项目根目录文件列表（读多少自行判断）
2. README.md
3. 最近 N 条 git log
4. .agent/plan.md、task-queue.md（若有）
5. .windsurf/memory/ 全部文件（若有，含 direction.md / intent-log.md / milestone-state.md / session-state.md）

### Phase 2: 产出接手备忘录

```
# 接手备忘录 — {项目名} — {日期}

## 骨架现状（Skeleton）
- 核心技术栈：
- 主要模块边界：
- 骨架稳定度：[稳定/有疑问/未知]

## 功能现状（Spec）
- 已实现能力：
- 进行中能力：
- 已知缺口：

## 当前级别判定
- [ ] 骨架级  - [ ] 功能级  - [ ] 任务级维护

## 上次断点
- 描述：（来自 session-state.md 或 git log）

## 建议下一步（3 选项）
1. 继续上次工作 → {描述}
2. 开始新方向  → {描述}
3. 先探索了解  → 生成项目结构图
```

### Phase 3: 人确认（强制暂停）

展示备忘录，等用户选择选项。

### Phase 4: 自动初始化项目级 Memory

若 `.windsurf/memory/` 不存在，创建：

- `direction.md`（根据扫描结果填充）
- `intent-log.md`（空文件，首行写 `# Intent Log`）
- `milestone-state.md`（空文件，首行写 `# Milestone State`；后续按追加快照模式写入，格式见 imp-architect Step 4）
- `session-state.md`（空模板）
