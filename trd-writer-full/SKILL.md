---
name: trd-writer-new
description: Analyze an existing codebase and generate a Technical Requirements Document (TRD) using multi-agent architecture. Use when the user asks to generate a TRD from code, document the technical design of a project, reverse-engineer a tech spec from source code, or produce architecture documentation for an existing system.
---

# TRD Writer

Analyze a codebase using Coordinator + Workers + Merger multi-agent architecture, then generate a structured TRD.

## Goal

Produce a TRD that accurately describes an existing codebase's architecture, data models, interfaces, workflows, and core algorithms. The document should enable readers to understand the codebase without reading source code.

## Hard Constraints

- All content must be derived from actual code. Never fabricate features.
- TRD must be written in the same language the user uses in conversation.
- Mark genuinely unclear system behavior/intent with `[INFERRED]` tags. Do NOT use `[INFERRED]` for bugs, code review, performance concerns, or standard patterns.
- No large code blocks — use type signatures, interface definitions, and short snippets only. Exception: core business formulas/algorithms should be documented in full.
- All sub-agents **must write output to files** in `{project_root}/trd_work/`. Never rely on Task return value for long content.
- **Max 10 parallel Worker agents per batch**. If more Workers needed, run in batches.
- **TRD format must strictly follow `reference.md` template**. Do NOT add metadata like generation time, file paths, or document info sections.

## TRD Format Requirements

### Title Format

**For complete project analysis**:
```
# {Project Name} — Technical Requirements Document (TRD)
```

**For sub-module analysis (when project is split into batches)**:
```
# {module_path} — Technical Requirements Document (TRD)
```

### Project Summary Requirements (Section 1.1)

**When analyzing a sub-module** (i.e., project split into multiple TRDs by directory), the Project Summary MUST:
1. Clearly state this is a sub-module of the parent project
2. Explain the module's role and responsibilities within the larger system
3. Describe relationships with other modules (dependencies, data flow, API calls)

**When analyzing a complete project**, describe the project normally.

### Forbidden Elements
- Document generation time/date
- File path metadata sections
- "Document Info" or similar meta-sections
- Any content not derived from actual code

## Cross-Path Analysis Requirements

Workers and Reviewers are **NOT limited to the assigned directory**. They MUST:

1. **Search across the entire project** for related files:
   - Database models may be in `app/common/model/`, shared libraries, or other locations
   - Configuration files may be in project root `config/`, `.env`, or module-specific config directories
   - Shared utilities may be in `lib/`, `utils/`, `common/`, etc.

2. **Trace dependencies fully**:
   - Follow imports/requires to understand data flow
   - Check database table definitions wherever they are defined
   - Verify external service integrations across module boundaries

3. **Resolve [INFERRED] items by cross-path investigation**:
   - Reviewers must search the entire project, not just the Worker's assigned path
   - Only mark as [UNRESOLVED] after exhaustive cross-path search

## Deep Analysis Requirements

Since TRD is generated per module (not entire project at once), each module deserves **thorough analysis**:

1. **Core business logic must be fully documented**:
   - Do NOT summarize with "etc." or "..."
   - List ALL API endpoints, not just "key" ones
   - Document ALL state machine states and transitions
   - Record ALL algorithm variants (e.g., long/short, different asset types)

2. **Root-level files require individual attention**:
   - `controller/*.php` — each file is a distinct controller, analyze individually
   - `command/*.php` — each file is a distinct CLI command, analyze individually
   - `model/*.php` — each file is a distinct data model, analyze individually
   - Do NOT group as "Root Controllers (Selected)" — list and analyze ALL

3. **For large directories (>50 files)**:
   - Split into multiple Workers (e.g., A-M and N-Z)
   - Each Worker handles fewer files with deeper analysis

## TRD Structure Overview

The final TRD follows this structure (details in `reference.md`):

```
1. Project Overview
   1.1 Project Summary
   1.2 Tech Stack
   1.3 Project Structure
   1.4 Glossary

2. Architecture
   2.1 System Architecture
   2.2 Module Breakdown
   2.3 External Dependencies

3. Data Model
   3.1 Entity Definitions
   3.2 Entity Relationships
   3.3 Data Flow

4. Interface Design
   4.1 External Interfaces
   4.2 Internal Interfaces
   4.3 External Integrations

5. Core Logic
   5.1 Primary Flows
   5.2 Core Algorithms
   5.3 Background Processes
   5.4 State Transitions

6. Runtime Configuration
   6.1 Configuration Items
   6.2 Deployment

7. Observability
   7.1 Logging
   7.2 Monitoring & Alerting
   7.3 Error Handling

8. File Index
```

## Workflow

All intermediate and final files are stored in `{project_root}/trd_work/`.

### Phase 1: Coordinator (1 sub-agent)

Launch **one** `generalPurpose` Task agent.

**Input**: project root path.

**Agent instructions** — the Coordinator must:

1. Scan directory tree, dependency files (`go.mod`, `package.json`, etc.), README, entry points.
2. Identify tech stack, module boundaries, core entities, and glossary.
3. Divide modules into Worker groups:
   - **Max 10 Workers per batch** (if more needed, plan for multiple batches)
   - For large directories (>100 files), split into multiple Workers
   - Root-level files (e.g., `controller/*.php`) should have dedicated Workers
4. **Write** the result to `{project_root}/trd_work/project_profile.md` using the Write tool.
5. Return a one-line confirmation with the file path.

**Project Profile schema** (Coordinator must follow):

```
# Project Profile: {name}
## Project Summary (2-3 sentences describing what this project does)
## Tech Stack (table: layer / technology / version)
## Project Structure (directory tree with descriptions)
## Module Assignment
### Worker 1: {group name}
| Module | Path | File Count |
### Worker 2: ...
(up to Worker 10, or indicate batching needed)
## Core Entities (type names + source files)
## Glossary (term / definition table)
## Entry Point Analysis (startup flow summary)
```

**Stop condition**: Coordinator finishes when `project_profile.md` is written.

### Phase 2: Workers (up to 10 parallel sub-agents)

After Coordinator completes, read `project_profile.md` to get module assignments.

Launch **up to 10** parallel `generalPurpose` Task agents. Each Worker gets:

1. The full content of `project_profile.md` (embed in prompt as shared context).
2. The specific module paths assigned to this Worker.
3. An output file path: `{project_root}/trd_work/worker_{N}.md`.

**Agent instructions** — each Worker must:

1. Read **ALL** source files in assigned modules (skip `_test` files, generated code, `vendor/`, `node_modules/`).
2. **Cross-path search** for related files (models, configs, utilities) in other directories.
3. Analyze each module following the **Worker Output Schema** below.
4. **Write** the full report to `{project_root}/trd_work/worker_{N}.md` using the Write tool.
5. Return a one-line confirmation with the file path.

**Worker Output Schema** (each module must follow this structure):

```
# Module: {name}

## Responsibility
One sentence.

## Key Files
| File Path | Role |

(List ALL files, not just "selected" ones)

## Data Model
Struct/table/proto definitions with field types and descriptions.

## Interface
Exported functions, API endpoints, RPC definitions, interface types.

(List ALL endpoints/functions, not just "key" ones)

## Core Flow
Step-by-step description of key processes.

## Core Algorithms
Document key business formulas, calculation logic, and algorithms. For each:
- **Name**: Function/method name and file path
- **Purpose**: What it calculates/decides
- **Formula**: Mathematical formula or pseudocode (use LaTeX: `$formula$`)
- **Variables**: Explain each variable/parameter
- **Variants**: Different cases (e.g., by direction, mode, asset type) — document ALL variants

Skip only if module contains no core business logic.

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

**Batching**: If modules require > 10 Workers, run in batches. Wait for batch 1 to complete before launching batch 2.

### Phase 3: Review (up to 10 parallel sub-agents)

After all Workers complete, the main agent performs these steps:

**Step 1 — Extract**: Use Grep to find all `[INFERRED]` items across `worker_*.md` files. If zero items found, skip to Phase 4.

**Step 2 — Dispatch**: Launch **up to 10** parallel `generalPurpose` Reviewer Task agents, one per Worker report that contains `[INFERRED]` items. Each Reviewer gets:

1. The content of its assigned `worker_{N}.md` (or the relevant [INFERRED] items from it).
2. The project root path for source code access.
3. An output file path: `{project_root}/trd_work/review_patches_worker_{N}.md`.

**Agent instructions** — each Reviewer must:

1. Read `{project_root}/trd_work/worker_{N}.md`.
2. Extract every `[INFERRED]` item from it.
3. For **each** item:
   - **Cross-path search**: Look in the ENTIRE project, not just the Worker's assigned path
   - Read whatever source files are needed to verify — no file read limit
   - Check database definitions, config files, related modules
   - Either:
     - **Confirm**: inference is correct → replace with confirmed description + evidence.
     - **Correct**: inference is wrong → provide the correct description + evidence.
     - **Unresolvable**: genuinely cannot determine after exhaustive search → mark `[UNRESOLVED]` with explanation of what was searched.
4. **Write** results to `{project_root}/trd_work/review_patches_worker_{N}.md` using the Write tool.
5. Return a one-line confirmation with counts.

**Stop condition**: Each Reviewer finishes when its `review_patches_worker_{N}.md` is written. Max 2 rounds total (prevent infinite loops).

**Skip condition**: Skip entirely if zero `[INFERRED]` items exist across all Worker reports.

### Phase 4: Merger (Layered Approach)

After Review completes (or is skipped), calculate total lines in all `worker_*.md` files.

**Decision Logic**:
- If total lines **< 5000**: Launch **one** Merger agent (simple merge)
- If total lines **>= 5000**: Launch **Section Mergers** in parallel, then **Final Merger** (layered merge)

#### Simple Merge (< 5000 lines)

Launch **one** `generalPurpose` Task agent to merge all content into `TRD.md`.

#### Layered Merge (>= 5000 lines)

**Phase 4a: Section Mergers (up to 5 parallel)**

Based on project_profile.md Worker assignments, group Workers by TRD section:

| Section Merger | TRD Sections | Typical Worker Sources |
|----------------|--------------|------------------------|
| Merger A | 1-2 (Overview + Architecture) | project_profile.md + all workers (summary) |
| Merger B | 3 (Data Model) | Workers handling model/* files |
| Merger C | 4 (Interface Design) | Workers handling controller/* files |
| Merger D | 5 (Core Logic) | Workers handling logic/*, command/* files |
| Merger E | 6-8 (Config + Observability + Index) | Workers handling config/*, validate/*, library/* |

Each Section Merger:
1. Reads only the relevant `worker_*.md` files for its section
2. Reads `review_patches_worker_*.md` if they exist
3. Writes to `{project_root}/trd_work/section_{A|B|C|D|E}.md`
4. **Preserves ALL detail** — no summarization

**Phase 4b: Final Assembly (shell command)**

After all Section Mergers complete, assemble via shell command:

```bash
# Create TRD header
echo "# {module_path} — Technical Requirements Document (TRD)" > TRD.md
echo "" >> TRD.md

# Concatenate sections (skip section file headers)
tail -n +2 section_A.md >> TRD.md
tail -n +1 section_B.md >> TRD.md
tail -n +1 section_C.md >> TRD.md
tail -n +1 section_D.md >> TRD.md
tail -n +1 section_E.md >> TRD.md
```

No additional agent needed — Section Mergers already produced properly formatted content.

**Merger Rules (apply to all mergers)**:
- **Title format**: `# {module_name} — Technical Requirements Document (TRD)`
- **No metadata**: Do NOT add generation time, file paths, or document info sections
- **Preserve ALL detail**: Do NOT summarize, truncate, or use "etc."
- Unify terminology using the glossary
- Apply review patches
- Reference real file paths
- No `[INFERRED]` should remain

**Stop condition**: Phase 4 finishes when `TRD.md` is written.

### Phase 5: Deliver

After Merger completes:

**Step 1 — Generate manifest** (for future incremental updates by `trd-updater`):

1. Read `project_profile.md` Module Assignment section.
2. Build a JSON object mapping module names to their directory paths, e.g.:
   ```json
   {"chain_apis":"chain/apis/","center":"center/","public_models":"public/models/"}
   ```
   Use normalized names (underscores, no parenthetical notes). Merge sub-modules that belong to the same directory.
3. Run: `python3 ~/.agents/skills/trd-writer-new/scripts/manifest.py {project_root} '<module_map_json>'`

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
2. Directory with > 100 files → split into multiple Workers (e.g., by alphabetical range or subdirectory).
3. Directory with > 50 files → consider splitting if Workers have capacity.
4. Directory with < 5 files → merge with a related directory.
5. **Root-level files** (e.g., `controller/*.php`) → dedicate Workers to ensure thorough analysis.
6. Special directories (`proto/`, `migrations/`, `config/`, `test/`) → group by relevance.
7. Static assets, generated code, and `vendor/` → exclude from analysis.
8. Group modules by coupling (modules that import each other belong to the same Worker).
9. Balance file count across Workers (aim for roughly equal load, ideally <150 files per Worker).

## Verification Checklist

Before delivering, verify:

- [ ] All major modules are documented in the TRD.
- [ ] **All root-level files** are documented (not summarized as "Selected").
- [ ] Architecture diagram matches actual code structure.
- [ ] File path references point to real files.
- [ ] Data model matches actual schema/struct definitions.
- [ ] API definitions match actual route/handler registrations.
- [ ] Core algorithms/formulas are documented with all variants.
- [ ] No fabricated features.
- [ ] No `[INFERRED]` tags remain — all resolved or marked `[UNRESOLVED]` inline.
- [ ] Mermaid diagrams are syntactically correct.
- [ ] Document language matches user's language.
- [ ] Cross-module flows have sequence diagrams.
- [ ] **TRD title follows format**: `# {name} — Technical Requirements Document (TRD)`
- [ ] **No metadata sections** (generation time, file paths, etc.)

## Examples

Examples document special project structures. **During Phase 1 (Coordinator)**, check if the project matches any example pattern. If it does, **read the example file and follow its strategy** for module scoping, Worker assignment, and analysis approach.

| Example | Detection Signal | Description |
|---------|------------------|-------------|
| [`examples/kratos-subapis.md`](examples/kratos-subapis.md) | `apis/` submodule + `internal/service/` + Kratos imports | Identify project-specific protos from service layer imports, skip unrelated public protos |

## When NOT to Use This Skill

- Designing a new system — use a forward-design approach instead.
- User wants a PRD, not a technical doc.
- User wants a code review, not documentation.
