---
name: skill-creator
description: Create or update reusable agent skills. Use when the user asks to build a new skill, refactor repeated workflows into a skill, or improve skill structure and SKILL.md quality.
---

# Skill Creator

Create high-quality, reusable agent skills.

## Before You Start: Gather Requirements

Before creating a skill, gather:

1. **Purpose and scope**: What specific workflow should this skill solve?
2. **Trigger scenarios**: When should the agent automatically use it?
3. **Target location**: Project skill or runtime workspace skill?
4. **Domain constraints**: Required tools, APIs, reliability constraints.
5. **Output style**: Report template, checklist, strict schema, etc.
6. **Existing patterns**: Are there existing skills or conventions to follow?

### Inferring from Context

If you have previous conversation context, infer the skill from what was discussed — workflows, patterns, or domain knowledge that emerged in the conversation.

Ask the user when requirements are ambiguous and discrete choices are needed.

## Skill File Structure

### Directory Layout

```
skill-name/
├── SKILL.md            # required
├── scripts/            # optional utility scripts
├── bin/                # optional compiled binaries
└── reference.md        # optional detailed docs
```

### Storage Locations

| Type | Path | Scope |
|------|------|-------|
| Personal | `~/.agents/skills/<skill-name>/` | Available across all projects |
| Project | `.agents/skills/<skill-name>/` | Bundled with the project |

## SKILL.md Requirements

- Keep SKILL.md concise (prefer under 500 lines).
- Frontmatter fields:
  - `name`: lowercase letters, numbers, hyphens only.
  - `description`: include WHAT and WHEN.
- Write SKILL.md in English for consistent triggering.

## Description Quality Rules

The description is **critical** for skill discovery. The agent uses it to decide when to apply the skill.

1. **Write in third person** (the description is injected into the system prompt):
   - Good: "Processes Excel files and generates reports"
   - Avoid: "I can help you process Excel files"

2. **Be specific and include trigger terms**:
   - Good: "Fetch and verify one specific news event with minimal tool calls. Use when user asks whether a specific claim is true."
   - Vague: "Helps with news."

3. **Include both WHAT and WHEN**:
   - WHAT: What the skill does (specific capabilities)
   - WHEN: When the agent should use it (trigger scenarios)

## Core Authoring Principles

### 1. Concise is Key

The context window is shared with conversation history, other skills, and requests. Every token competes for space.

**Default assumption**: The agent is already very smart. Only add context it doesn't already have.

Challenge each piece of information:
- "Does the agent really need this explanation?"
- "Can I assume the agent knows this?"
- "Does this paragraph justify its token cost?"

### 2. Progressive Disclosure

Put essential information in SKILL.md; detailed reference material in separate files that the agent reads only when needed.

**Keep references one level deep** — link directly from SKILL.md to reference files. Deeply nested references may result in partial reads.

### 3. One File, One Concern

Each skill should address a single workflow. If a skill tries to do too many things, split it.

### 4. Maximize Determinism

Skills are executed via multiple independent tool calls (file writing, shell commands, etc.). Each call is stateless — no shared session or persistent variables between calls.

**Core rule**: Eliminate ambiguity at every layer — description, workflow, script parameters, and output format.

- **Internalize decisions**: If a value can be decided inside a script (output path, temp filename, timestamp), do not expose it as a parameter.
- **Use fixed literal paths in workflows**: The agent copies commands verbatim. Never rely on shell variables staying consistent across separate tool calls.
- **Minimize script parameters**: Each exposed parameter is a point of failure. Only require what the agent *must* provide.
- **Scripts return structured JSON to stdout**: The agent parses the result deterministically.
- **Specify exact tool call sequence**: e.g. "Exactly 3 steps: write file → run command → deliver output."
- **Add stop conditions**: Prevent open-ended tool loops for expensive operations.

### 5. Set Appropriate Degrees of Freedom

Match specificity to the task's fragility:

| Freedom Level | When to Use | Example |
|---------------|-------------|---------|
| **High** (text instructions) | Multiple valid approaches, context-dependent | Code review guidelines |
| **Medium** (pseudocode/templates) | Preferred pattern with acceptable variation | Report generation |
| **Low** (specific scripts) | Fragile operations, consistency critical | Database migrations |

## Recommended SKILL.md Sections

1. Goal
2. Hard Constraints
3. Workflow
4. Output Template
5. When NOT to use this skill

## Common Patterns

### Workflow Pattern

Break operations into explicit steps with clear tool-call sequence:

```markdown
## Workflow

1. Gather input data
2. Process: `<exact command the agent should run>`
3. Parse output, proceed to next step
4. Stop when condition met
```

### Template Pattern

Provide output format templates:

```markdown
## Output Template

\`\`\`markdown
# [Title]

## Summary
[One-paragraph overview]

## Findings
- Finding 1 with supporting data
- Finding 2 with supporting data
\`\`\`
```

### Conditional Workflow Pattern

Guide through decision points:

```markdown
## Workflow

1. Determine the type:
   **Creating new?** → Follow "Creation workflow" below
   **Editing existing?** → Follow "Editing workflow" below
```

### Feedback Loop Pattern

For quality-critical tasks, implement validation:

```markdown
1. Make edits
2. Validate: `python scripts/validate.py output/`
3. If validation fails → fix and re-validate
4. Only proceed when validation passes
```

## Utility Scripts

Pre-made scripts offer advantages over generated code:
- More reliable than generated code
- Save tokens (no code in context)
- Ensure consistency across uses

**Script design rules**:
- Only expose parameters the agent *must* supply (input data, mode selection).
- Let the script handle all internal decisions (output path, temp files, format defaults).
- Return results as structured JSON to stdout.
- Make clear whether the agent should **execute** the script or **read** it as reference.

## Anti-Patterns

### 1. Cross-Step Variable Sharing

Each tool call is independent and stateless. Shell variables set in one call do not exist in the next.

```markdown
# Bad — variable $TS differs between Write and Bash calls
Write content to /tmp/data-$TS.txt     # tool call 1: timestamp A
Bash: cmd --input /tmp/data-$TS.txt    # tool call 2: timestamp B → file not found

# Good — use a fixed path; let script handle dynamic naming internally
Write content to /var/skill-name/input.txt
Bash: cmd --input /var/skill-name/input.txt
```

### 2. Exposing Internal Decisions as Parameters

If a value can be determined by the script itself, do not expose it as a parameter.

```markdown
# Bad — unnecessary parameters the agent must coordinate
cmd --input file.txt --output out.png --format png --theme default

# Good — only the essential input; script decides the rest
cmd --input file.txt
```

### 3. Too Many Options

```markdown
# Bad
"You can use pypdf, or pdfplumber, or PyMuPDF, or..."

# Good — provide a default with escape hatch
"Use pdfplumber for text extraction.
For scanned PDFs requiring OCR, use pdf2image with pytesseract instead."
```

### 4. Missing Stop Conditions

Multiple broad search loops without explicit exit criteria.

### 5. Mixing Unrelated Workflows

One skill should not address multiple unrelated concerns. Split into separate skills.

### 6. Vague Skill Names

- Good: `processing-pdfs`, `render-mermaid`
- Avoid: `helper`, `utils`, `tools`

## Creation Workflow

### Phase 1: Discovery

- Clarify user intent and boundaries.
- Capture tool budget and reliability requirements.
- Identify overlap with existing skills.

### Phase 2: Design

- Choose a specific skill name.
- Draft trigger-rich description.
- Decide script/no-script approach.
- Define success criteria and stop criteria.

### Phase 3: Implementation

- Create directory and SKILL.md.
- Add optional scripts in `scripts/` only when needed.
- Keep commands deterministic and reproducible.

### Phase 4: Verification

Checklist:

- [ ] Description is specific, third-person, includes trigger terms.
- [ ] SKILL.md body is under 500 lines.
- [ ] Workflow has explicit tool-call sequence and stop conditions.
- [ ] Tool usage limits are stated when applicable.
- [ ] Terminology is consistent throughout.
- [ ] No cross-step variable dependencies.
- [ ] Scripts expose only necessary parameters.
- [ ] Scripts return structured JSON to stdout.
- [ ] "When NOT to use" section is present.

## Minimal Template

```markdown
---
name: skill-name
description: Specific capability and trigger scenarios.
---

# Skill Name

## Goal
One clear objective.

## Hard Constraints
- Budget / safety / stop rules.

## Workflow
1. Step one
2. Step two
3. Stop when condition met

## Output Template
Required output structure.

## When NOT to use this skill
- Boundary cases.
```
