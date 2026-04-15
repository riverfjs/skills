# Agent 技能目录（`~/.agents/skills`）

本目录存放**个人级、跨项目**的 Agent 技能。每个技能是一个文件夹，**必须**包含 `SKILL.md`（YAML 头信息 + 执行说明）。运行时根据 `description` 等字段判断何时启用该技能。

## 目录结构

```
<skill-name>/
├── SKILL.md           # 必填：name、description、流程说明
├── scripts/           # 可选：脚本/CLI 等
├── reference.md       # 可选：详细参考
└── examples/          # 可选：示例
```

**存放范围**

| 路径 | 作用域 |
|------|--------|
| `~/.agents/skills/<name>/` | 本机所有项目可用 |
| `<项目>/.agents/skills/<name>/` | 仅该仓库 |

## 本目录包含的技能

| 技能 | 说明 |
|------|------|
| **chrome-cdp** | 通过 WebSocket 使用 Chrome DevTools Protocol 的轻量 CLI：列出标签页、执行 `eval`、点击、导航等。**仅在用户明确同意**调试或操作本机已打开的 Chrome 时使用。需开启远程调试、Node 22+。 |
| **skill-creator** | 新建或迭代技能的规范：目录结构、frontmatter、`description` 写法与行文原则。 |
| **trd-writer-full** | 已废弃的旧版 TRD 流水线，仅保留作参考；当前请优先使用 `trd-writer-v2`。 |
| **trd-updater** | 待更新。当前增量 TRD 刷新流程尚未同步到最新的 TRD writer 工作流。 |

**TRD 状态：** `trd-writer-full` 已废弃，`trd-updater` 待更新。

## 新增或修改技能

1. 按 **skill-creator**（`skill-creator/SKILL.md`）命名、写 frontmatter，并保持正文简洁。
2. 若无特殊要求，`SKILL.md` 正文建议用**英文**，便于各环境稳定触发。

## 相关说明

- 上层配置与设计说明可能在 `~/.agents/`（如设计文档）。
- 仅某项目需要的技能，可在该项目下建立 `.agents/skills/`，结构与本目录相同。
