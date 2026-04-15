# TRD Template

Final TRD structure after shell concatenation.

```markdown
# {module_path} — Technical Requirements Document (TRD)

## 1. Project Overview

### 1.1 Project Summary
One concise sentence: what this module exposes and its key purpose. No impl-gap discussion, no scope rationale, no sibling-module discussion.

### 1.2 Tech Stack
| Layer | Technology | Version |
|-------|------------|---------|

### 1.3 Project Structure
Repo-rooted tree listing every in-scope file with line count and short note. Include every layer the module actually has; omit layers that do not exist.

```
{repo_root}/
├── {module_path}/
│   ├── {file}                            # {short note} ({N} lines)
│   └── ...
└── {impl_path}/
    └── {file}                            # {short note} ({N} lines)
```

### 1.4 Glossary
| Term | Definition |
|------|------------|
Domain-specific terminology required to understand the system.

---

## 2. Architecture

### 2.1 System Architecture
Mermaid architecture diagram showing major components and connections.

### 2.2 Module Breakdown
For each module: responsibility, key files, dependencies.

### 2.3 External Dependencies
Third-party services, libraries, upstream/downstream systems.

---

## 3. Data Model

### 3.1 Entity Definitions
All persistent tables/collections/structs with field-level detail. Include source file references.

### 3.2 Entity Relationships
Mermaid ER diagram.

### 3.3 Data Flow
How data enters, transforms, and exits the system.

---

## 4. Interface Design

### 4.1 External Interfaces
For each endpoint/RPC/message channel: method, path/topic, description, request/response types.

### 4.2 Internal Interfaces
Key exported functions, service interfaces, module boundary contracts.

### 4.3 External Integrations
Protocol, authentication, data format for each integration.

---

## 5. Core Logic

### 5.1 Primary Flows
End-to-end request flows with Mermaid sequence diagrams.

### 5.2 Core Algorithms
Document key business formulas, calculation logic, and decision algorithms. For each:
- **Name & Location**: Function/method name and file path
- **Purpose**: What it calculates or decides
- **Formula/Logic**: Mathematical formula (use LaTeX: `$formula$`) or pseudocode
- **Variables**: Explanation of each input parameter
- **Variants**: Different cases (e.g., by direction, mode, asset type)

### 5.3 Background Processes
Workers, cron jobs, event consumers, scheduled tasks.

### 5.4 State Transitions
Lifecycle state machines found in code.

---

## 6. Runtime Configuration

### 6.1 Configuration Items
All configuration keys with descriptions, types, default values, and valid ranges.

### 6.2 Deployment
Containerization, process model, resource requirements, startup sequence.

---

## 7. Observability

### 7.1 Logging
Log levels, formats, key log points, log rotation.

### 7.2 Monitoring & Alerting
Metrics exposed, alert conditions, notification channels.

### 7.3 Error Handling
Error types, retry patterns, fallback strategies, degradation behavior.

---

## 8. File Index

Split into subsections. Include a subsection only when the module has relevant content; omit the rest.

### 8.1 Files
| # | Category | File Path | Lines | Primary Content |

### 8.2 Functions
Per-layer tables. Columns: Function | Line | Description.

### 8.3 Data Models
| Model | Table / Store | File | Description |

### 8.4 Enums & Constants
| Constant | Value | Description |

### 8.5 Public Endpoints
| Endpoint | Method / Protocol | Auth | Description |

### 8.6 Cache / Storage Keys
| Key Pattern | Backend | TTL | Description |

### 8.7 External Dependencies
| Dependency | Type | Usage |
```

## Section Inclusion Rules

| Section | Include When | If Not Applicable |
|---------|--------------|-------------------|
| Project Overview | Always | — |
| Architecture | Always | — |
| Data Model | Always | Write "No persistent entities in this module" |
| Interface Design | Always | Write "No public interfaces in this module" |
| Core Logic | Always | Write "No multi-step flows in this module" |
| Core Algorithms | Always | Write "No business algorithms in this module" |
| Runtime Configuration | Always | Write "No configuration items in this module" |
| Observability | Always | Write "No logging/metrics in this module" |
| File Index | Always | — |

## Forbidden Elements

Do NOT include in TRD:
- Document generation time/date
- File path metadata sections
- "Document Info" or similar meta-sections
- Any content not derived from actual code
- Summarizations like "etc.", "...", "and more"
