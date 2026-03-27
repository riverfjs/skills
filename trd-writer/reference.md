# TRD Writer — Reference

Detailed templates and prompt examples for each sub-agent phase. Read this file when constructing sub-agent prompts.

## TRD Output Template

The Merger agent must produce a TRD following this structure. Include/exclude sections per the rules table below.

```markdown
# {Project Name} — Technical Requirements Document (TRD)

## 1. Overview

### 1.1 Background
What the system does, derived from README, comments, and code behavior.

### 1.2 Scope
What is covered in this TRD. What is explicitly excluded.

### 1.3 Tech Stack
| Layer | Technology | Version |
|-------|-----------|---------|

### 1.4 Project Structure
Directory tree with module descriptions.

### 1.5 Glossary
| Term | Definition |
|------|-----------|

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

### 4.1 External APIs
For each endpoint/RPC: method, path, description, request/response types, error handling.

### 4.2 Internal Interfaces
Key exported functions, service interfaces, module boundary contracts.

### 4.3 External Integrations
Protocol, authentication, data format for each integration.

## 5. Core Workflow

### 5.1 Primary Flows
End-to-end request flows with Mermaid sequence diagrams.

### 5.2 Background Processes
Workers, cron jobs, event consumers, scheduled tasks.

### 5.3 State Transitions
Lifecycle state machines found in code.

## 6. Non-Functional Characteristics

### 6.1 Error Handling
Retry, circuit breaker, fallback, degradation patterns.

### 6.2 Security
Auth mechanisms, encryption, input validation, role isolation.

### 6.3 Observability
Logging, tracing, metrics, alerting, health checks.

### 6.4 Configuration Management
Config files, env vars, hot reload, feature flags.

## 7. Build & Deployment

### 7.1 Build Process
Commands, compilation, conditional compilation (build tags etc.).

### 7.2 Database Migration
Schema evolution history, migration tools.

### 7.3 Deployment
Containerization, CI/CD, deployment configs.

## 8. References
File paths, related docs, external resources.
```

### Section Inclusion Rules

| Section | Include When |
|---------|-------------|
| Architecture | Always |
| Data Model | Code defines persistent entities or structured data |
| Interface Design | Code exposes APIs, RPCs, or has clear module boundaries |
| Core Workflow | Multi-step request/business flows exist |
| Non-Functional Characteristics | Always |
| Build & Deployment | Build scripts, Dockerfile, CI config, or migration files exist |

## Coordinator Prompt Template

Use this as a base when constructing the Coordinator sub-agent prompt. Replace `{project_root}` with the actual path.

```
You are a TRD Coordinator Agent. Your task is to scan a project and produce a Project Profile.

## Target Project
Path: {project_root}

## Steps

1. Run `find {project_root} -type f -name "*.go" -o -name "*.py" -o -name "*.ts" -o -name "*.js" -o -name "*.java" -o -name "*.rs" | grep -v vendor | grep -v node_modules | head -300` to get a file overview.
2. Read dependency files (go.mod, package.json, requirements.txt, Cargo.toml, etc.).
3. Read README if it exists.
4. Read entry point files (main.go, app.py, index.ts, etc.).
5. Map directory structure and identify module boundaries.
6. Divide modules into up to 4 Worker groups, balanced by file count and coupling.
7. Write the Project Profile to {project_root}/trd_work/project_profile.md using the Write tool.
8. Return: "Project Profile written to {project_root}/trd_work/project_profile.md"

## Project Profile Format
[Insert Project Profile schema from SKILL.md]

## Rules
- Shallow scan only. Do not analyze business logic in depth.
- Prioritize: dependency files → entry points → directory structure → model definitions.
- Exclude: vendor/, node_modules/, generated code, static assets, test files from module assignment.
- Group tightly coupled modules (heavy cross-imports) into the same Worker.
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
2. For each module, analyze: responsibility, data models, interfaces, core flows, error handling, dependencies.
3. Write your complete report to {project_root}/trd_work/worker_{N}.md using the Write tool.
4. Return: "Worker {N} report written to {project_root}/trd_work/worker_{N}.md"

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
- Read every .go/.py/.ts file in your modules (not just headers).
- Use actual type definitions and function signatures from the code.
- [INFERRED] means "cannot determine system behavior/intent from code". Use ONLY for genuinely unclear system behavior (e.g., unknown external integration purpose, ambiguous cross-system data source).
- Do NOT mark as [INFERRED]: bugs, performance issues, code style, naming typos, standard framework usage, TODO/unimplemented features, security observations, design suggestions.
- For TODO/unimplemented features, document them factually in the relevant section (e.g., "currently unimplemented") without [INFERRED] tag.
- Your job is to DESCRIBE what the system does, NOT to review code quality.
```

## Reviewer Prompt Template

Each Reviewer handles a **single** Worker report. Launch up to 4 in parallel. Replace `{N}` with the Worker number.

```
You are a TRD Reviewer Agent. Your task is to resolve [INFERRED] items from a single Worker report.

## Input
- Worker report: {project_root}/trd_work/worker_{N}.md
- Source code root: {project_root}

## Steps

1. Read {project_root}/trd_work/worker_{N}.md.
2. Extract every [INFERRED] item.
3. For EACH [INFERRED] item:
   - Identify the relevant source file(s) from the Worker report's "Key Files" table.
   - Read those source files to gather evidence.
   - Determine: Confirmed (inference correct) / Corrected (inference wrong) / Unresolved (cannot determine).
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
- Read whatever source files are needed to resolve each item. No file read limit. Trace imports, check callers, read configs — do whatever it takes.
- If an item genuinely cannot be resolved after thorough investigation, mark as [UNRESOLVED] with detailed explanation of what was checked and why it remains unclear.
- Do NOT modify worker_{N}.md directly. Only write review_patches_worker_{N}.md.
```

## Merger Prompt Template

```
You are a TRD Merger Agent. Combine all analysis reports into a final TRD document.

## Input Files
Read these files:
- {project_root}/trd_work/project_profile.md
- {project_root}/trd_work/worker_1.md
- {project_root}/trd_work/worker_2.md
- {project_root}/trd_work/worker_3.md
- {project_root}/trd_work/worker_4.md
- {project_root}/trd_work/review_patches_worker_*.md (all that exist, apply corrections)

## Steps

1. Read all input files.
2. If review_patches_worker_*.md files exist, apply all patches to the corresponding Worker report content before merging.
3. Merge into a unified TRD following the TRD Output Template structure.
4. Apply merge rules:
   - Unify terminology per the glossary in Project Profile.
   - Deduplicate overlapping content.
   - Add Mermaid architecture diagram (component dependencies).
   - Add Mermaid ER diagram (data model relationships).
   - Add Mermaid sequence diagrams for cross-module flows.
   - Apply patches: replace [INFERRED] with confirmed/corrected descriptions.
   - Any remaining [UNRESOLVED] items are noted inline in the relevant module section. No dedicated "Known Issues" or "Open Questions" chapter. No [INFERRED] should remain.
   - Reference real file paths throughout.
5. Write the final TRD to {project_root}/trd_work/TRD.md using the Write tool.
6. Return: "TRD written to {project_root}/trd_work/TRD.md"

## TRD Structure
[Insert TRD Output Template]

## Merge Rules
- Do NOT read source code. Work only from the provided reports.
- When Workers describe the same entity differently, prefer the more detailed description.
- For cross-module flows (e.g., HTTP request → middleware → service → model → DB), construct end-to-end sequence diagrams.
- Use {user_language} for the document.
```
