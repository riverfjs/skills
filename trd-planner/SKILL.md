---
name: trd-planner
description: Scan a complex project and generate a TRD execution plan with module breakdown. Use before trd-writer-v2 when project has multiple modules or >50 files. Produces TRD_PLAN.md with module list, exclusions, and execution tracking.
---

# TRD Planner

Scan a complex project and generate a modular TRD execution plan. Run this first, then use `trd-writer-v2` for each module.

## Goal

Produce a `TRD_PLAN.md` that:
1. Lists all modules to analyze
2. Defines exclusion rules
3. Tracks execution status per module
4. Enables sequential or parallel TRD generation

## Hard Constraints

- Always produce exactly one `TRD_PLAN.md` per project. Never split or duplicate.
- Always write output to `{project_root}/TRD_PLAN.md`.
- Always defer per-module TRD generation to `trd-writer-v2`. Never embed module content in the plan.
- Always omit TRD format rules from the plan. Never duplicate `trd-writer-v2` instructions here.

## When to Use

Use this skill when:
- Project has multiple sub-modules or user ask to split repository in modules
- Project has >50 source files total
- You want to track progress across multiple TRD generation sessions

Do NOT use when:
- Single small module (<50 files) — suggest user using trd-writer-v2 directly
- User already has a TRD_PLAN.md

## Workflow

### Step 1: Scan Project Structure

```bash
# Find all potential modules
find {project_root} -type d -maxdepth 3 | head -100

# Count files per directory
find {project_root} -name "*.go" -o -name "*.proto" | wc -l

# Check for common patterns
ls -la {project_root}/apis/
ls -la {project_root}/internal/
```

### Step 2: Identify Module Boundaries

Common patterns:
- `apis/{service}/*` — API definition modules
- `internal/service/*` — Service implementations
- `cmd/*` — Entry points
- `pkg/*` — Shared packages

### Step 3: Define Exclusions

Standard exclusions for Go projects:
- `vendor/` — third-party dependencies
- `*_test.go` — test files
- `*.pb.go` — protobuf generated
- `*.swagger.json` — swagger generated
- `node_modules/` — JS dependencies
- `dist/`, `build/` — build outputs

### Step 4: Write TRD_PLAN.md

```bash
# Run the plan generator script
bash ~/.agents/skills/trd-planner/scripts/generate_plan.sh {project_root} {tech_stack}
```

Or write manually following the template in `plan_template.md`.

### Step 5: Return Plan Summary

Report to user:
- Total modules: N
- Total files to analyze: ~N
- Estimated TRDs to generate: N
- Plan location: {project_root}/TRD_PLAN.md

## Output

See `plan_template.md` for the full TRD_PLAN.md structure.

## After Planning

For each module in TRD_PLAN.md:
1. Use `trd-writer-v2` to generate TRD
2. Update status in TRD_PLAN.md (⏳ → ✅)
3. Record completion time and notes

## When NOT to Use

- Small projects (<50 files) — use trd-writer-v2 directly
- User already has TRD_PLAN.md — just execute it
- Single module analysis — use trd-writer-v2 directly
