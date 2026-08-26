# Direction — IMP 仓库自身

IMP（Intent Management Protocol）是跨平台 AI 协作的意图管理协议。本仓库是 IMP 的源仓库，自身也由 IMP 管理（自举）。

## 骨架现状

- **三层结构**：
  - Layer 1 入口路由：`core/global-rules.md`（核心）→ 各平台壳
  - Layer 2 编排逻辑：`core/imp-*.md`（7 个核心 skill）→ 各平台壳
  - Layer 3 状态存储：各项目 `.imp/memory/`（4 文件）+ `.imp/trace/`（事件流）
- **核心协议**：`core/` 下平台无关 SOP，唯一修改源
- **平台适配层**：`adaptors/<platform>/` 下薄壳，含 frontmatter 和工具映射
- **构建机制**：`scripts/build.ps1` 把核心注入壳生成最终 skill
- **自迭代回路**：trace 采集 → `.imp/trace/events.ndjson` → `imp-reflect` 评估 → 改进项入 intent-log → 迭代 IMP 自身

## 技术栈

- 核心协议：Markdown（平台无关）
- 构建脚本：PowerShell（本机单用户，Windows）
- 状态存储：Markdown + ndjson
- 平台：Windsurf、DSH（已适配）；WorkBuddy、豆包（预留扩展位）

## 核心约束

1. `core/` 是唯一修改源，禁止直接改 `windsurf/` 或 `dsh/` 下的生成文件
2. 平台适配壳只含 frontmatter + 工具映射，不含 SOP 逻辑
3. `.imp/memory/` 跨平台共享，路径固定为 `<项目根>/.imp/memory/`
4. trace 是 append-only ndjson，schema 见 `core/trace-spec.md`
5. IMP 仓库自身迭代走 IMP 标准流程（自举）
