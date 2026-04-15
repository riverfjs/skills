---
name: hk-ipo-multi-compare
description: >-
  Produces a Hong Kong IPO analysis report for one or more listings.
  Extracts M1-M4 data from HKEX prospectus PDFs, fetches peer financials via Chrome MCP,
  and outputs markdown with clickable sources. Use when user asks for HK IPO subscription
  analysis, 打新 comparison, single-name IPO diligence, or side-by-side evaluation of
  Hong Kong issuers.
---

# HK IPO Multi-Name Comparison

## Goal

Deliver a markdown report for 1..N Hong Kong IPO candidates across M1-M4 modules.
For 1 issuer, produce single-name diligence. For 2 issuers, produce side-by-side comparison.
Only produce final ranking and cross-name recommendation when there are more than 2 issuers.

## Hard Constraints

- Always support single-name IPO analysis.
- Always compare issuers only when there is more than 1 issuer.
- Always rank issuers only when there are more than 2 issuers.
- Always cite every numeric claim with a clickable source URL.
- Always output markdown tables instead of screenshots.
- Always use Chrome MCP for browser data collection.
- Always use `curl` only to download prospectus PDFs after Chrome MCP has found the PDF URL.
- Never continue if Chrome MCP is unavailable.
- Never use WebSearch, `curl`, or any fallback tool to replace Chrome MCP for browser data collection when Chrome MCP fails.

## Tooling: Chrome MCP

**MUST use Chrome MCP** — do NOT use WebSearch or `curl` as a browser-data fallback.

Available MCP tools:
- `chrome-devtools-mcp-list_pages` — list open pages
- `chrome-devtools-mcp-new_page` — open new page
- `chrome-devtools-mcp-navigate_page` — navigate to URL
- `chrome-devtools-mcp-evaluate_script` — run JavaScript
- `chrome-devtools-mcp-take_snapshot` — get page content

**If error "Not connected"** — STOP and tell user:
```
Chrome MCP not connected. Please enable it:
1. Open Chrome, go to chrome://flags
2. Search #enable-webmcp-testing
3. Enable "WebMCP for testing"
4. Restart Chrome
5. Re-run this command
```

## Tooling: PDF Extractor

```bash
# Get TOC with page numbers
python3 ~/.agents/skill/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> toc

# Extract specific pages
python3 ~/.agents/skill/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> pages <start> <end>
```

## Workflow

```
Master
├── Phase 1: Setup
│   ├── Create session directory
│   ├── Navigate HKEX, get PDF links
│   └── Download all prospectus PDFs
│
├── Phase 2: Parallel extraction (N subagents, one per issuer)
│   ├── Subagent A: Extract 6656 (M1-M4 + peers from Yahoo)
│   ├── Subagent B: Extract 3277 (M1-M4 + peers from Yahoo)
│   └── Subagent C: Extract 0068 (M1-M4 + peers from Yahoo)
│
├── Phase 3: Analysis (1 subagent)
│   ├── N=1: Generate single-name diligence
│   ├── N=2: Generate side-by-side comparison
│   └── N>2: Generate comparison, ranking, and recommendation
│
└── Phase 4: Master merges final report
```

## Phase 1: Master Setup

1. **Test Chrome MCP connection** using `chrome-devtools-mcp-list_pages`
   - If fails → STOP, show error message from Tooling section, do NOT continue
   - If success → proceed to step 2

2. **Create session directory**
   ```bash
   mkdir -p ~/.cache/hk-ipo-multi-compare/YYYYMMDD-issuer1[-issuer2-issuer3...]
   ```

3. **Open HKEX page** using `chrome-devtools-mcp-new_page`:
   - url: "https://www2.hkexnews.hk/New-Listings/New-Listing-Information/Main-Board?sc_lang=zh-HK"
   - isolatedContext: "hk-ipo-session"

4. **List all rows** using `chrome-devtools-mcp-evaluate_script`:
   ```javascript
   () => Array.from(document.querySelectorAll('tr')).map(tr=>tr.innerText.slice(0,80)).join('\n')
   ```

5. **Extract PDF links** using `chrome-devtools-mcp-evaluate_script`:
   ```javascript
   () => Array.from(document.querySelectorAll('tr')).filter(tr=>tr.innerText.includes('<keyword>')).map(tr=>({text:tr.innerText.slice(0,100),links:Array.from(tr.querySelectorAll('a')).map(a=>a.href)}))
   ```
   - Replace `<keyword>` with the issuer stock code first.
   - If stock code is unavailable, use the issuer short name shown on the HKEX listing page.

6. **Download all PDFs**
   ```bash
   curl -fsSL -o <session>/<code>-prospectus.pdf "<pdf_url>"
   ```

### Phase 2: Parallel Subagents (one per issuer)

Launch N subagents in parallel using Task tool:

```
For each issuer, launch Task with subagent_type: generalPurpose:

"Extract IPO data for [公司名] (code: [XXXX])

Session: ~/.cache/hk-ipo-multi-compare/<session>/
PDF: <session>/<code>-prospectus.pdf

Steps:
1. Get TOC:
   python3 ~/.agents/skill/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> toc

2. Extract pages for each module and write M1-M4 markdown files:
   - M1 (概要): python3 ~/.agents/skill/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> pages <start> <end> → Write to <code>-m1-offering.md
   - M2 (行業概覽): python3 ~/.agents/skill/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> pages <start> <end> → Write to <code>-m2-peers.md
   - M3 (基石投資者): python3 ~/.agents/skill/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> pages <start> <end> → Write to <code>-m3-cornerstone.md
   - M4 (財務資料): python3 ~/.agents/skill/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> pages <start> <end> → Write to <code>-m4-financials.md

3. Identify peer companies from M2 content

4. Fetch peer financials from Yahoo Finance via MCP:
   - Use chrome-devtools-mcp-new_page to open Yahoo Finance
   - Use chrome-devtools-mcp-evaluate_script to get page content

5. Update M2 file with peer financials

Return: List of generated files"
```

### Phase 3: Analysis

After all Phase 2 subagents complete, launch analysis subagent:

1. If `N = 1`, launch one analysis subagent to produce a single-name diligence summary.
2. If `N = 2`, launch one analysis subagent to produce a side-by-side comparison.
3. If `N > 2`, launch one analysis subagent to produce comparison, ranking, and recommendation.
4. Always pass `N` and the issuer code list into the analysis subagent prompt.

```
"Analyze all IPO data.

Read these files:
- <session>/*-m1-offering.md
- <session>/*-m2-peers.md
- <session>/*-m3-cornerstone.md
- <session>/*-m4-financials.md

If N = 1:
- Summarize offering terms, peers, cornerstone support, and financial quality
- Output a single-name diligence conclusion

If N = 2:
- Compare the 2 issuers across entry cost, cornerstone quality, peer valuation, financial trend, and industry outlook
- Output a side-by-side conclusion

If N > 2:
- Compare all issuers across entry cost, cornerstone quality, peer valuation, financial trend, and industry outlook
- Generate final ranking and recommendation

Output format:
- N = 1: 单标的总结 + 打新判断
- N = 2: 双标的对比表 + 结论
- N > 2: 最终排名 + 逐维度对比表 + 综合评分 + 打新建议"
```

### Phase 4: Master Merge

Combine all M1-M4 files + analysis into final `report.md`.

See [reference.md](reference.md) for report template.

## Output Template

Final report at `<session>/report.md` with:
- M1-M4 analysis tables
- Peer financials with Yahoo Finance links
- Single-name conclusion, side-by-side comparison, or ranking depending on issuer count
- All source links

## When NOT to use this skill

- Non-HK listings
- No Chrome / no remote debugging available
