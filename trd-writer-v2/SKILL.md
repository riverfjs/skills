---
name: trd-writer-v2
description: Analyze a codebase module and generate a Technical Requirements Document (TRD) with zero information loss. Uses multi-agent Workers writing TRD sections directly, then shell concatenation instead of Merger agent. Use when generating TRD from code, documenting technical design, or reverse-engineering a tech spec.
---

# TRD Writer V2

Analyze a codebase module using Coordinator + Section Workers + Reviewers, then concatenate sections via shell. No Merger agent — zero information loss.

## Goal

Produce a TRD that accurately describes a codebase module's architecture, data models, interfaces, workflows, and core algorithms. The document preserves 100% of Worker analysis with no summarization.

## Hard Constraints

- Always derive content from actual code. Never fabricate features.
- Always write the TRD in the user's conversation language.
- Always translate code into documentation. Never evaluate the code. Never write `[Bug]`, "suspected bug", "should fix", "error swallowed", "dead code". Always state the trigger condition and actual return/side-effect as a neutral fact.
- Always reserve `[INFERRED]` for facts the current file cannot prove (caller identity, config source, runtime value). Reviewer must cross-path verify and resolve. Never use `[INFERRED]` to flag suspicious code.
- Always use signatures and short snippets. Never paste large code blocks. Exception: core business formulas.
- Always write sub-agent output to `{output_dir}/`. Never rely on Task return for long content.
- Never launch more than 10 parallel Workers per batch.
- Always pass `model: "sonnet"` when launching Coordinator, Worker, and Reviewer Agent calls.
- Never use a Merger agent. Always concatenate sections via shell.
- Always analyze every source file. 100% coverage, no exceptions.
- Always use repo-relative paths. Never emit absolute host paths.
- Never label module nature ("pure-proto", "business-only"). Describe only what exists in-repo.
- Never invent external repo names. If impl not found, say "not located in this repo [INFERRED]".
- Always scope a module to files under its own path plus files that actually import/register it or hold its data (e.g. GORM model files whose tables match the domain). Never pull in files matching only the module name as a substring.
- Always halt at coordinator scope phase only when the WHOLE module has zero in-repo implementation (no importer of its package, no service registration, no schema match). This is a structural signal the project has changed — ask the user before writing any section. Never halt for code-detail uncertainty; let Workers mark `[INFERRED]` and Reviewers cross-path verify.
- Always keep Section 1.1 to one sentence. Always render Section 1.3 as a repo-rooted file tree with line counts. Always follow the Section 8 subsection structure in `trd_template.md`; omit subsections that do not apply.

## File Structure

```
trd-writer-v2/
├── SKILL.md                    # This file
├── trd_template.md             # TRD output format template
├── section_naming.md           # Section file naming convention (MUST READ)
├── prompts/                    # Subagent prompt templates
│   ├── coordinator.md
│   ├── worker_overview_architecture.md
│   ├── worker_data_model.md
│   ├── worker_interface.md
│   ├── worker_core_logic.md
│   ├── worker_config_observability.md
│   └── reviewer.md
└── scripts/
    ├── concat_trd.sh           # Concatenate sections into TRD.md
    └── manifest.py             # Generate manifest.json for incremental updates
```

## Section File Naming (CRITICAL)

**All Workers MUST output files with these exact names.** See `section_naming.md` for details.

| Section | File Name Pattern |
|---------|-------------------|
| 1 | `section_1_overview.md` |
| 2 | `section_2_architecture.md` |
| 3 | `section_3_data_model.md` |
| 4 | `section_4_interface.md` |
| 5 | `section_5_{N}_core_logic.md` (N=1,2,3...) |
| 6 | `section_6_{N}_data_access.md` (N=1,2,3...) |
| 7 | `section_7_1_observability.md` |
| 8 | `section_8_file_index.md` |

## Workflow

**Phases MUST be executed in strict order. Do NOT skip or reorder phases.**

| Phase | Name | Gate Condition |
|-------|------|----------------|
| 1 | Coordinator | project_profile.md + worker TODOs written |
| 2 | Workers | All section_*.md files written |
| 3 | Reviewers | All review_patches written |
| 3.5 | Fix Issues | If Pass: No, fix missing content, re-review until ALL Pass: Yes |
| 4 | Concat | TRD.md generated |
| 5 | Deliver | Report to user, update TRD_PLAN.md |

**Manifest**: Only generate once per project (first module), not per module. Uses `git ls-files` for entire project.

### Phase 1: Coordinator (1 sub-agent)

Launch one `generalPurpose` Task agent. Read `prompts/coordinator.md` for full prompt.

**Coordinator must**:
1. Scan module and find related files across project
2. Assign files to Section Workers based on TRD structure
3. Write `{output_dir}/project_profile.md`
4. Write `{output_dir}/worker_{N}_todo.md` for each Worker
5. Return: "Project Profile + {N} Worker TODOs written"

### Phase 2: Section Workers (up to 10 parallel)

Launch parallel `generalPurpose` Task agents. Read prompts from `prompts/worker_*.md`.

| Worker | Prompt File | Output Files |
|--------|-------------|--------------|
| Worker 1 | (synthesize) | section_1_overview.md, section_2_architecture.md |
| Worker 2 | worker_data_model.md | section_3_data_model.md |
| Worker 3 | worker_interface.md | section_4_interface.md |
| Worker 4+ | worker_core_logic.md | section_5_core_logic_partN.md |
| Worker N | worker_config_observability.md | section_6/7/8.md |

**Section content rules**:
- Document ALL functions/methods — no "etc." or "similar to above"
- Include ALL fields in ALL models
- Include ALL API endpoints
- Include ALL algorithms with formulas

### Phase 3: Reviewers (MANDATORY — up to 10 parallel)

**This phase is MANDATORY. Do NOT skip to Phase 4 without completing all Reviews.**

Launch parallel `generalPurpose` Task agents. Read `prompts/reviewer.md` for full prompt.

Each Reviewer must:
1. **TODO Audit**: Verify all checkboxes `[x]`
2. **Coverage Verification**: Read source files, count methods, verify documented
3. **[INFERRED] Resolution**: Cross-path search, confirm/correct/unresolved
4. Write `{output_dir}/review_patches_worker_{N}.md`
5. Return: "Review complete — TODO: X/Y, Coverage: X/Y, [INFERRED]: X resolved, Pass: Yes/No"

**Gate condition**: ALL Reviewers must return "Pass: Yes" before proceeding to Phase 4.

### Phase 3.5: Fix Issues (if any Reviewer returns Pass: No)

**If ANY Reviewer reports missing content, you MUST fix before Phase 4.**

1. **Read review_patches_worker_{N}.md** to identify missing items
2. **For each missing item**:
   - If function/method missing: Add to corresponding section file
   - If field missing: Add to section_3_data_model.md
   - If endpoint missing: Add to section_4_interface.md
3. **Re-run affected Reviewer** to verify fix
4. **Only proceed to Phase 4 when ALL Pass: Yes**

**Do NOT skip missing content.** Do NOT justify skipping with "covered elsewhere" — each section must be complete per its scope.

### Phase 4: Concat (ONLY after Phase 3 ALL Pass)

Run concat script to generate TRD.md:

```bash
bash ~/.agents/skills/trd-writer-v2/scripts/concat_trd.sh {output_dir} {module_path}
```

**Result**: `TRD.md` with 100% content from all Workers. Script outputs line count summary.

### Phase 5: Deliver

Report to user based on concat script output:
- Section file count and line totals
- TRD.md location and line count
- Difference (title + separators)
- Update TRD_PLAN.md status

---

## Manifest (Once Per Project)

Generate manifest.json **only once** when starting a new project (first module analysis).

```bash
python3 ~/.agents/skills/trd-writer-v2/scripts/manifest.py {project_root}
```

This records:
- `last_commit`: Current git HEAD commit hash
- `last_run`: Timestamp  
- `files`: All git-tracked files in the project

Output: `{project_root}/trd_work/manifest.json`

**Do NOT regenerate manifest for each module.** It tracks the entire project state for future incremental updates by `trd-updater`.

## When NOT to Use This Skill

- Designing a new system (use forward-design approach)
- User wants PRD, not technical doc
- User wants code review, not documentation
