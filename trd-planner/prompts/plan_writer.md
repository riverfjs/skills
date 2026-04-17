# Plan Writer Prompt — Phase 2 of trd-planner

Your job: take the Phase 1 (`scanner.md`) draft and produce the final
`{project_root}/TRD_PLAN.md` by filling `plan_template.md`.

## Inputs

- `{project_root}` (absolute path)
- Phase 1 draft (modules table + exclusions list)
- `{tech_stack}` string
- Today's date (YYYY-MM-DD)

## Hard Constraints

- Always read `plan_template.md` first; copy its template block verbatim, then fill placeholders.
- Always keep all 5 Analysis-Convention section headers, even if you trim bullets.
- Always run the **Forbidden-Fields Self-Check** (below) before writing the file.
- Always derive module rows from Phase 1's actually-counted file list. Never re-count or invent.
- Never add sections not present in `plan_template.md`.
- Never add a "Worker 拆分" / "执行顺序" / "架构概览" / mermaid block. The template explicitly forbids these.
- Never fill execution-record blocks with non-blank content (status starts as `⏳ 待开始`).

## Workflow

### Step 1: Skeleton (optional)

If the project has no `TRD_PLAN.md` yet, you may bootstrap a skeleton:

```bash
bash ~/.claude/skills/trd-planner/scripts/generate_plan.sh {project_root} "{tech_stack}"
```

The script writes a placeholder file. You will overwrite it in Step 2 with the
filled template — the script just gives you a starting point.

### Step 2: Fill the template

Open `plan_template.md`, copy the block between `<!-- BEGIN TRD_PLAN.md -->` and
`<!-- END TRD_PLAN.md -->`, and substitute every `{{placeholder}}`:

| Placeholder | Source |
|-------------|--------|
| `{{project_root}}` | input |
| `{{project_name}}` | `basename {project_root}` or manifest module name |
| `{{tech_stack}}` | input |
| `{{entry_points}}` | scanner output |
| `{{date}}` | today |
| `{{exclusions_bullet_list}}` | scanner exclusions, one bullet per line |
| `{{module_count}}` | length of scanner module list |
| `{{module_rows}}` | one row per module, in scanner order |
| `{{format_rules}}` ... `{{inferred_rules}}` | start from `plan_template.md` defaults; tweak nouns/paths to the project; keep ≤ 6 bullets per section |
| `{{execution_blocks}}` | one blank 4-line block per module; status = `⏳ 待开始` |

### Step 3: Customize Analysis Conventions

For each of the 5 sections, take the default bullets from `plan_template.md`
("Default Bullets for Analysis Conventions") and edit so that:

- Project name and module nouns are concrete (e.g. "在 UCI v2 中" instead of "in {project_name}")
- Cross-path examples mention this project's actual layout (e.g. proto ↔ model ↔ service for UCI; `internal/data/gorm/model/` for Kratos)
- Detail-depth bullets call out this project's load-bearing things (signing algorithms, state machines, cron schedules — whatever scanner found)

Never delete a section. Never reduce a section to a single sentence.

### Step 4: Forbidden-Fields Self-Check (MANDATORY)

Before writing, scan your draft text for any of these:

| Forbidden | Pattern |
|-----------|---------|
| Worker counts / slicing | `Worker`, `切片`, `Vertical Slice`, `Sub-task` |
| Execution order suggestion | `执行顺序`, `Execution Order`, `执行优先级`, `推荐顺序` |
| Layered architecture prose | `架构概览`, `Architecture Overview` (as a section heading) |
| Diagrams | ` ```mermaid `, `flowchart`, `sequenceDiagram` |
| Filled execution records | any non-blank `开始时间` / `完成时间` / a non-`⏳ 待开始` status |

If any pattern hits, delete the offending text and re-check. Only proceed when clean.

### Step 5: Write the file

Use the Write tool to save the filled template to `{project_root}/TRD_PLAN.md`.
Do not write anywhere else. Do not leave behind temp files.

### Step 6: Post-write verification

Run:

```bash
grep -nE "Worker|切片|Vertical Slice|执行顺序|Execution Order|架构概览|Architecture Overview|mermaid|flowchart|sequenceDiagram" {project_root}/TRD_PLAN.md
```

Expected: zero matches (unless a module name legitimately contains one of these
substrings — then accept and move on).

```bash
grep -c "^### " {project_root}/TRD_PLAN.md
```

Expected: 5 (analysis conventions) + N (execution blocks).

## Return value

Report to the orchestrator (SKILL.md Phase 3):

```
TRD_PLAN.md written: {project_root}/TRD_PLAN.md
Modules: {N}
In-scope source files: ~{sum of file_count}
Forbidden-field check: PASS
```
