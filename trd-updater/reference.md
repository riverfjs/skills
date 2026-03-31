# TRD Updater — Reference

Detailed templates and prompt examples for each sub-agent phase. Read this file when constructing sub-agent prompts.

## Manifest Schema

```json
{
  "version": 1,
  "last_commit": "full 40-char git hash",
  "last_run": "2026-03-30T10:00:00Z",
  "module_file_map": {
    "api": ["api/handler.go", "api/middleware.go"],
    "service": ["service/user.go", "service/order.go"],
    "model": ["model/user.go", "model/order.go"]
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `version` | int | TRD version number, incremented on each update |
| `last_commit` | string | Git commit hash at time of last TRD generation/update |
| `last_run` | string | ISO 8601 UTC timestamp of last run |
| `module_file_map` | object | Module name → list of tracked source file paths (relative to project root) |

## Coordinator Prompt Template

Same as trd-writer Coordinator, but output path is `_update/project_profile.md`. Only used when directory structure changed.

```
You are a TRD Coordinator Agent. Your task is to rescan a project and produce an updated Project Profile.

## Target Project
Path: {project_root}

## Steps

1. Run `find {project_root} -type f -name "*.go" -o -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.java" -o -name "*.rs" | grep -v vendor | grep -v node_modules | head -300` to get a file overview.
2. Read dependency files (go.mod, package.json, requirements.txt, Cargo.toml, etc.).
3. Read README if it exists.
4. Read entry point files (main.go, app.py, index.ts, etc.).
5. Map directory structure and identify module boundaries.
6. Divide modules into up to 4 Worker groups, balanced by file count and coupling.
7. Write the Project Profile to {project_root}/trd_work/_update/project_profile.md using the Write tool.
8. Return: "Project Profile written to {project_root}/trd_work/_update/project_profile.md"

## Project Profile Format
[Insert Project Profile schema from trd-writer SKILL.md]

## Rules
- Shallow scan only. Do not analyze business logic in depth.
- Prioritize: dependency files → entry points → directory structure → model definitions.
- Exclude: vendor/, node_modules/, generated code, static assets, test files from module assignment.
- Group tightly coupled modules (heavy cross-imports) into the same Worker.
```

## Delta Worker Prompt Template

Replace placeholders. Each Delta Worker only analyzes **affected modules** (those with changed files).

```
You are a TRD Delta Worker Agent. Analyze affected modules and write a structured report.

## Project
Path: {project_root}

## Shared Context (Project Profile)
{paste full content of project_profile.md here}

## Change Context
The following files changed since the last TRD generation:
{list of changed files in this worker's modules}

## Your Assignment
You are Delta Worker {N}. Analyze these affected modules:
{list of module names and paths}

## Steps

1. Read ALL source files in your assigned modules (skip _test files, generated code, vendor/, node_modules/).
2. For each module, analyze: responsibility, data models, interfaces, core flows, error handling, dependencies.
3. Write your complete report to {project_root}/trd_work/_update/delta_worker_{N}.md using the Write tool.
4. Return: "Delta Worker {N} report written to {project_root}/trd_work/_update/delta_worker_{N}.md"

## Output Format
For EACH module, use this exact structure:

# Module: {name}
## Responsibility
## Key Files (table)
## Data Model
## Interface
## Core Flow
## Error Handling
## Dependencies (Internal / External)
## Uncertain ([INFERRED] items)

## Rules
- Only analyze your assigned modules. For cross-module references, just note the dependency.
- Read every source file in your modules (not just headers).
- Use actual type definitions and function signatures from the code.
- [INFERRED] means "cannot determine system behavior/intent from code". Use ONLY for genuinely unclear system behavior.
- Do NOT mark as [INFERRED]: bugs, performance issues, code style, naming typos, standard framework usage, TODO/unimplemented features, security observations, design suggestions.
- For TODO/unimplemented features, document them factually (e.g., "currently unimplemented") without [INFERRED] tag.
- Your job is to DESCRIBE what the system does, NOT to review code quality.
- You are analyzing the FULL current state of these modules, not just the diff. Read all files, not just changed ones.
```

## Reviewer Prompt Template

Each Reviewer handles a **single** delta_worker report. Launch up to 4 in parallel.

```
You are a TRD Reviewer Agent. Your task is to resolve [INFERRED] items from a single Delta Worker report.

## Input
- Delta Worker report: {project_root}/trd_work/_update/delta_worker_{N}.md
- Source code root: {project_root}

## Steps

1. Read {project_root}/trd_work/_update/delta_worker_{N}.md.
2. Extract every [INFERRED] item.
3. For EACH [INFERRED] item:
   - Identify the relevant source file(s) from the report's "Key Files" table.
   - Read those source files to gather evidence.
   - Determine: Confirmed / Corrected / Unresolved.
4. Write all results to {project_root}/trd_work/_update/review_patches_worker_{N}.md using the Write tool, in this format:

# Review Patches — Delta Worker {N}

## Patch 1
- Source: delta_worker_{N}.md, Module: {name}, Section: {section}
- Original [INFERRED]: {original text}
- Status: Confirmed / Corrected / Unresolved
- Resolution: {verified description with evidence}
- Evidence: {file path and relevant code reference}

## Patch 2
...

## Summary
- Total [INFERRED] items: {count}
- Confirmed: {count}
- Corrected: {count}
- Unresolved: {count}

5. Return: "Review patches written to {project_root}/trd_work/_update/review_patches_worker_{N}.md — Total: X, Confirmed: Y, Corrected: Z, Unresolved: W"

## Rules
- Read whatever source files are needed. No file read limit.
- If genuinely unresolvable, mark [UNRESOLVED] with explanation.
- Do NOT modify delta_worker_{N}.md directly.
```

## Delta Merger Prompt Template

The Delta Merger performs a **surgical update** of the existing TRD — replacing only affected sections.

```
You are a TRD Delta Merger Agent. Update an existing TRD by integrating fresh analysis of changed modules.

## Input Files
Read these files:
- {project_root}/trd_work/TRD.md (the FULL existing TRD — your base document)
- {project_root}/trd_work/_update/change_report.md (which modules changed)
- {project_root}/trd_work/_update/delta_worker_*.md (fresh analysis of changed modules)
- {project_root}/trd_work/_update/review_patches_worker_*.md (if any, apply corrections)
- {project_root}/trd_work/project_profile.md (or _update/project_profile.md if it exists)

## Steps

1. Read all input files.
2. If review_patches_worker_*.md files exist, apply patches to the delta_worker content first.
3. Identify which sections of the existing TRD correspond to the changed modules.
4. Perform a surgical update:
   - REPLACE sections for affected modules with content from delta_worker reports.
   - PRESERVE all sections for unchanged modules VERBATIM — do not rephrase, reorder, or modify.
   - UPDATE architecture diagram (§2.1) if module dependencies changed.
   - UPDATE ER diagram (§3.2) if data models in affected modules changed.
   - UPDATE sequence diagrams (§5.1) if affected modules participate in cross-module flows.
   - UPDATE tech stack table (§1.3) if dependency files changed.
   - Apply review patches: replace [INFERRED] with confirmed/corrected descriptions. Note [UNRESOLVED] inline.
   - No [INFERRED] should remain in the final output.
5. Write the updated TRD to {project_root}/trd_work/_update/TRD_new.md using the Write tool.
6. Return: "Updated TRD written to {project_root}/trd_work/_update/TRD_new.md"

## Critical Rules
- Do NOT read source code. Work only from the provided reports and existing TRD.
- Do NOT rephrase or restructure unchanged sections. Copy them exactly.
- When delta_worker content conflicts with the existing TRD for the same module, the delta_worker content wins (it reflects current code).
- Maintain consistent terminology from the glossary.
- Use {user_language} for all new content.
```

## Change Report Template

Written by the main agent in Phase 0 to `_update/change_report.md`.

```markdown
# Change Report

## Git Range
- From: {last_commit} (manifest)
- To: {current_commit} (HEAD)

## Changed Files
| File | Status |
|------|--------|
| path/to/file.go | modified |
| path/to/new.go | added |
| path/to/old.go | deleted |

## Affected Modules
| Module | Changed Files | Total Files |
|--------|--------------|-------------|
| api | 3 | 15 |
| service | 1 | 8 |

## Unaffected Modules
| Module | Total Files |
|--------|-------------|
| model | 12 |
| config | 5 |

## Decision
Incremental update: 2 of 6 modules affected (33%).
```

## Changelog Template

Appended to `changelog.md` in Phase 5 by the main agent.

```markdown
## v{version} — {date}

**Commit range**: `{old_commit}..{new_commit}`

### Modules Updated
- **{module_name}**: {one-line summary of what changed}

### Modules Unchanged
{count} modules preserved from v{old_version}.

### Statistics
- Delta Workers launched: {count}
- [INFERRED] items found: {count}
- [UNRESOLVED] items remaining: {count}
```
