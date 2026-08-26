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
