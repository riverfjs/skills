---
name: trd-updater
description: Incrementally update an existing TRD when the codebase changes, using git diff to detect affected modules and only re-analyzing those. Use when the user asks to update a TRD, refresh documentation after code changes, sync TRD with latest code, or bring a TRD up to date. Requires a prior trd-writer run (manifest.json must exist).
---

# TRD Updater

Detect code changes via git diff, re-analyze only affected modules, and surgically update the existing TRD. Produces versioned output with changelog.

## Goal

Keep an existing TRD accurate after code changes, without full regeneration. Minimize token usage by only analyzing modules whose source files changed.

## Hard Constraints

- Requires `{project_root}/trd_work/manifest.json` from a prior `trd-writer` run. If missing → tell user to run `trd-writer` first and stop.
- Requires a git repository. If not a git repo → stop with error.
- All content must be derived from actual code. Never fabricate features.
- TRD must be written in the same language the user uses in conversation.
- `[INFERRED]` rules are identical to `trd-writer`: only for genuinely unclear system behavior/intent. Not for bugs, code review, performance, or standard patterns.
- All sub-agent output goes to `{project_root}/trd_work/_update/`. Never rely on Task return value for long content.
- Max 4 parallel agents per batch.
- The updater does NOT read old `worker_*.md` files. It works from the existing `TRD.md` + fresh delta analysis.

## File Layout

```
trd_work/
├── manifest.json              # Read by updater, updated in Phase 5
├── project_profile.md         # Read by updater, may be regenerated
├── worker_*.md                # From trd-writer (NOT read by updater)
├── TRD.md                     # Current TRD (read as base, replaced)
├── versions/                  # Managed by updater
│   └── TRD_v{N}.md
├── changelog.md               # Managed by updater
└── _update/                   # Updater's ephemeral workspace
    ├── project_profile.md     # Only if directory structure changed
    ├── delta_worker_*.md      # Fresh analysis of affected modules
    └── review_patches_*.md    # Review of delta workers
```

## Workflow

### Phase 0: Change Detection (main agent, no sub-agent)

1. Read `{project_root}/trd_work/manifest.json`. If missing → stop: "No manifest found. Run trd-writer first."
2. Run `git -C {project_root} rev-parse HEAD` → current commit.
3. If current commit == `last_commit` in manifest → stop: "TRD is up to date. No changes since last run."
4. Run `git -C {project_root} diff --name-only {last_commit}..HEAD` → changed files list.
5. Filter: ignore files in `vendor/`, `node_modules/`, `_test` files, generated code, static assets.
6. Map each changed file to a module using `module_file_map` from manifest.
7. Check for new/deleted top-level directories: `git -C {project_root} diff --diff-filter=A --name-only {last_commit}..HEAD` and `--diff-filter=D`.

**Decision**:

| Condition | Action |
|-----------|--------|
| 0 relevant changed files | Stop: "TRD is up to date." |
| ≥50% modules affected OR new/deleted top-level directories | Recommend: "Major structural changes detected. Consider running trd-writer for full regeneration." Proceed with full update if user confirms, or stop. |
| <50% modules affected, no structural changes | Proceed with incremental update. |

8. Write affected module list and changed file mapping to `{project_root}/trd_work/_update/change_report.md`.

### Phase 1: Selective Coordinator (conditional, 1 sub-agent)

**If** new or deleted top-level directories were detected in Phase 0:

Launch **one** `generalPurpose` Task agent to rescan the project. Same instructions as trd-writer Coordinator, but output goes to `{project_root}/trd_work/_update/project_profile.md`.

**Otherwise**: Use the existing `{project_root}/trd_work/project_profile.md` as-is.

**Stop condition**: Coordinator finishes when `_update/project_profile.md` is written (or skipped).

### Phase 2: Delta Workers (up to 4 parallel sub-agents)

Launch **up to 4** parallel `generalPurpose` Task agents. Each Delta Worker gets:

1. The full content of `project_profile.md` (updated or existing) as shared context.
2. Only the **affected module paths** (from Phase 0 change mapping).
3. The change report (which files changed in this module).
4. An output file path: `{project_root}/trd_work/_update/delta_worker_{N}.md`.

**Agent instructions** — each Delta Worker must:

1. Read all source files in the affected modules (same skip rules as trd-writer: no `_test`, no generated code, no `vendor/`).
2. Analyze each module following the **same Worker Output Schema** as trd-writer (see `reference.md`).
3. **Write** the full report to `{project_root}/trd_work/_update/delta_worker_{N}.md`.
4. Return a one-line confirmation.

**[INFERRED] rules**: Identical to trd-writer. Only for genuinely unclear system behavior. No code review.

**Stop condition**: Delta Worker finishes when its file is written.

### Phase 3: Review (up to 4 parallel sub-agents)

Same process as trd-writer Phase 3, but operates on `_update/delta_worker_*.md`:

**Step 1 — Extract**: Grep all `[INFERRED]` items in `_update/delta_worker_*.md`. If zero → skip to Phase 4.

**Step 2 — Dispatch**: Launch parallel Reviewer agents, one per delta_worker that has `[INFERRED]` items.

**Agent instructions** — each Reviewer must:

1. Read `{project_root}/trd_work/_update/delta_worker_{N}.md`.
2. For each `[INFERRED]` item, read source files to verify. No file read limit.
3. **Write** results to `{project_root}/trd_work/_update/review_patches_worker_{N}.md`.
4. Return a one-line confirmation with counts.

**Stop condition**: Written. Max 2 rounds.

### Phase 4: Delta Merger (1 sub-agent)

Launch **one** `generalPurpose` Task agent.

**Agent instructions** — the Delta Merger must:

1. Read `{project_root}/trd_work/TRD.md` (the full existing TRD as base document).
2. Read `{project_root}/trd_work/_update/change_report.md` (which modules changed).
3. Read all `{project_root}/trd_work/_update/delta_worker_*.md` (fresh analysis of changed modules).
4. Read all `{project_root}/trd_work/_update/review_patches_worker_*.md` if they exist (apply corrections).
5. Read `project_profile.md` (existing or updated from `_update/`).
6. Perform a **surgical update** of the existing TRD:
   - Replace sections corresponding to affected modules with content from delta workers.
   - Preserve all sections for unchanged modules verbatim.
   - Update architecture diagram if module dependencies changed.
   - Update ER diagram if data models in affected modules changed.
   - Update sequence diagrams if affected modules participate in cross-module flows.
   - Apply review patches: replace `[INFERRED]` with confirmed/corrected descriptions. Note `[UNRESOLVED]` inline.
   - Unify terminology. No `[INFERRED]` in final output.
7. **Write** the updated TRD to `{project_root}/trd_work/_update/TRD_new.md`.
8. Return a one-line confirmation.

**Stop condition**: Delta Merger finishes when `_update/TRD_new.md` is written.

### Phase 5: Versioned Delivery (main agent, no sub-agent)

1. **Archive**: Copy current `TRD.md` → `versions/TRD_v{version}.md` (version from manifest).
2. **Replace**: Move `_update/TRD_new.md` → `TRD.md`.
3. **Changelog**: Append to `{project_root}/trd_work/changelog.md` (see `reference.md` for template).
4. **Update manifest**:
   1. Build the module→path JSON from `project_profile.md` (use `_update/project_profile.md` if Phase 1 re-ran, otherwise the existing one). Same format as trd-writer: `{"module_name":"path/", ...}`.
   2. Run: `python3 ~/.agents/skills/trd-updater/scripts/manifest.py {project_root} '<module_map_json>'`
   The script reads the existing manifest, increments version, updates commit/timestamp, and re-scans file lists for each module path.
5. **Present summary** to the user (no questions):
   - Version: v{old} → v{new}
   - Modules updated: list
   - Modules unchanged: count
   - Number of `[UNRESOLVED]` items (if any)
   - Key changes summary
   - File path to the full TRD

## When NOT to Use This Skill

- No prior `trd-writer` run (no `manifest.json`).
- Not a git repository.
- User wants a fresh TRD from scratch — use `trd-writer` instead.
- User wants a code review, not documentation update.
- Major rewrite (≥50% modules changed) — recommend `trd-writer` full regeneration.
