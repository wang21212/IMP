# IMP Trace 事件规范

> 各项目 `<项目根>/.imp/trace/events.ndjson`，append-only，每行一条 JSON。
> imp-reflect 按此 schema 解析，用于评估 IMP 自身。

## 通用字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| ts | string (ISO 8601) | 是 | 事件时间戳，含时区 |
| project | string | 是 | 项目名（项目根目录名） |
| agent | string | 是 | 执行 agent 名（windsurf / dsh / devin / workbuddy / doubao / 其他） |
| skill | string | 是 | 触发事件 的 skill 名（imp-onboard / imp-intent / imp-feature / imp-architect / imp-debug / imp-verify / imp-reflect / global-rules） |
| level | string | 是 | 当时判定的级别（任务级 / 功能级 / 骨架级 / 新项目） |
| event | string | 是 | 事件类型（见下表） |
| outcome | string | 否 | pass / fail / upgrade / pending（视事件类型而定） |
| detail | string | 否 | 人类可读的简要说明 |

## 7 类事件

### 1. level_judged
**触发点**：global-rules Step 1 级别判定后
**必填字段**：ts, project, agent, skill="global-rules", level, event="level_judged", detail（一句话用户意图）
**示例**：
```json
{"ts":"2026-08-26T14:03:22+08:00","project":"IMP","agent":"windsurf","skill":"global-rules","level":"骨架级","event":"level_judged","detail":"给 IMP 加自迭代回路"}
```

### 2. intent_locked
**触发点**：imp-intent Phase 3 锁定后
**必填字段**：ts, project, agent, skill="imp-intent", level, event="intent_locked", detail（锁定意图一句话摘要）
**示例**：
```json
{"ts":"2026-08-26T14:10:01+08:00","project":"IMP","agent":"windsurf","skill":"imp-intent","level":"骨架级","event":"intent_locked","detail":"核心协议+平台适配层+自迭代回路"}
```

### 3. skin_bone_check
**触发点**：imp-feature Step 3 / imp-architect Step 3 / imp-debug Step 3 皮骨检查后
**必填字段**：ts, project, agent, skill, level, event="skin_bone_check", outcome（皮/骨/升级）, detail
**示例**：
```json
{"ts":"2026-08-26T14:20:15+08:00","project":"IMP","agent":"windsurf","skill":"imp-feature","level":"功能级","event":"skin_bone_check","outcome":"皮","detail":"只改 skill 文本，不动数据模型"}
```

### 4. verify_result
**触发点**：imp-verify 完成后
**必填字段**：ts, project, agent, skill="imp-verify", level, event="verify_result", outcome（pass/fail）, detail
**示例**：
```json
{"ts":"2026-08-26T14:30:00+08:00","project":"IMP","agent":"windsurf","skill":"imp-verify","level":"骨架级","event":"verify_result","outcome":"pass","detail":"build.ps1 生成 windsurf/dsh skill 成功"}
```

### 5. route_upgrade
**触发点**：任意 skill 触发升级路由时
**必填字段**：ts, project, agent, skill, level, event="route_upgrade", outcome="upgrade", detail（含 from→to 和原因）
**示例**：
```json
{"ts":"2026-08-26T14:15:30+08:00","project":"IMP","agent":"windsurf","skill":"imp-debug","level":"任务级","event":"route_upgrade","outcome":"upgrade","detail":"任务级→骨架级：修 bug 时发现需改数据模型"}
```

### 6. correction
**触发点**：imp-feature / imp-debug / imp-architect 执行中纠偏时
**必填字段**：ts, project, agent, skill, level, event="correction", detail（纠偏了什么 + 为什么）
**示例**：
```json
{"ts":"2026-08-26T14:25:00+08:00","project":"IMP","agent":"windsurf","skill":"imp-feature","level":"功能级","event":"correction","detail":"原计划改 6 个 skill，执行中发现 imp-onboard 也需改 trace 步骤，扩大范围"}
```

### 7. onboard
**触发点**：imp-onboard Phase 4 完成后
**必填字段**：ts, project, agent, skill="imp-onboard", level="新项目", event="onboard", detail（项目一句话描述）
**示例**：
```json
{"ts":"2026-08-26T09:00:00+08:00","project":"PodBase","agent":"windsurf","skill":"imp-onboard","level":"新项目","event":"onboard","detail":"接手 PodBase 项目，初始化 memory"}
```

## 写入规则

1. **append-only**：只追加，不修改/删除已有行
2. **一行一条**：严格 ndjson，每行一个完整 JSON 对象，行内无换行
3. **文件不存在则创建**：首次写入时 agent 应确保 `.imp/trace/` 目录存在
4. **失败不阻塞**：trace 写入失败不应阻塞 IMP 主流程，agent 静默跳过即可
5. **本机单用户**：不考虑并发写入冲突

## 文件生命周期

- v1 不做自动 rotate/清理
- 若文件膨胀影响 imp-reflect 性能，手动归档旧事件到 `events-YYYY-MM.ndjson`
