# Kratos Project with Shared APIs Submodule

Kratos-based Go microservices often use a shared `apis/` git submodule containing proto definitions for multiple services. This example shows how to scope TRD analysis to **only the current project's protos**, avoiding analysis of unrelated public protos.

## Problem

A typical structure:

```
project/
├── apis/                          # git submodule (shared proto repo)
│   ├── wallet/                    # ← belongs to THIS project
│   │   ├── withdraw/v1/withdraw.proto
│   │   ├── deposit/v1/deposit.proto
│   │   └── address/v1/address.proto
│   ├── contract/                  # ← belongs to another project
│   ├── otc/                       # ← belongs to another project
│   ├── spot/                      # ← belongs to another project
│   └── ... (200+ proto files)
├── internal/
│   ├── service/                   # gRPC service implementations
│   ├── biz/
│   ├── data/
│   └── conf/conf.proto
├── cmd/
└── configs/
```

The `apis/` submodule contains 200+ proto files, but only a subset belongs to this project.

## Solution: Identify Project Protos from Service Layer

The service layer **directly reveals** which protos belong to the current project:

```go
// internal/service/withdraw.go
package service

import (
    withdrawPb "apis/wallet/withdraw/v1"      // ← project proto
    depositPb "apis/wallet/deposit/v1"        // ← project proto
    walletError "apis/wallet/common/error/v1" // ← project proto
    commonError "apis/common/error/v1"        // ← shared dependency
)

type WithdrawService struct {
    withdrawPb.UnimplementedWithdrawServer    // ← implements this proto service
}
```

## Proto Scope Rules

| Proto Namespace | Ownership | Analysis |
|-----------------|-----------|----------|
| `apis/{project}/*` | Project-owned | Full analysis |
| `apis/common/*` | Shared dependency | Document as external dependency |
| Other `apis/*` | Unrelated | Skip entirely |

## Key Patterns in Kratos Projects

| Pattern | Location | What to Document |
|---------|----------|------------------|
| Service registration | `internal/service/service.go` | Wire providers, HTTP/gRPC registration |
| Proto imports | `internal/service/*.go` imports | Identifies project proto scope |
| Biz interfaces | `internal/biz/*.go` | UseCase interfaces and implementations |
| Data repos | `internal/data/*.go` | Repository pattern, DB access |
| Config proto | `internal/conf/conf.proto` | Runtime configuration structure |
| Wire DI | `cmd/*/wire.go` | Dependency injection graph |

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Analyzing all 200+ protos in apis/ | Scope to project namespace from service imports |
| Missing shared error types | Document `apis/common/error/*` as external dependency |
| Ignoring rate limit configs | Include in Interface section |
| Missing Wire DI analysis | Include in Architecture section |
