# TRD Plan Template

This file is the **only** authoritative shape for `{project_root}/TRD_PLAN.md`.
The `prompts/plan_writer.md` agent fills the placeholders below; nothing else.

---

## Template (everything between BEGIN and END goes into TRD_PLAN.md)

```markdown
<!-- BEGIN TRD_PLAN.md -->
# TRD 生成计划

## 项目信息

- **项目路径**: `{{project_root}}`
- **项目名称**: {{project_name}}
- **技术栈**: {{tech_stack}}
- **入口**: {{entry_points}}
- **生成日期**: {{date}}

## 分析范围

### 排除项
{{exclusions_bullet_list}}

### 模块列表 ({{module_count}} 个)

| 序号 | 模块名 | 模块路径 / 范围 | 文件数 | TRD 输出路径 | 状态 |
|------|--------|----------------|--------|-------------|------|
{{module_rows}}

## 分析规范(所有模块必须遵守)

### 1. TRD 格式要求
{{format_rules}}

### 2. 项目描述要求
{{project_context_rules}}

### 3. 跨路径查找要求
{{cross_path_rules}}

### 4. 细节分析要求
{{detail_rules}}

### 5. [INFERRED] 处理要求
{{inferred_rules}}

## 执行记录

{{execution_blocks}}
<!-- END TRD_PLAN.md -->
```

---

## Placeholder Specifications

| Placeholder | Filled From | Format |
|-------------|-------------|--------|
| `{{project_root}}` | scanner Phase 1 input | absolute path |
| `{{project_name}}` | derived from `basename {{project_root}}` or `go.mod` / `package.json` | short string |
| `{{tech_stack}}` | scanner inspection of `go.mod` / `package.json` / `pyproject.toml` etc. | one line, e.g. "Go 1.24 (Kratos)" |
| `{{entry_points}}` | scanner finds `main.go` / `cmd/*` / `index.ts` etc. | comma-separated paths |
| `{{date}}` | today (YYYY-MM-DD) | ISO date |
| `{{exclusions_bullet_list}}` | scanner exclusions(defaults + tech-stack additions) | markdown bullet list |
| `{{module_count}}` | length of module list | integer |
| `{{module_rows}}` | one row per module | see Module Row Format below |
| `{{format_rules}}` ... `{{inferred_rules}}` | plan_writer defaults customized to project | markdown bullet list, ≤ 6 bullets each |
| `{{execution_blocks}}` | one 4-line block per module, all values blank | see Execution Block Format below |

### Module Row Format

```
| {N} | {module_name} | `{path1}`, `{path2}` ... | {file_count} | `trd_work/{module_name}/` | ⏳ 待开始 |
```

- `module_name`: lowercase, hyphen-or-snake, no spaces
- 路径列允许写多个目录或子目录,用逗号分隔;不要列单文件
- 状态初始一律 `⏳ 待开始`

### Status Values

| Status | Meaning |
|--------|---------|
| ⏳ 待开始 | Not started |
| 🔄 进行中 | In progress |
| ✅ 完成 | Completed |
| ⚠️ 跳过 | Skipped (reason in 备注) |
| ❌ 失败 | Failed |

### Execution Block Format

```
### 模块 {N}: {module_name}
- **开始时间**: 
- **完成时间**: 
- **状态**: ⏳ 待开始
- **备注**: 
```

All four fields stay blank (or `⏳ 待开始` for 状态) at planning time. Execution phase fills them.

### Default Bullets for Analysis Conventions

Plan writer SHOULD start from these defaults, then customize per project. Do not delete a section.

- **§1 TRD 格式要求**:遵循 `trd-writer-v2` 的 `trd_template.md` / `reference.md` 结构;TRD 标题格式 `# {module_path} — Technical Requirements Document (TRD)`;不写生成时间等元数据;Mermaid 图表语法必须正确。
- **§2 项目描述要求**:每个 TRD 在 §1.1 Project Summary 第一句声明本模块在 `{project_name}` 中的定位、对外暴露的接口/服务名、与其他模块的依赖关系。
- **§3 跨路径查找要求**:允许跨目录查找数据库模型、配置、外部客户端、wire 装配等;每条 `[INFERRED]` 必须经 Reviewer 跨路径核实。
- **§4 细节分析要求**:核心业务逻辑、算法公式(LaTeX)、状态机、所有 RPC/HTTP 接口、所有数据表字段必须完整记录,不得 "etc." / "similar to above"。
- **§5 [INFERRED] 处理要求**:仅用于"代码无法证明的运行期事实";Reviewer 必须将 `[INFERRED]` 改写为事实(给证据)或保留并降级为 `[UNRESOLVED]`(给一行原因)。

---

## 禁止字段(planner 不可写入,违反即视为失败)

写入 `TRD_PLAN.md` 之前,plan_writer 必须自检:**以下任何字段或措辞都不允许出现**。

| 禁止项 | 原因 |
|-------|------|
| "建议 Worker 拆分" / "Worker 切片" / "Vertical Slice" / "Sub-task Worker" | Worker 拆分由 `trd-writer-v2` Coordinator 决定 |
| "推荐执行顺序" / "Execution Order" / "执行优先级" | 模块之间默认无序,顺序由用户/调度决定 |
| 文件 → Worker 映射表 | 同上,属 Coordinator 输出 |
| "架构概览" / "Architecture Overview" 散文段 | 模块表已表达;散文段会与 TRD 内容重复 |
| 任何 `trd-writer-v2` 的 prompt / 阶段说明 | skill 边界,`trd-planner` 不该重复 |
| 已完成模块的实际备注内容 | 由执行阶段(`update_status.sh`)回填 |
| `mermaid` / 流程图 / 时序图 | TRD 才需要图;PLAN 是目录 |

自检命令:

```bash
grep -nE "Worker|切片|Vertical Slice|执行顺序|Execution Order|架构概览|Architecture Overview|mermaid" {project_root}/TRD_PLAN.md
# Expected: 0 matches (除非项目模块名本身含这些词)
```

如有命中且非模块名误伤,立即删除并重写相应段落。
