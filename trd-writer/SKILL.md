---
name: trd-writer
description: Analyze an existing codebase and generate a Technical Requirements Document (TRD) using multi-agent architecture. Use when the user asks to generate a TRD from code, document the technical design of a project, reverse-engineer a tech spec from source code, or produce architecture documentation for an existing system.
---

# TRD Writer

Analyze a codebase using Coordinator + Workers + Merger multi-agent architecture, then generate a structured TRD.

## Goal

Produce a TRD that accurately describes an existing codebase's architecture, data models, interfaces, workflows, and design decisions. Use parallel sub-agents to handle large codebases without context window overflow.

## Hard Constraints

- All content must be derived from actual code. Never fabricate features.
- TRD must be written in the same language the user uses in conversation.
- Mark genuinely unclear system behavior/intent with `[INFERRED]` tags. Do NOT use `[INFERRED]` for bugs, code review, performance concerns, or standard patterns.
- No large code blocks — use type signatures, interface definitions, and short snippets only.
- All sub-agents **must write output to files** in `{project_root}/trd_work/`. Never rely on Task return value for long content.
- Max 4 parallel Worker agents per batch (Task tool limit).

## Workflow

All intermediate and final files are stored in `{project_root}/trd_work/`.

### Phase 1: Coordinator (1 sub-agent)

Launch **one** `generalPurpose` Task agent.

**Input**: project root path.

**Agent instructions** — the Coordinator must:

1. Scan directory tree, dependency files (`go.mod`, `package.json`, etc.), README, entry points.
2. Identify tech stack, module boundaries, core entities, and glossary.
3. Divide modules into Worker groups (max 4 per batch, merge small modules, split large ones).
4. **Write** the result to `{project_root}/trd_work/project_profile.md` using the Write tool.
5. Return a one-line confirmation with the file path.

**Project Profile schema** (Coordinator must follow):

```
# Project Profile: {name}
## Tech Stack (table: layer / technology / version)
## Project Structure (directory tree with descriptions)
## Module Assignment
### Worker 1: {group name}
| Module | Path | File Count |
### Worker 2: ...
### Worker 3: ...
### Worker 4: ...
## Core Entities (type names + source files)
## Glossary (term / definition table)
## Entry Point Analysis (startup flow summary)
```

**Stop condition**: Coordinator finishes when `project_profile.md` is written.

### Phase 2: Workers (up to 4 parallel sub-agents)

After Coordinator completes, read `project_profile.md` to get module assignments.

Launch **up to 4** parallel `generalPurpose` Task agents. Each Worker gets:

1. The full content of `project_profile.md` (embed in prompt as shared context).
2. The specific module paths assigned to this Worker.
3. An output file path: `{project_root}/trd_work/worker_{N}.md`.

**Agent instructions** — each Worker must:

1. Read all source files in assigned modules (skip `_test` files, generated code, `vendor/`, `node_modules/`).
2. Analyze each module following the **Worker Output Schema** below.
3. **Write** the full report to `{project_root}/trd_work/worker_{N}.md` using the Write tool.
4. Return a one-line confirmation with the file path.

**Worker Output Schema** (each module must follow this structure):

```
# Module: {name}

## Responsibility
One sentence.

## Key Files
| File Path | Role |

## Data Model
Struct/table/proto definitions with field types and descriptions.

## Interface
Exported functions, API endpoints, RPC definitions, interface types.

## Core Flow
Step-by-step description of key processes.

## Error Handling
Error types, retry patterns, fallback strategies.

## Dependencies
- Internal: [which other modules]
- External: [which libraries/services]

## Uncertain
Items marked [INFERRED] — ONLY for cases where system behavior or intent
genuinely cannot be determined from the code. See rules below.
```

**[INFERRED] usage rules** (Workers must follow strictly):

`[INFERRED]` means: "I read the code but cannot determine what the system does or why."

Use ONLY for:
- External system integration whose direction/purpose is unclear from code alone
- Commented-out code blocks whose original purpose cannot be determined
- Cross-system data sources where the origin is ambiguous
- Module responsibility that is genuinely unclear from naming and code

Do NOT mark as [INFERRED]:
- Bugs, logic errors, or incorrect implementations — these are code review, not TRD
- Performance concerns or optimization suggestions
- Code style, naming issues, or typos
- Standard framework/library usage patterns (e.g., `go build -ldflags`, gRPC-Gateway annotations)
- TODO/unimplemented features — document these factually in the relevant section (e.g., "currently unimplemented") without [INFERRED]
- Design improvement suggestions
- Security observations (e.g., hardcoded keys)

**Stop condition**: Worker finishes when its `worker_{N}.md` is written.

**Batching**: If modules require > 4 Workers, run in batches. Wait for batch 1 to complete before launching batch 2.

### Phase 3: Review (up to 4 parallel sub-agents)

After all Workers complete, the main agent performs these steps:

**Step 1 — Extract**: Use Grep to find all `[INFERRED]` items across `worker_*.md` files. If zero items found, skip to Phase 4.

**Step 2 — Dispatch**: Launch **up to 4** parallel `generalPurpose` Reviewer Task agents, one per Worker report that contains `[INFERRED]` items. Each Reviewer gets:

1. The content of its assigned `worker_{N}.md` (or the relevant [INFERRED] items from it).
2. The project root path for source code access.
3. An output file path: `{project_root}/trd_work/review_patches_worker_{N}.md`.

**Agent instructions** — each Reviewer must:

1. Read `{project_root}/trd_work/worker_{N}.md`.
2. Extract every `[INFERRED]` item from it.
3. For **each** item, read whatever source files are needed to verify — no file read limit. Either:
   - **Confirm**: inference is correct → replace with confirmed description + evidence.
   - **Correct**: inference is wrong → provide the correct description + evidence.
   - **Unresolvable**: genuinely cannot determine → mark `[UNRESOLVED]` with explanation.
4. **Write** results to `{project_root}/trd_work/review_patches_worker_{N}.md` using the Write tool.
5. Return a one-line confirmation with counts.

**Stop condition**: Each Reviewer finishes when its `review_patches_worker_{N}.md` is written. Max 2 rounds total (prevent infinite loops).

**Skip condition**: Skip entirely if zero `[INFERRED]` items exist across all Worker reports.

### Phase 4: Merger (1 sub-agent)

After Review completes (or is skipped), launch **one** `generalPurpose` Task agent.

**Agent instructions** — the Merger must:

1. Read `{project_root}/trd_work/project_profile.md`.
2. Read all `{project_root}/trd_work/worker_*.md` files.
3. Read all `{project_root}/trd_work/review_patches_worker_*.md` files if they exist (apply corrections).
4. Merge into a unified TRD following the **TRD Output Template** (see `reference.md` in this skill directory).
5. Apply merge rules:
   - Unify terminology using the glossary from Project Profile.
   - Deduplicate content across Worker reports.
   - Add cross-module sequence diagrams for end-to-end flows.
   - Generate Mermaid architecture diagram from module dependencies.
   - Generate Mermaid ER diagram from data models.
   - Reference real file paths.
   - Apply patches: replace `[INFERRED]` with confirmed/corrected descriptions. Any remaining `[UNRESOLVED]` items are noted inline in the relevant module section, not as a dedicated chapter.
   - No `[INFERRED]` should remain in the final TRD.
6. **Write** the final TRD to `{project_root}/trd_work/TRD.md` using the Write tool.
7. Return a one-line confirmation with the file path.

**Stop condition**: Merger finishes when `TRD.md` is written.

### Phase 5: Deliver

After Merger completes:

**Step 1 — Generate manifest** (for future incremental updates by `trd-updater`):

1. Read `project_profile.md` Module Assignment section.
2. Build a JSON object mapping module names to their directory paths, e.g.:
   ```json
   {"chain_apis":"chain/apis/","center":"center/","public_models":"public/models/"}
   ```
   Use normalized names (underscores, no parenthetical notes). Merge sub-modules that belong to the same directory.
3. Run: `python3 ~/.agents/skills/trd-writer/scripts/manifest.py {project_root} '<module_map_json>'`

The script gets git HEAD commit, runs `git ls-files` for each module path, and writes `{project_root}/trd_work/manifest.json`. Returns JSON to stdout.

**Step 2 — Present summary** to the user (no questions, just deliver):

- Total modules documented
- Key architecture highlights
- Number of `[UNRESOLVED]` items (if any)
- File path to the full TRD
- Manifest written (commit hash recorded for future incremental updates)

## Module Splitting Rules

The Coordinator uses these rules to assign modules to Workers:

1. Each top-level directory is one module.
2. Directory with > 50 files → split into sub-modules by subdirectory.
3. Directory with < 5 files → merge with a related directory.
4. Special directories (`proto/`, `migrations/`, `config/`, `test/`) → group by relevance.
5. Static assets, generated code, and `vendor/` → exclude from analysis.
6. Group modules by coupling (modules that import each other belong to the same Worker).
7. Balance file count across Workers (aim for roughly equal load).

## Verification Checklist

Before delivering, verify:

- [ ] All major modules are documented in the TRD.
- [ ] Architecture diagram matches actual code structure.
- [ ] File path references point to real files.
- [ ] Data model matches actual schema/struct definitions.
- [ ] API definitions match actual route/handler registrations.
- [ ] No fabricated features.
- [ ] No `[INFERRED]` tags remain — all resolved or marked `[UNRESOLVED]` inline.
- [ ] Mermaid diagrams are syntactically correct.
- [ ] Document language matches user's language.
- [ ] Cross-module flows have sequence diagrams.

## When NOT to Use This Skill

- Designing a new system — use a forward-design approach instead.
- User wants a PRD, not a technical doc.
- User wants a code review, not documentation.
- Codebase is a single script or trivial utility.
- Project has fewer than ~10 source files — a single-agent scan is sufficient, no need for multi-agent.
