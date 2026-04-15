# TRD Plan Template

Use this template to generate `TRD_PLAN.md` for a project.

```markdown
# TRD 生成计划

## 项目信息

- **项目路径**: `{project_root}`
- **技术栈**: {tech_stack}
- **生成日期**: {date}

## 分析范围

### 排除项
- `vendor/` — 第三方依赖
- `*_test.go` — 测试文件
- `*.pb.go` — protobuf 生成文件
- `*.swagger.json` — swagger 生成文件
- `node_modules/` — JS 依赖
- `dist/`, `build/` — 构建输出
{additional_exclusions}

### 模块列表 ({module_count}个)

| 序号 | 模块路径 | 文件数 | TRD输出路径 | 状态 |
|------|----------|--------|-------------|------|
| 1 | `{module_path_1}` | {file_count} | `trd_work/{module_name}/` | ⏳ 待开始 |
| 2 | `{module_path_2}` | {file_count} | `trd_work/{module_name}/` | ⏳ 待开始 |
...

## 执行记录

### 模块 1: {module_name}
- **开始时间**: 
- **完成时间**: 
- **状态**: 
- **备注**: 

### 模块 2: {module_name}
- **开始时间**: 
- **完成时间**: 
- **状态**: 
- **备注**: 

...
```

## Field Descriptions

| Field | Description |
|-------|-------------|
| `{project_root}` | Absolute path to project |
| `{tech_stack}` | e.g., "Go 1.24 (Kratos)", "Python 3.11 (FastAPI)" |
| `{date}` | Plan creation date (YYYY-MM-DD) |
| `{module_path}` | Relative path from project root |
| `{file_count}` | Number of source files (excluding tests/generated) |
| `{module_name}` | Short name for TRD output directory |

## Status Values

| Status | Meaning |
|--------|---------|
| ⏳ 待开始 | Not started |
| 🔄 进行中 | In progress |
| ✅ 完成 | Completed |
| ❌ 跳过 | Skipped (with reason in notes) |

## Execution Record Fields

| Field | Description |
|-------|-------------|
| 开始时间 | Start timestamp (YYYY-MM-DD HH:MM) |
| 完成时间 | End timestamp |
| 状态 | Final status (✅ 完成, ❌ 失败) |
| 备注 | File count, worker count, TRD line count, issues |
