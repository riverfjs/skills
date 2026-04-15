#!/bin/bash
# concat_trd.sh — Concatenate TRD sections with zero information loss
#
# Usage: ./concat_trd.sh <output_dir> <module_path>
# Example: ./concat_trd.sh /path/to/trd_work/asset apis/back/asset
#
# Expected section files (in order):
#   section_1_overview.md
#   section_2_architecture.md
#   section_3_data_model.md
#   section_4_interface.md
#   section_5_*.md (all core logic parts, sorted)
#   section_6_*.md (all config/data parts, sorted)
#   section_7_*.md (all observability parts, sorted)
#   section_8_file_index.md

set -e

OUTPUT_DIR="$1"
MODULE_PATH="$2"

if [ -z "$OUTPUT_DIR" ] || [ -z "$MODULE_PATH" ]; then
    echo "Usage: $0 <output_dir> <module_path>"
    exit 1
fi

cd "$OUTPUT_DIR"

# Create TRD with title
echo "# ${MODULE_PATH} — Technical Requirements Document (TRD)" > TRD.md
echo "" >> TRD.md

# Function to append section with separator
append_section() {
    local file="$1"
    if [ -f "$file" ]; then
        cat "$file" >> TRD.md
        echo "" >> TRD.md
        echo "---" >> TRD.md
        echo "" >> TRD.md
        return 0
    fi
    return 1
}

# Function to append multi-part section files
# First file: include everything
# Subsequent files: skip first line (the duplicate ## N. title) and any empty lines after it
append_multipart_section() {
    local section_num="$1"
    local files=$(ls section_${section_num}_*.md 2>/dev/null | sort || true)
    
    if [ -z "$files" ]; then
        return 1
    fi
    
    local first=true
    for f in $files; do
        if [ "$first" = true ]; then
            # First file: include everything
            cat "$f" >> TRD.md
            echo "" >> TRD.md
            first=false
        else
            # Subsequent files: skip lines starting with "## N." (section header)
            # This removes duplicate "## 5. Core Logic" headers
            tail -n +2 "$f" | sed '/^## [0-9]\./d' >> TRD.md
            echo "" >> TRD.md
        fi
    done
    
    echo "---" >> TRD.md
    echo "" >> TRD.md
    return 0
}

# Section 1: Overview
append_section "section_1_overview.md" || true

# Section 2: Architecture
append_section "section_2_architecture.md" || true

# Section 3: Data Model
append_section "section_3_data_model.md" || true

# Section 4: Interface
append_section "section_4_interface.md" || true

# Section 5: Core Logic (all parts, remove duplicate headers)
append_multipart_section "5" || true

# Section 6: Config / Data Access (all parts, remove duplicate headers)
append_multipart_section "6" || true

# Section 7: Observability (all parts, remove duplicate headers)
append_multipart_section "7" || true

# Section 8: File Index (no trailing separator)
if [ -f "section_8_file_index.md" ]; then
    cat "section_8_file_index.md" >> TRD.md
    echo "" >> TRD.md
fi

# Remove trailing separator if exists
sed -i.bak '${/^---$/d;}' TRD.md 2>/dev/null || true
rm -f TRD.md.bak

# Remove multiple consecutive blank lines
sed -i.bak '/^$/N;/^\n$/d' TRD.md 2>/dev/null || true
rm -f TRD.md.bak

echo "=== TRD Concatenation Complete ==="
echo ""
echo "Output: ${OUTPUT_DIR}/TRD.md"
echo ""

# Report line counts
echo "=== Section Line Counts ==="
for f in section_*.md; do
    if [ -f "$f" ]; then
        lines=$(wc -l < "$f" | tr -d ' ')
        printf "  %-40s %s lines\n" "$f" "$lines"
    fi
done

echo ""
SECTION_TOTAL=$(cat section_*.md 2>/dev/null | wc -l | tr -d ' ')
TRD_TOTAL=$(wc -l < TRD.md | tr -d ' ')

echo "=== Summary ==="
echo "Section files total: ${SECTION_TOTAL} lines"
echo "TRD.md total: ${TRD_TOTAL} lines"
echo "Difference: $((TRD_TOTAL - SECTION_TOTAL)) lines (may be negative due to removed duplicate headers)"

echo ""
echo "✅ Concatenation successful"
