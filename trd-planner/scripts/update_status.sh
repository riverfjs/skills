#!/bin/bash
# update_status.sh — Update module status in TRD_PLAN.md
#
# Usage: ./update_status.sh <plan_file> <module_name> <status> [notes]
# Example: ./update_status.sh TRD_PLAN.md activity "✅ 完成" "9 files, 2330 lines"

set -e

PLAN_FILE="$1"
MODULE_NAME="$2"
STATUS="$3"
NOTES="$4"
NOW=$(date "+%Y-%m-%d %H:%M")

if [ -z "$PLAN_FILE" ] || [ -z "$MODULE_NAME" ] || [ -z "$STATUS" ]; then
    echo "Usage: $0 <plan_file> <module_name> <status> [notes]"
    exit 1
fi

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file not found: $PLAN_FILE"
    exit 1
fi

# Update table status
sed -i.bak "s/\`${MODULE_NAME}\/\`.*⏳ 待开始/\`${MODULE_NAME}\/\` | ... | ... | ${STATUS}/" "$PLAN_FILE"

# Update execution record
# This is a simplified version - may need adjustment for complex cases
if [ "$STATUS" = "✅ 完成" ]; then
    # Find the module section and update
    sed -i.bak "/### 模块.*: ${MODULE_NAME}/,/### 模块/{
        s/- \*\*完成时间\*\*: /- **完成时间**: ${NOW}/
        s/- \*\*状态\*\*: /- **状态**: ✅ 完成/
        s/- \*\*备注\*\*: /- **备注**: ${NOTES}/
    }" "$PLAN_FILE"
fi

# Clean up backup
rm -f "${PLAN_FILE}.bak"

echo "Updated ${MODULE_NAME} status to: ${STATUS}"
