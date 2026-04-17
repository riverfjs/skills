---
name: trd-planner
description: Scan a project and produce TRD_PLAN.md — a module catalog with shared analysis conventions for downstream trd-writer-v2. Use before writing any TRD when the project has multiple modules. Produces only module list + exclusions + analysis conventions; never prescribes Worker counts, vertical slices, or execution order.
---

# TRD Planner

Produce a `TRD_PLAN.md` that catalogs modules and shared conventions, so `trd-writer-v2` can pick up each module independently.

## Goal

Write exactly one `{project_root}/TRD_PLAN.md` containing:

1. Project info (path, tech stack, date)
2. Exclusion rules
3. Module list (table: name / path / file count / TRD output / status)
4. Analysis Conventions (5 sections, all modules must follow)
5. Empty execution-record blocks (one per module, filled by execution phase)

## Hard Constraints

- Always produce exactly one `TRD_PLAN.md` at `{project_root}/TRD_PLAN.md`.
- Always list modules and shared analysis conventions only. Never prescribe Worker counts, vertical slices, file-to-Worker mappings, or recommended execution order — that is the coordinator's job inside `trd-writer-v2`.
- Always include an **分析规范 / Analysis Conventions** section covering: TRD format, project-context statement, cross-path lookup, detail depth, `[INFERRED]` handling.
- Always group modules by **business domain** when one is identifiable (e.g. `member` vs `sumsub`). Fall back to architectural layer (`apis/`, `internal/service/`, `cmd/`) only when no domain split exists.
- Always derive module file counts from `find ... | wc -l` actually executed; never invent numbers.
- Always read `prompts/scanner.md` before scanning, and `prompts/plan_writer.md` before writing.
- Never embed per-module TRD content, Worker prompts, or `trd-writer-v2` execution detail.
- Never duplicate the rules from `prompts/*.md` here — this file is the entry, not the rulebook.

## File Structure

```
trd-planner/
├── SKILL.md                # This file (entry)
├── plan_template.md        # Strict TRD_PLAN.md template + forbidden-fields list
├── prompts/
│   ├── scanner.md          # Phase 1: scan + identify modules
│   └── plan_writer.md      # Phase 2: fill template, run forbidden-field self-check
└── scripts/
    ├── generate_plan.sh    # Emits skeleton TRD_PLAN.md (placeholders only)
    └── update_status.sh    # Used by trd-writer-v2 to mark module status
```

## Workflow

Strict three-phase order. Do not skip.

### Phase 1 — Scan

Read `prompts/scanner.md`. Follow it to:
- Run scan commands (depth-limited `find`, file counts by extension)
- Decide module boundaries (business-domain first; architectural layer fallback)
- Build the exclusion list (defaults + tech-stack additions)

Output of this phase stays in conversation: a draft module list (name, paths, file count) and a final exclusion list.

### Phase 2 — Write

Read `prompts/plan_writer.md`. Follow it to:
- (Optional) Run `bash scripts/generate_plan.sh {project_root} "{tech_stack}"` to emit the skeleton
- Fill every placeholder in `plan_template.md` using the Phase 1 draft
- Customize the 5 Analysis-Convention sections to the project (never delete a section)
- Run the forbidden-fields self-check (see `plan_writer.md`) before saving
- Save to `{project_root}/TRD_PLAN.md`

### Phase 3 — Verify & Report

Run these checks against the saved file:

```bash
grep -nE "Worker|切片|vertical slice|执行顺序|Execution Order" {project_root}/TRD_PLAN.md
# Expected: 0 matches

grep -c "^### " {project_root}/TRD_PLAN.md
# Expected: at least 5 (analysis conventions) + N (execution records)
```

Report to user:
- Total modules: N
- Total in-scope source files: ~N
- Plan location: `{project_root}/TRD_PLAN.md`
- Next step: hand off each module to `trd-writer-v2`

## Output

See `plan_template.md` for the exact `TRD_PLAN.md` structure and the forbidden-fields list.

## When NOT to Use

- Project has < 50 in-scope source files and no obvious module split — call `trd-writer-v2` directly.
- A `TRD_PLAN.md` already exists at the target path — read it instead of regenerating.
- User wants a single-module deep-dive — skip planning, go straight to `trd-writer-v2`.
