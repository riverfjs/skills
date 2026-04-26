# Agent Skills (`~/.agents/skill`)

Private, cross-project **agent skills**. Each skill is a folder with a required `SKILL.md` (YAML frontmatter + instructions). The runtime discovers skills and uses the `description` field to decide when to apply them.

## Layout

```
<skill-name>/
├── SKILL.md           # required: name, description, workflow
├── scripts/           # optional helpers (e.g. CLI)
├── reference.md       # optional deep docs
└── examples/          # optional samples
```

**Scopes**

| Location | Scope |
|----------|--------|
| `~/.agents/skill/<name>/` | All projects on this machine |
| `<project>/.agents/skills/<name>/` | That repository only |

## Skills in this directory

| Skill | Summary |
|-------|---------|
| **chrome-cdp** | Chrome DevTools Protocol CLI over WebSocket: list tabs, eval, clicks, navigation. Use only after the user explicitly approves inspecting or driving a local Chrome session. Requires remote debugging and Node 22+. |
| **hk-ipo-multi-compare** | Produces a Hong Kong IPO analysis report for one or more listings using prospectus extraction, peer financials, and sourced markdown output. |
| **skill-creator** | Authoring guide for new or updated skills: structure, frontmatter, description quality, and conventions. |
| **trd-planner** | Scans a complex project and produces a TRD execution plan with module breakdown, exclusions, and progress tracking. Use before `trd-writer-v2` on larger repos. |
| **trd-writer-v2** | Active TRD pipeline for generating zero-loss technical requirement documents from code modules using direct worker-written sections. |
| **trd-writer-full** | Deprecated legacy TRD pipeline. Kept for reference only; prefer `trd-writer-v2` for active use. |
| **trd-updater** | Pending update. Incremental TRD refresh from a prior manifest-based run is not yet synced with the latest TRD workflow. |

**TRD status:** Use `trd-planner` + `trd-writer-v2` for current TRD work. `trd-writer-full` is deprecated, and `trd-updater` is pending update.

## Adding or changing skills

1. Follow **skill-creator** (`skill-creator/SKILL.md`) for naming, frontmatter, and concise instructions.
2. Keep `SKILL.md` in **English** for consistent triggering unless your tooling specifies otherwise.

## Related

- Parent config and design notes may live under `~/.agents/` (e.g. design docs).
- For project-only skills, mirror the same folder layout under the project’s `.agents/skills/`.

## Links

- Friendly link: [Linux.do](https://linux.do)
