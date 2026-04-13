#!/usr/bin/env python3
"""
HK IPO Prospectus PDF Extractor

Usage:
    python3 extract_pdf.py <pdf_path> toc              # Show table of contents with page numbers
    python3 extract_pdf.py <pdf_path> pages <start> [end]  # Extract pages content

Examples:
    python3 extract_pdf.py prospectus.pdf toc
    python3 extract_pdf.py prospectus.pdf pages 1 5    # Pages 1-5
    python3 extract_pdf.py prospectus.pdf pages 84     # Single page 84
"""

import fitz
import sys
import os
import re


def parse_toc(doc):
    """Parse table of contents to get chapter page numbers."""
    toc = {}
    toc_keywords = [
        '概要',
        '行業概覽',
        '業務',
        '基石投資者',
        '財務資料',
        '風險因素',
        '未來計劃及所得款項用途',
    ]
    
    # Find TOC pages
    for page_num in range(min(20, len(doc))):
        text = doc[page_num].get_text()
        if '目' in text and '錄' in text:
            lines = text.split('\n')
            for i, line in enumerate(lines):
                for keyword in toc_keywords:
                    if keyword in line and keyword not in toc:
                        # Page number on same line or next line
                        nums = re.findall(r'(\d+)\s*$', line.strip())
                        if nums:
                            toc[keyword] = int(nums[-1])
                        elif i + 1 < len(lines):
                            next_line = lines[i + 1].strip()
                            if re.match(r'^\d+$', next_line):
                                toc[keyword] = int(next_line)
    
    return toc


def get_page_offset(doc):
    """Calculate offset between display page numbers and actual page indices."""
    for i in range(min(30, len(doc))):
        text = doc[i].get_text()
        match = re.search(r'–\s*(\d+)\s*–', text)
        if match:
            display_page = int(match.group(1))
            return i - display_page + 1
    return 9  # Default offset


def show_toc(doc):
    """Show table of contents with actual page indices."""
    toc = parse_toc(doc)
    offset = get_page_offset(doc)
    
    print("## 目录 (Table of Contents)\n")
    print("| 章节 | 显示页码 | 实际页码 |")
    print("|------|----------|----------|")
    
    for chapter, display_page in sorted(toc.items(), key=lambda x: x[1]):
        actual_page = display_page + offset - 1
        print(f"| {chapter} | {display_page} | {actual_page + 1} |")
    
    print(f"\n页码偏移量: {offset}")
    print(f"总页数: {len(doc)}")
    
    # Also output suggested commands
    print("\n## 建议命令\n")
    if '概要' in toc:
        p = toc['概要'] + offset - 1
        print(f"M1 招股概要: python3 extract_pdf.py <pdf> pages {p+1} {p+10}")
    if '行業概覽' in toc:
        p = toc['行業概覽'] + offset - 1
        print(f"M2 同行对比: python3 extract_pdf.py <pdf> pages {p+1} {p+15}")
    if '基石投資者' in toc:
        p = toc['基石投資者'] + offset - 1
        print(f"M3 基石投资: python3 extract_pdf.py <pdf> pages {p+1} {p+10}")
    if '財務資料' in toc:
        p = toc['財務資料'] + offset - 1
        print(f"M4 财务数据: python3 extract_pdf.py <pdf> pages {p+1} {p+15}")


def extract_pages(doc, start, end=None):
    """Extract text from specific pages."""
    if end is None:
        end = start
    
    # Convert to 0-indexed
    start_idx = start - 1
    end_idx = end
    
    if start_idx < 0 or end_idx > len(doc):
        print(f"Error: Invalid page range. PDF has {len(doc)} pages.")
        return
    
    for page_num in range(start_idx, end_idx):
        print(f"\n{'='*60}")
        print(f"PAGE {page_num + 1}")
        print('='*60)
        print(doc[page_num].get_text())


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    command = sys.argv[2]
    
    try:
        doc = fitz.open(pdf_path)
    except Exception as e:
        print(f"Error: Failed to open PDF: {e}")
        sys.exit(1)
    
    if command == 'toc':
        show_toc(doc)
    elif command == 'pages':
        if len(sys.argv) < 4:
            print("Error: 'pages' command requires start page number")
            sys.exit(1)
        start = int(sys.argv[3])
        end = int(sys.argv[4]) if len(sys.argv) > 4 else None
        extract_pages(doc, start, end)
    else:
        print(f"Error: Unknown command '{command}'")
        print("Available: toc, pages")
        sys.exit(1)
    
    doc.close()


if __name__ == '__main__':
    main()
