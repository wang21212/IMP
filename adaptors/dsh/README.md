# IMP → DHS（DeepSeek Harness）移植

本目录是 IMP 协议在 **DHS（DeepSeek Harness，本机 ~/.dsh 部署的 Web GUI 会话环境）** 中的完整移植，与 `windsurf/` 目录同源同构。三层结构一一映射：

| IMP 概念 | Windsurf 版 | DHS 版 |
|----------|-------------|--------|
| Layer 1 全局入口规则 | `windsurf/global_rules.md`（追加到 ~/.codeium/windsurf/memories/global_rules.md） | `preset/agent.cordis.yml` 的 persona（IMP 模式预设）；同时以 skill「imp」形式随会话目录自动出现 |
| Layer 2 六个 Skill | `windsurf/skills/imp-*/SKILL.md` | `skills/imp-*/SKILL.md` → `~/.dsh/skills/` |
| Layer 3 项目 Memory | `[项目]/.imp/memory/`（与 DHS 统一，跨工具共享） | `[项目]/.imp/memory/` |

**状态根统一为 `.imp/memory/`**：Windsurf / DHS / Claude Code / Cursor 读写同一份，换工具不丢上下文。旧版 `.windsurf/memory/` 用 `migrate-memory.ps1` 一键迁移。

## 文件清单

```
dsh/
  skills/
    imp/SKILL.md            # 入口路由：断点恢复 + 四级分类 + 强制约束 + DHS 工具映射
    imp-intent/SKILL.md     # 意图三循环（描述→细化→可行性），goal 工具锁定 + intent-log
    imp-onboard/SKILL.md    # 接手/新项目初始化，自动迁移 .windsurf/memory/
    imp-debug/SKILL.md      # 任务级执行
    imp-feature/SKILL.md    # 功能级迭代（todo_write 拆解）
    imp-architect/SKILL.md  # 骨架级变更（DHS 经 plan mode 强制确认）
    imp-verify/SKILL.md     # 落地验证（结构化输出）
  preset/
    preset.yml              # preset 元数据（name: IMP 模式）
    agent.cordis.yml        # persona = 全局入口规则 + standard 全量工具集
  deploy-dsh.ps1            # 一键部署到 ~/.dsh/
  migrate-memory.ps1        # .windsurf/memory/ → .imp/memory/ 迁移脚本
  README.md                 # 本文件
```

## 安装

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy-dsh.ps1
```

或 VSCode 任务（Ctrl+Shift+B → "IMP: Deploy to DSH"）。

部署后：
1. **Skills 自动生效**：DHS 新会话的技能目录会自动列出 7 个 imp-* 技能（无需重启服务；若未见，重启 DSH Web 或新开会话）。
2. **全局入口规则**（可选，推荐）：把 `~/.dsh/settings.yaml` 中 `agent-presets.default` 改为 `imp`，之后每个新会话都以 IMP 模式运行（persona 内置 Step 0/1/2 入口规则）；或保持默认 preset，仅靠 skill「imp」在会话中按需加载。注意：**skill 是全局的，不选 IMP 模式也能用 IMP**。
3. **项目 Memory**：在目标项目目录中开新会话，说「接手项目 / 帮我看看这个项目」，触发 imp-onboard 自动扫描并初始化 `.imp/memory/`；已有旧版 `.windsurf/memory/` 的项目先跑 `migrate-memory.ps1 -Project <路径>`。

## 骨架级确认：绑定 DHS plan mode（区别于 Windsurf 版）

DHS 的 plan mode 是平台底层机制：plan 模式下模型物理上无法修改文件，必须 `exit_plan_mode` 提交计划并经批准后才可执行。imp-architect 的「人确认」在 DHS 中分两级：

1. **首选**：请用户将会话切换到 plan mode，把骨架变更计划（影响分析 + 执行顺序 + 回滚方案）经 `exit_plan_mode` 提交审批；获批后才开始改代码。
2. **回退**：用户不切 plan mode 时，等用户明确文字回复「确认执行」，禁止自动推断同意。

Windsurf 等无 plan mode 的平台沿用纯文字确认。这解决了「二次编排 vs 底层编排冲突」的核心顾虑：骨架级确认从 IMP 的 markdown 约定升级为平台原生强制，两层指令不再打架。

## DHS 原生能力映射

| IMP 环节 | DHS 原生工具 |
|----------|--------------|
| 意图锁定（跨轮长任务） | goal 工具（create_goal / get_goal / update_goal），与 intent-log.md 互补 |
| 任务拆解（imp-feature Step 2） | todo_write |
| 细化澄清 / 关键确认 | ask_user_question（逐轮、一次一组） |
| 骨架级强制确认 | plan mode（exit_plan_mode 获批后才执行） |
| 断点恢复 | read 读取 session-state.md |
| 执行 / 验证 | read/write/edit/glob/grep + pwsh（长任务 run_in_background） |

## 与 Windsurf 版的关系

- 协议内容完全同源，状态根统一为 `.imp/memory/`（跨工具共享同一份 memory）。DHS 版新增：goal/todo/plan-mode 原生绑定与 frontmatter（description/whenToUse）。
- 旧版 `.windsurf/memory/` 状态用 `migrate-memory.ps1` 迁移一次即可，之后两工具读写同一份。
