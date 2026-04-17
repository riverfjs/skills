# Scanner Prompt — Phase 1 of trd-planner

Your job: scan `{project_root}` and produce a draft module list + final exclusion list.
Do **not** write `TRD_PLAN.md` here — that is Phase 2 (`plan_writer.md`).

## Inputs

- `{project_root}` (absolute path, required)
- `{tech_stack_hint}` (optional, e.g. "Go", "Python+FastAPI") — if omitted, infer from manifest files

## Hard Constraints

- Always run scan commands; never invent file counts.
- Always group by **business domain** first; fall back to architectural layer only when no domain split is detectable.
- Always treat `cmd/` + shared infra (`internal/conf`, `pkg/`, `common/util`, root-level `*.go`) as a single optional `root` module.
- Never decide Worker counts, slicing, or execution order — that's `trd-writer-v2`'s job.
- Never produce a module that overlaps another module's path.
- Never include generated, vendored, or build-output files in the file count.

## Workflow

### Step 1: Identify tech stack and entry points

Look at manifests:

```bash
ls {project_root}/{go.mod,package.json,pyproject.toml,Cargo.toml,pom.xml,build.gradle,composer.json} 2>/dev/null
```

Read the relevant one to extract language, framework, version. Also locate entry points:

```bash
find {project_root} -maxdepth 4 -type f \( -name "main.go" -o -name "main.py" -o -name "index.ts" -o -name "app.py" -o -name "Application.java" \)
```

### Step 2: Map directory structure

```bash
find {project_root} -type d -maxdepth 4 \
  -not -path '*/.git*' \
  -not -path '*/vendor*' \
  -not -path '*/node_modules*' \
  -not -path '*/logs*' \
  -not -path '*/dist*' \
  -not -path '*/build*' | sort
```

### Step 3: Decide module boundaries

Apply rules in this order, stop at the first that fits:

1. **Domain-first split** — if subdirs under `apis/`, `pkg/`, `internal/biz/`, `internal/service/`, `src/model/`, `src/service/` cluster around clear business nouns, one module per noun. A module spans **all layers** of the same noun (proto + model + service + biz).
2. **Layered split** — if no domain clustering exists, split by architectural layer (`apis/`, `internal/service/`, `cmd/`, `pkg/`).
3. **Single-module fallback** — if the project is small or homogeneous, declare 1 module.

Always add a `root` module covering: entry point(s), shared utilities (`common/util`, `internal/conf`, `pkg/`), and any repo-wide shared contracts (e.g. `shared/proto/`, `contracts/`). Mark it as the last module.

### Step 4: Count files per module

For each module, run a count that **excludes** generated/test/vendor:

Go example:
```bash
find {module_paths} -type f -name "*.go" \
  ! -name "*_test.go" \
  ! -name "*.pb.go" \
  ! -name "*_grpc.pb.go" | wc -l
```

Add proto/yaml/sql counts as relevant.

Record: `{module_name}` → list of paths → file_count.

### Step 5: Build exclusion list

Start from defaults:

- `vendor/` — third-party deps
- `*_test.go` / `*_test.py` / `*.test.ts` — test files
- `logs/`, `sbin/`, `bin/`, `dist/`, `build/` — runtime/build outputs
- `.git/`, `.idea/`, `.vscode/` — VCS/IDE

Add by tech stack:

| Stack | Add |
|-------|-----|
| Go + protobuf | `*.pb.go`, `*_grpc.pb.go`, `*.swagger.json` |
| Node/TS | `node_modules/`, `*.d.ts` (generated), `coverage/` |
| Python | `__pycache__/`, `*.pyc`, `.venv/`, `venv/` |
| Java | `target/`, `*.class` |

Mention deployment scripts and config files separately in the plan if they are excluded only "from TRD body" but referenced for context (e.g. `conf/config.ini`).

## Output

Return to the conversation a structured draft like this (Markdown). **Use your actual scan results** — the table below is only a shape example, not a real project:

```markdown
### Scan Result

**Tech stack**: Go 1.22 + gRPC + PostgreSQL (example)
**Entry points**: `cmd/api/main.go`, `cmd/worker/main.go`
**Project name**: acme-api (from go.mod / dirname)

**Modules**:

| name | paths | file_count |
|------|-------|------------|
| billing | `api/billing/`, `internal/billing/`, `proto/billing/` | 45 |
| notifications | `internal/notify/`, `pkg/email/` | 18 |
| root | `cmd/`, `internal/conf/`, `pkg/`, shared proto under `proto/common/` | 22 |

**Exclusions**:
- vendor/
- *_test.go
- *.pb.go, *_grpc.pb.go
- logs/, dist/
- .env (referenced for context only, not copied into TRD body)
```

Hand this draft to Phase 2 (`plan_writer.md`) along with the original `{project_root}` and `{tech_stack}`.
