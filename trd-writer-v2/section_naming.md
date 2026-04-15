# Section File Naming Convention

**All Workers, Coordinator, and scripts MUST use these exact file names.**

## Fixed Section Files

| Section | File Name | Content |
|---------|-----------|---------|
| 1 | `section_1_overview.md` | Project Overview (1.1-1.4) |
| 2 | `section_2_architecture.md` | Architecture (2.1-2.3) |
| 3 | `section_3_data_model.md` | Data Model (3.1-3.3) |
| 4 | `section_4_interface.md` | Interface Design (4.1-4.3) |
| 8 | `section_8_file_index.md` | File Index |

## Multi-Part Sections

For sections split across multiple Workers, Coordinator assigns exact file names:

| Section | Pattern | Examples |
|---------|---------|----------|
| 5 Core Logic | `section_5_{N}_core_logic.md` | N=1,2,3,4... |
| 6 Data Access | `section_6_{N}_data_access.md` | N=1,2,3,4... |
| 7 Observability | `section_7_1_observability.md` | Single file |

## Naming Rules

1. **Prefix**: Always `section_`
2. **Section number**: Single digit (1-8)
3. **Part number** (for multi-part): `_{N}_` where N is 1, 2, 3...
4. **Suffix**: Descriptive name in lowercase with underscores
5. **Extension**: `.md`

## Concatenation Order

The `concat_trd.sh` script concatenates in this order:

```
section_1_overview.md
section_2_architecture.md
section_3_data_model.md
section_4_interface.md
section_5_*.md (sorted alphabetically)
section_6_*.md (sorted alphabetically)
section_7_*.md (sorted alphabetically)
section_8_file_index.md
```

## Worker Assignment Example

Coordinator assigns Workers with explicit output file names based on module size:

| Worker | Output Files |
|--------|--------------|
| Worker 1 | `section_1_overview.md`, `section_2_architecture.md` |
| Worker 2 | `section_3_data_model.md` |
| Worker 3 | `section_4_interface.md` |
| Worker 4 | `section_5_1_core_logic.md` |
| Worker 5 | `section_5_2_core_logic.md` |
| Worker 6 | `section_6_1_data_access.md` |
| Worker 7 | `section_7_1_observability.md`, `section_8_file_index.md` |

**Coordinator decides Worker count and part count based on source file count.**

## Validation

Before concatenation, verify all expected files exist:

```bash
ls section_1_overview.md
ls section_2_architecture.md
ls section_3_data_model.md
ls section_4_interface.md
ls section_5_*.md
ls section_8_file_index.md
```
