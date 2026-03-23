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

- **Never use `shot` to read page content** — screenshots are massive base64 blobs, extremely token-costly. Only use for visual debugging as a last resort.
- **Prefer `eval` + `getBoundingClientRect()` over `shot` to find element coords** — zero extra tokens.
- **Use `clickxy` instead of `click <selector>` by default** — CSS selector click is intercepted by JS-driven SPAs (React, Google News, etc.); `clickxy` sends real mouse input events and is far more reliable.
- **After clicking, always check where navigation went** — run `eval "window.location.href"` to see if current tab changed, AND run `list` to detect if a new tab was opened.
- **Collect all data in one `eval` call** — avoid multiple sequential `eval` calls when the DOM may change between them.

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

## When NOT to use this skill

- Page content can be fetched statically (use `WebFetch` instead).
- User has not explicitly asked to interact with Chrome.
