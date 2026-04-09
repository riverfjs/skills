# TRD Writer — Reference

Detailed templates and prompt examples for each sub-agent phase. Read this file when constructing sub-agent prompts.

## TRD Output Template

The Merger agent must produce a TRD following this structure. Include/exclude sections per the rules table below.

```markdown
# {Project Name} — Technical Requirements Document (TRD)

## 1. Project Overview

### 1.1 Project Summary
A concise description (2-3 paragraphs) of what this project does, its primary responsibilities, and how it fits into the larger system. Derived from README, comments, entry points, and code behavior.

**For sub-module analysis**: Must clearly state this is a sub-module, explain its role in the parent project, and describe relationships with other modules.

### 1.2 Tech Stack
| Layer | Technology | Version |
|-------|-----------|---------|

### 1.3 Project Structure
Directory tree with module descriptions.

### 1.4 Glossary
| Term | Definition |
|------|-----------|
Domain-specific terminology required to understand the system.

## 2. Architecture

### 2.1 System Architecture
Mermaid architecture diagram showing major components and connections.

### 2.2 Module Breakdown
For each module: responsibility, key files, dependencies.

### 2.3 External Dependencies
Third-party services, libraries, upstream/downstream systems.

## 3. Data Model

### 3.1 Entity Definitions
All persistent tables/collections/structs with field-level detail. Include source file references.

### 3.2 Entity Relationships
Mermaid ER diagram.

### 3.3 Data Flow
How data enters, transforms, and exits the system.

## 4. Interface Design

### 4.1 External Interfaces
For each endpoint/RPC/message channel: method, path/topic, description, request/response types.

### 4.2 Internal Interfaces
Key exported functions, service interfaces, module boundary contracts.

### 4.3 External Integrations
Protocol, authentication, data format for each integration.

## 5. Core Logic

### 5.1 Primary Flows
End-to-end request flows with Mermaid sequence diagrams.

### 5.2 Core Algorithms
Document key business formulas, calculation logic, and decision algorithms. For each:
- **Name & Location**: Function/method name and file path
- **Purpose**: What it calculates or decides
- **Formula/Logic**: Mathematical formula (use LaTeX: `$formula$`) or pseudocode
- **Variables**: Explanation of each input parameter
- **Variants**: Different cases (e.g., by direction, mode, asset type) — document ALL variants with their respective formulas

This section is critical for finance, trading, risk management, ML/AI, pricing, scheduling, and similar domains.

### 5.3 Background Processes
Workers, cron jobs, event consumers, scheduled tasks.

### 5.4 State Transitions
Lifecycle state machines found in code.

## 6. Runtime Configuration

### 6.1 Configuration Items
All configuration keys with descriptions, types, default values, and valid ranges.

### 6.2 Deployment
Containerization, process model, resource requirements, startup sequence.

## 7. Observability

### 7.1 Logging
Log levels, formats, key log points, log rotation.

### 7.2 Monitoring & Alerting
Metrics exposed, alert conditions, notification channels.

### 7.3 Error Handling
Error types, retry patterns, fallback strategies, degradation behavior.

## 8. File Index
| Category | File Path | Description |
|----------|-----------|-------------|
Reference table mapping key files to their roles.
```

### Title Format Rules

| Scenario | Title Format |
|----------|--------------|
| Complete project analysis | `# {Project Name} — Technical Requirements Document (TRD)` |
| Sub-module analysis (project split by directory) | `# {module_path} — Technical Requirements Document (TRD)` |

### Section Inclusion Rules

| Section | Include When |
|---------|-------------|
| Project Overview | Always |
| Architecture | Always |
| Data Model | Code defines persistent entities or structured data |
| Interface Design | Code exposes APIs, RPCs, or has clear module boundaries |
| Core Logic | Multi-step request/business flows exist |
| Core Algorithms | Domain-specific calculations exist (finance, trading, pricing, ML, scheduling, etc.) |
| Runtime Configuration | Config files, env vars, or deployment configs exist |
| Observability | Logging, metrics, or alerting code exists |
| File Index | Always |

### Forbidden Elements

Do NOT include in TRD:
- Document generation time/date
- File path metadata sections
- "Document Info" or similar meta-sections
- Any content not derived from actual code

## Coordinator Prompt Template

Use this as a base when constructing the Coordinator sub-agent prompt. Replace `{project_root}` with the actual path.

```
You are a TRD Coordinator Agent. Your task is to scan a project and produce a Project Profile.

## Target Project
Path: {project_root}

## Steps

1. Scan directory structure to get file overview.
2. **Check for special project patterns**: Refer to the Examples table in SKILL.md. If the project matches a detection signal, read the corresponding example file and follow its scoping strategy.
3. Read dependency files (go.mod, package.json, requirements.txt, Cargo.toml, composer.json, etc.).
4. Read README if it exists.
5. Read entry point files (main.go, app.py, index.ts, index.php, etc.).
6. Map directory structure and identify module boundaries.
7. Divide modules into Worker groups:
   - Max 10 Workers per batch (if more needed, plan batches)
   - Large directories (>100 files) should be split across multiple Workers
   - Root-level files deserve dedicated Workers for thorough analysis
   - Balance file count (aim for <150 files per Worker)
8. Write the Project Profile to {project_root}/trd_work/project_profile.md using the Write tool.
9. Return: "Project Profile written to {project_root}/trd_work/project_profile.md"

## Project Profile Format

# Project Profile: {name}
## Project Summary (2-3 sentences describing what this project does)
## Tech Stack (table: layer / technology / version)
## Project Structure (directory tree with descriptions)
## Module Assignment
### Worker 1: {group name}
| Module | Path | File Count |
### Worker 2: ...
(up to Worker 10; if more needed, indicate batching plan)
## Core Entities (type names + source files)
## Glossary (term / definition table)
## Entry Point Analysis (startup flow summary)

## Rules
- Shallow scan only. Do not analyze business logic in depth.
- Prioritize: dependency files → entry points → directory structure → model definitions.
- Exclude: vendor/, node_modules/, generated code, static assets, test files from module assignment.
- Group tightly coupled modules (heavy cross-imports) into the same Worker.
- Split large directories to ensure thorough analysis.
```

## Worker Prompt Template

Use this as a base for each Worker sub-agent. Replace placeholders.

```
You are a TRD Worker Agent. Analyze assigned modules and write a structured report.

## Project
Path: {project_root}

## Shared Context (Project Profile)
{paste full content of project_profile.md here}

## Your Assignment
You are Worker {N}. Analyze these modules:
{list of module names and paths}

## Steps

1. Read ALL source files in your assigned modules (skip _test files, generated code).
2. **Cross-path search**: Look for related files in other directories (models, configs, utilities may be elsewhere).
3. For each module, analyze: responsibility, data models, interfaces, core flows, core algorithms/formulas, error handling, dependencies.
4. Write your complete report to {project_root}/trd_work/worker_{N}.md using the Write tool.
5. Return: "Worker {N} report written to {project_root}/trd_work/worker_{N}.md"

## Output Format
For EACH module, use this exact structure:

# Module: {name}
## Responsibility
## Key Files (table — list ALL files, not "selected")
## Data Model
## Interface (list ALL endpoints/functions, not just "key" ones)
## Core Flow
## Core Algorithms
For each key calculation/formula/decision logic:
- Name & Location (function name, file path)
- Purpose (what it calculates)
- Formula (mathematical formula or pseudocode, use LaTeX for math)
- Variables (explain each parameter)
- Variants (different cases — document ALL)
Skip only if module has no core business logic.
## Error Handling
## Dependencies (Internal / External)
## Uncertain ([INFERRED] items)

## Rules
- Analyze your assigned modules thoroughly. Do NOT summarize with "etc." or "(Selected)".
- **Cross-path search**: Database models, configs, utilities may be in other directories — find them.
- Read every source file in your modules (not just headers).
- Use actual type definitions and function signatures from the code.
- [INFERRED] means "cannot determine system behavior/intent from code". Use ONLY for genuinely unclear system behavior.
- Do NOT mark as [INFERRED]: bugs, performance issues, code style, naming typos, standard framework usage, TODO/unimplemented features, security observations, design suggestions.
- For TODO/unimplemented features, document them factually (e.g., "currently unimplemented") without [INFERRED] tag.
- Your job is to DESCRIBE what the system does, NOT to review code quality.
```

## Reviewer Prompt Template

Each Reviewer handles a **single** Worker report. Launch up to 10 in parallel. Replace `{N}` with the Worker number.

```
You are a TRD Reviewer Agent. Your task is to resolve [INFERRED] items from a single Worker report.

## Input
- Worker report: {project_root}/trd_work/worker_{N}.md
- Source code root: {project_root}

## Steps

1. Read {project_root}/trd_work/worker_{N}.md.
2. Extract every [INFERRED] item.
3. For EACH [INFERRED] item:
   - **Cross-path search**: Look in the ENTIRE project, not just the Worker's assigned path.
   - Check database definitions, config files, related modules, shared libraries.
   - Read whatever source files are needed to gather evidence.
   - Determine: Confirmed (inference correct) / Corrected (inference wrong) / Unresolved (cannot determine after exhaustive search).
4. Write all results to {project_root}/trd_work/review_patches_worker_{N}.md using the Write tool, in this format:

# Review Patches — Worker {N}

## Patch 1
- Source: worker_{N}.md, Module: {name}, Section: {section}
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

5. Return: "Review patches written to {project_root}/trd_work/review_patches_worker_{N}.md — Total: X, Confirmed: Y, Corrected: Z, Unresolved: W"

## Rules
- **Cross-path search is mandatory**. Search the entire project to resolve items.
- Read whatever source files are needed. No file read limit. Trace imports, check callers, read configs.
- Only mark as [UNRESOLVED] after exhaustive cross-path search. Explain what was searched.
- Do NOT modify worker_{N}.md directly. Only write review_patches_worker_{N}.md.
```

## Merger Strategy

Choose merge strategy based on total Worker report size:
- **< 5000 lines**: Simple Merge (1 agent)
- **>= 5000 lines**: Layered Merge (Section Mergers + Final Merger)

---

## Simple Merger Prompt Template (< 5000 lines)

```
You are a TRD Merger Agent. Combine all analysis reports into a final TRD document.

## Input Files
Read these files:
- {project_root}/trd_work/project_profile.md
- {project_root}/trd_work/worker_*.md (all worker reports)
- {project_root}/trd_work/review_patches_worker_*.md (all that exist, apply corrections)

## CRITICAL: Content Preservation Rules

**The final TRD must preserve ALL substantive content from Worker reports.**

- Do NOT summarize or truncate detailed lists (endpoints, fields, algorithms)
- Do NOT replace detailed content with "etc." or "..."
- Do NOT reduce content to save space
- The final TRD should be at least 60-80% of the combined Worker reports in length
- ALL core algorithms with formulas must be preserved
- ALL state machines must be preserved
- ALL validation rules should be preserved

**Deduplication means**: Remove exact duplicates only. It does NOT mean summarizing.

## Steps

1. Read all input files completely.
2. Apply review patches if they exist.
3. **Reorganize** (not summarize) content into TRD structure.
4. Apply merge rules (title, no metadata, terminology, diagrams).
5. Write to {project_root}/trd_work/TRD.md.
6. Return: "TRD written to {path}"
```

---

## Layered Merger Prompt Templates (>= 5000 lines)

### Section Merger Prompt Template

Use this for each Section Merger (A through E). Replace placeholders.

```
You are a TRD Section Merger Agent. Merge specific Worker reports into one TRD section.

## Your Assignment: Section Merger {A|B|C|D|E}

| Merger | TRD Sections | Output File |
|--------|--------------|-------------|
| A | 1-2 (Overview + Architecture) | section_A.md |
| B | 3 (Data Model) | section_B.md |
| C | 4 (Interface Design) | section_C.md |
| D | 5 (Core Logic) | section_D.md |
| E | 6-8 (Config + Observability + Index) | section_E.md |

## Input Files
- {project_root}/trd_work/project_profile.md
- {project_root}/trd_work/worker_{list of relevant worker numbers}.md
- {project_root}/trd_work/review_patches_worker_*.md (if exist)

## CRITICAL: Content Preservation

- **PRESERVE ALL DETAIL** from Worker reports
- Do NOT summarize, truncate, or use "etc."
- List ALL endpoints, fields, algorithms, rules
- This section file should contain the FULL content for its TRD sections

## Steps

1. Read assigned Worker reports completely.
2. Apply any review patches.
3. Extract and organize content for your assigned TRD sections.
4. Write to {project_root}/trd_work/section_{A|B|C|D|E}.md
5. Return: "Section {letter} written to {path}"

## Output Format

For Section A (Overview + Architecture):
```markdown
## 1. Project Overview
### 1.1 Project Summary
### 1.2 Tech Stack
### 1.3 Project Structure
### 1.4 Glossary

## 2. Architecture
### 2.1 System Architecture
### 2.2 Module Breakdown
### 2.3 External Dependencies
```

For Section B (Data Model):
```markdown
## 3. Data Model
### 3.1 Entity Definitions
(ALL entities with ALL fields)
### 3.2 Entity Relationships
### 3.3 Data Flow
```

For Section C (Interface Design):
```markdown
## 4. Interface Design
### 4.1 External Interfaces
(ALL endpoints with full details)
### 4.2 Internal Interfaces
### 4.3 External Integrations
```

For Section D (Core Logic):
```markdown
## 5. Core Logic
### 5.1 Primary Flows
### 5.2 Core Algorithms
(ALL algorithms with formulas)
### 5.3 Background Processes
(ALL scheduled tasks)
### 5.4 State Transitions
(ALL state machines)
```

For Section E (Config + Observability + Index):
```markdown
## 6. Runtime Configuration
### 6.1 Configuration Items
### 6.2 Deployment

## 7. Observability
### 7.1 Logging
### 7.2 Monitoring & Alerting
### 7.3 Error Handling

## 8. File Index
(ALL key files)
```
```

### Final Assembly (Shell Command)

After Section Mergers complete, assemble TRD via shell command (no agent needed):

```bash
cd {project_root}/trd_work

# Create TRD with title (skip section_A header line)
echo "# {module_path} — Technical Requirements Document (TRD)" > TRD.md
echo "" >> TRD.md

# Append section A (skip first line which is section header)
tail -n +2 section_A.md >> TRD.md

# Append remaining sections (include all content)
cat section_B.md >> TRD.md
cat section_C.md >> TRD.md
cat section_D.md >> TRD.md
cat section_E.md >> TRD.md
```

Section Mergers already produce properly formatted content with Mermaid diagrams, so no additional processing is needed.

---

## Merge Rules (All Mergers)

- Do NOT read source code. Work only from provided reports.
- When Workers describe the same entity differently, prefer more detailed version.
- **PRESERVE ALL DETAIL** — goal is reorganization, not summarization.
- For sub-module analysis, Section 1.1 must explain module's role in parent project.
- No `[INFERRED]` should remain — apply patches or note `[UNRESOLVED]` inline.
