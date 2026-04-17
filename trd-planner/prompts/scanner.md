# Scanner Prompt — Phase 1 of trd-planner

Your job: scan `{project_root}` and produce a draft module list + final exclusion list.
Do **not** write `TRD_PLAN.md` here — that is Phase 2 (`plan_writer.md`).

## Inputs

- `{project_root}` (absolute path, required)
- `{tech_stack_hint}` (optional, e.g. "Go", "Python+FastAPI") — if omitted, infer from manifest files

## Hard Constraints

- Always run scan commands; never invent file counts.
- Always group by **business domain** first (e.g. `member` vs `sumsub`); fall back to architectural layer only when no domain split is detectable.
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

1. **Domain-first split** — if subdirs under `apis/`, `pkg/`, `internal/biz/`, `internal/service/`, `src/model/`, `src/service/` cluster around clear business nouns (e.g. `member`, `sumsub`, `order`, `payment`), one module per noun. A module spans **all layers** of the same noun (proto + model + service + biz).
2. **Layered split** — if no domain clustering exists, split by architectural layer (`apis/`, `internal/service/`, `cmd/`, `pkg/`).
3. **Single-module fallback** — if the project is small or homogeneous, declare 1 module.

Always add a `root` module covering: entry point(s), shared utilities (`common/util`, `internal/conf`, `pkg/`), and shared proto (`Common/`). Mark it as the last module.

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

Return to the conversation a structured draft like this (Markdown):

```markdown
### Scan Result

**Tech stack**: Go 1.14 + gRPC + GORM (MySQL) + Beego
**Entry points**: `src/cmd/uci/main.go`
**Project name**: uci_v2 (from go.mod)

**Modules**:

| name | paths | file_count |
|------|-------|------------|
| member | src/common/protos/pb/Member, src/model/member*.go..., src/service/member*.go... | 32 |
| sumsub | src/common/protos/pb/Kyc, src/model/KycSumsub*.go, src/service/KycSumsub*.go | 9 |
| root | src/cmd/uci, src/common/util, src/common/protos/pb/Common, src/service/common.go | 10 |

**Exclusions**:
- vendor/
- *_test.go
- *.pb.go, *_grpc.pb.go
- logs/, sbin/
- shell/, build.sh
- conf/config.ini (referenced for context only)
```

Hand this draft to Phase 2 (`plan_writer.md`) along with the original `{project_root}` and `{tech_stack}`.
