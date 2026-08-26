---
name: imp
description: IMP（Intent Management Protocol）全局入口路由 — 每次对话/每个新任务先按此执行：断点恢复 → 四级问题分类（任务级/功能级/骨架级/新项目）→ 路由到 imp-* 技能，保证意图不丢失、骨架不失控、上下文不断层。
whenToUse: 每次对话开始或收到新的开发协作请求时必读；用户提及「IMP」「意图管理」「接手项目」「继续上次」「评估 IMP」时优先触发。
---

# IMP 全局入口规则（DHS 版）

<!-- IMP-CORE-INJECT: global-rules -->

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
