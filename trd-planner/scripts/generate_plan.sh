#!/bin/bash
# generate_plan.sh — Emit a placeholder TRD_PLAN.md skeleton.
#
# This script is intentionally dumb: it writes the template skeleton with
# {{placeholder}} markers and one blank module/execution slot. The LLM
# (plan_writer.md prompt) is responsible for filling placeholders, expanding
# the module list, and customising the Analysis-Conventions bullets.
#
# Usage:
#   ./generate_plan.sh <project_root> <tech_stack>
#
# Example:
#   ./generate_plan.sh /path/to/project "Go 1.24 (Kratos)"

set -euo pipefail

PROJECT_ROOT="${1:-}"
TECH_STACK="${2:-}"
TODAY="$(date +%Y-%m-%d)"

if [ -z "$PROJECT_ROOT" ] || [ -z "$TECH_STACK" ]; then
    echo "Usage: $0 <project_root> <tech_stack>" >&2
    exit 1
fi

if [ ! -d "$PROJECT_ROOT" ]; then
    echo "Error: project root not found: $PROJECT_ROOT" >&2
    exit 1
fi

OUTPUT_FILE="${PROJECT_ROOT}/TRD_PLAN.md"

if [ -f "$OUTPUT_FILE" ]; then
    echo "Refusing to overwrite existing $OUTPUT_FILE" >&2
    echo "Delete it first if you want to regenerate." >&2
    exit 2
fi

PROJECT_NAME="$(basename "$PROJECT_ROOT")"

cat > "$OUTPUT_FILE" <<EOF
# TRD 生成计划

## 项目信息

- **项目路径**: \`${PROJECT_ROOT}\`
- **项目名称**: ${PROJECT_NAME}
- **技术栈**: ${TECH_STACK}
- **入口**: {{entry_points}}
- **生成日期**: ${TODAY}

## 分析范围

### 排除项
{{exclusions_bullet_list}}

### 模块列表 ({{module_count}} 个)

| 序号 | 模块名 | 模块路径 / 范围 | 文件数 | TRD 输出路径 | 状态 |
|------|--------|----------------|--------|-------------|------|
| 1 | {{module_name}} | \`{{module_paths}}\` | {{file_count}} | \`trd_work/{{module_name}}/\` | ⏳ 待开始 |

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

### 模块 1: {{module_name}}
- **开始时间**:
- **完成时间**:
- **状态**: ⏳ 待开始
- **备注**:
EOF

echo "Skeleton written: ${OUTPUT_FILE}"
echo "Now: edit it via the plan_writer.md prompt to fill placeholders and expand modules."
