#!/bin/bash
# generate_plan.sh — Generate TRD_PLAN.md for a project
#
# Usage: ./generate_plan.sh <project_root> <tech_stack>
# Example: ./generate_plan.sh /path/to/project "Go 1.24 (Kratos)"

set -e

PROJECT_ROOT="$1"
TECH_STACK="$2"
TODAY=$(date +%Y-%m-%d)

if [ -z "$PROJECT_ROOT" ] || [ -z "$TECH_STACK" ]; then
    echo "Usage: $0 <project_root> <tech_stack>"
    echo "Example: $0 /path/to/project 'Go 1.24 (Kratos)'"
    exit 1
fi

OUTPUT_FILE="${PROJECT_ROOT}/TRD_PLAN.md"

# Start writing plan
cat > "$OUTPUT_FILE" << EOF
# TRD 生成计划

## 项目信息

- **项目路径**: \`${PROJECT_ROOT}\`
- **技术栈**: ${TECH_STACK}
- **生成日期**: ${TODAY}

## 分析范围

### 排除项
- \`vendor/\` — 第三方依赖
- \`*_test.go\` — 测试文件
- \`*.pb.go\` — protobuf 生成文件
- \`*.swagger.json\` — swagger 生成文件
- \`node_modules/\` — JS 依赖
- \`dist/\`, \`build/\` — 构建输出

### 模块列表

| 序号 | 模块路径 | 文件数 | TRD输出路径 | 状态 |
|------|----------|--------|-------------|------|
EOF

# Find modules (customize based on project structure)
# This is a basic implementation - adjust patterns as needed
MODULE_NUM=1

# Check for apis/back/* pattern (Go Kratos)
if [ -d "${PROJECT_ROOT}/apis/back" ]; then
    for dir in "${PROJECT_ROOT}/apis/back"/*/; do
        if [ -d "$dir" ]; then
            module_name=$(basename "$dir")
            file_count=$(find "$dir" -name "*.proto" 2>/dev/null | wc -l | tr -d ' ')
            echo "| ${MODULE_NUM} | \`apis/back/${module_name}/\` | ${file_count} | \`trd_work/${module_name}/\` | ⏳ 待开始 |" >> "$OUTPUT_FILE"
            MODULE_NUM=$((MODULE_NUM + 1))
        fi
    done
fi

# Check for internal/* pattern
if [ -d "${PROJECT_ROOT}/internal" ]; then
    # Count internal as infrastructure module
    internal_count=$(find "${PROJECT_ROOT}/internal" -name "*.go" ! -name "*_test.go" ! -name "*.pb.go" 2>/dev/null | wc -l | tr -d ' ')
    echo "" >> "$OUTPUT_FILE"
    echo "### 基础设施模块" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "| 序号 | 模块范围 | 文件数 | TRD输出路径 | 状态 |" >> "$OUTPUT_FILE"
    echo "|------|----------|--------|-------------|------|" >> "$OUTPUT_FILE"
    echo "| ${MODULE_NUM} | \`cmd/\`, \`internal/\`, \`pkg/\`, \`configs/\` | ~${internal_count} | \`trd_work/infra/\` | ⏳ 待开始 |" >> "$OUTPUT_FILE"
fi

# Add execution records
cat >> "$OUTPUT_FILE" << 'EOF'

## 执行记录

EOF

# Generate execution record entries
MODULE_NUM=1
if [ -d "${PROJECT_ROOT}/apis/back" ]; then
    for dir in "${PROJECT_ROOT}/apis/back"/*/; do
        if [ -d "$dir" ]; then
            module_name=$(basename "$dir")
            cat >> "$OUTPUT_FILE" << EOF
### 模块 ${MODULE_NUM}: ${module_name}
- **开始时间**: 
- **完成时间**: 
- **状态**: 
- **备注**: 

EOF
            MODULE_NUM=$((MODULE_NUM + 1))
        fi
    done
fi

# Add infra module record
cat >> "$OUTPUT_FILE" << EOF
### 模块 ${MODULE_NUM}: 基础设施 (infra)
- **开始时间**: 
- **完成时间**: 
- **状态**: 
- **备注**: 
EOF

echo "TRD_PLAN.md generated at: ${OUTPUT_FILE}"
echo "Total modules: $((MODULE_NUM))"
