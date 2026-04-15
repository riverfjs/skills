---
name: chrome-cdp
description: Interact with local Chrome browser session (only on explicit user approval after being asked to inspect, debug, or interact with a page open in Chrome)
---

# Chrome CDP

Lightweight Chrome DevTools Protocol CLI. Connects directly via WebSocket — no Puppeteer, works with 100+ tabs, instant connection.

## Prerequisites

- Chrome (or Chromium, Brave, Edge, Vivaldi) with remote debugging enabled: open `chrome://inspect/#remote-debugging` and toggle the switch
- Node.js 22+ (uses built-in WebSocket)
- If your browser's `DevToolsActivePort` is in a non-standard location, set `CDP_PORT_FILE` to its full path

## Hard Constraints

- Never use `shot` to read page content. Use it only for visual debugging as a last resort.
- Always prefer `eval` plus `getBoundingClientRect()` over `shot` to find element coordinates.
- Always prefer `clickxy` over `click <selector>` unless you have a specific reason to use DOM click.
- Always check `window.location.href` and `list` after clicking.
- Always collect volatile page data in one `eval` call when possible.
- Never switch to MCP when the user explicitly requires CDP. CDP may have login state that MCP does not.

## Commands

All commands use `scripts/cdp.mjs`. The `<target>` is a **unique** targetId prefix from `list`.

```bash
scripts/cdp.mjs list                          # list all open tabs (* marks current active tab)
scripts/cdp.mjs eval   <target> <expr>        # run JS in page context
scripts/cdp.mjs clickxy <target> <x> <y>      # real mouse click at CSS px coords (preferred)
scripts/cdp.mjs click  <target> <selector>    # DOM click by CSS selector (SPA-unreliable)
scripts/cdp.mjs nav    <target> <url>         # navigate and wait for load
scripts/cdp.mjs snap   <target>               # accessibility tree (token-light alternative to shot)
scripts/cdp.mjs type   <target> <text>        # insert text at current focus
scripts/cdp.mjs html   <target> [selector]    # full page or element HTML
scripts/cdp.mjs shot   <target> [file]        # screenshot (last resort, very token-heavy)
scripts/cdp.mjs open   [url]                  # open new tab
scripts/cdp.mjs stop   [target]               # stop daemon(s)
```

## Active Tab Detection (macOS)

`list` automatically marks the currently focused Chrome tab with `*` using AppleScript:

```
(* = current active tab in Chrome)
* B5404DDD  MiMo-V2-Pro & Omni & TTS ...   https://www.reddit.com/...
  5BE8FE3C  Google 新聞                      https://news.google.com/...
```

- On first run, macOS may show an automation permission dialog — click Allow once.
- Only works on macOS; silently skipped on other platforms.
- Reflects the real Chrome foreground tab, updates on every `list` call.
- **Use this to quickly identify the target without manually matching URLs.**

## Coordinates

`shot` saves at native resolution: image pixels = CSS pixels × DPR. `clickxy` takes **CSS pixels**.
Use this conversion only if you already have a screenshot for visual debugging. Do not take a screenshot just to compute click coordinates.

```
CSS px = screenshot px / DPR
```

## Workflow

### Identify the right target quickly

```bash
# Run list — the * tab is what the user currently has open in Chrome
scripts/cdp.mjs list
# → use the * prefix directly as <target>
```

### Click a JS-driven link (SPA / Google News / React apps)

```bash
# 1. Get element center in CSS px via JS (no screenshot needed)
eval <target> "var el=document.querySelector('a[href*=\"keyword\"]'); var r=el.getBoundingClientRect(); ((r.left+r.right)/2)+','+((r.top+r.bottom)/2)"
# → "908,555"

# 2. Click using real mouse input
clickxy <target> 908 555

# 3a. Check if current tab navigated
eval <target> "window.location.href"

# 3b. Check if a new tab opened (compare before/after)
list
```

### Detect new tab after click

```bash
# Before click — note existing targetIds
list
# Click ...
# After click — new entry = new tab
list
# Inspect the new tab
eval <new-target-prefix> "window.location.href"
eval <new-target-prefix> "document.title"
```

### Inspect page content efficiently

```bash
# Preferred: JS query (near-zero tokens)
eval <target> "document.title"
eval <target> "Array.from(document.querySelectorAll('a[href*=\"/news/\"]')).map(a=>a.innerText+' | '+a.href).join('\n')"

# Alternative: accessibility tree (compact, structured)
snap <target>

# Avoid: screenshot (only when visual layout truly needed)
shot <target>
```

## Token Cost Guide

| Command | Relative cost | Use when |
|---------|--------------|----------|
| `eval`  | Very low     | Reading text, coords, URLs, DOM state |
| `snap`  | Low–Medium   | Need page structure overview |
| `html`  | Medium       | Need raw HTML of a section |
| `shot`  | Very high    | Visual debugging only (last resort) |

## Examples

| Example | Description |
|---------|-------------|
| [`examples/fetch-hook-api-capture.md`](examples/fetch-hook-api-capture.md) | Intercept SPA API responses by injecting a fetch/XHR hook via `eval` — covers inject → trigger → read → paginate workflow |

## When NOT to use this skill

- Page content can be fetched statically (use `WebFetch` instead).
- User has not explicitly asked to interact with Chrome.
