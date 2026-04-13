---
name: hk-ipo-multi-compare
description: >-
  Produces a Hong Kong IPO comparison report for two or more listings side by side.
  Extracts M1-M4 data from HKEX prospectus PDFs, fetches peer financials via Chrome CDP,
  launches subagent for ranking analysis, outputs markdown report with clickable sources.
  Use when user asks for HK IPO subscription analysis, 打新 comparison, multi-ticker IPO
  diligence, or side-by-side new listing evaluation for Hong Kong issuers.
---

# HK IPO Multi-Name Comparison

## Goal

Deliver a markdown report comparing ≥2 Hong Kong IPO candidates across M1-M4 modules, with final ranking and 打新 recommendation.

## Hard Constraints

- **≥2 issuers required** — single-name not supported, ask for another
- **No unsourced numbers** — every figure needs a clickable URL
- **Tables, not screenshots** — markdown tables only
- **Chrome MCP required** — if MCP fails, STOP IMMEDIATELY. Do NOT use WebSearch, curl, or any fallback. Tell user to fix Chrome MCP first.

## Tooling: Chrome MCP

**MUST use Chrome MCP** — do NOT use WebSearch or curl as fallback.

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
python3 ~/.agents/skills/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> toc

# Extract specific pages
python3 ~/.agents/skills/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> pages <start> <end>
```

## Architecture

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
│   └── Read all M1-M4, generate ranking
│
└── Phase 4: Master merges final report
```

## Phase 1: Master Setup

1. **Test Chrome MCP connection** using `chrome-devtools-mcp-list_pages`
   - If fails → STOP, show error message from Tooling section, do NOT continue
   - If success → proceed to step 2

2. **Create session directory**
   ```bash
   mkdir -p ~/.cache/hk-ipo-multi-compare/YYYYMMDD-issuer1-issuer2
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

6. **Download all PDFs**
   ```bash
   curl -fsSL -o <session>/<code>-prospectus.pdf "<pdf_url>"
   ```

## Phase 2: Parallel Subagents (one per issuer)

Launch N subagents in parallel using Task tool:

```
For each issuer, launch Task with subagent_type: generalPurpose:

"Extract IPO data for [公司名] (code: [XXXX])

Session: ~/.cache/hk-ipo-multi-compare/<session>/
PDF: <session>/<code>-prospectus.pdf

Steps:
1. Get TOC:
   python3 ~/.agents/skills/hk-ipo-multi-compare/scripts/extract_pdf.py <pdf> toc

2. Extract pages for each module and write M1-M4 markdown files:
   - M1 (概要): python3 ... pages <start> <end> → Write to <code>-m1-offering.md
   - M2 (行業概覽): python3 ... pages <start> <end> → Write to <code>-m2-peers.md
   - M3 (基石投資者): python3 ... pages <start> <end> → Write to <code>-m3-cornerstone.md  
   - M4 (財務資料): python3 ... pages <start> <end> → Write to <code>-m4-financials.md

3. Identify peer companies from M2 content

4. Fetch peer financials from Yahoo Finance via MCP:
   - Use chrome-devtools-mcp-new_page to open Yahoo Finance
   - Use chrome-devtools-mcp-evaluate_script to get page content

5. Update M2 file with peer financials

Return: List of generated files"
```

## Phase 3: Analysis Subagent

After all Phase 2 subagents complete, launch analysis subagent:

```
"Analyze all IPO data and generate ranking.

Read these files:
- <session>/*-m1-offering.md
- <session>/*-m2-peers.md
- <session>/*-m3-cornerstone.md
- <session>/*-m4-financials.md

Generate ranking based on:
1. 入场费门槛
2. 基石投资者质量和占比
3. 同行估值对比
4. 财务增长趋势
5. 行业前景

Output format:
- 最终排名: 综上，A > B > C
- 逐维度对比表
- 综合评分
- 打新建议"
```

## Phase 4: Master Merge

Combine all M1-M4 files + analysis into final `report.md`.

See [reference.md](reference.md) for report template.

## Output

Final report at `<session>/report.md` with:
- M1-M4 comparison tables
- Peer financials with Yahoo Finance links
- Ranking and recommendation
- All source links

## When NOT to use this skill

- Single-name-only IPO analysis
- Non-HK listings
- No Chrome / no remote debugging available
