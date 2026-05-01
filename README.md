# File Browser — Custom Fork

> A customized deployment of [filebrowser/filebrowser](https://github.com/filebrowser/filebrowser) (📂 Web File Browser).

[![CI](https://github.com/asrarulHuq/asrarulHuq.github.io/actions/workflows/ci.yaml/badge.svg)](https://github.com/asrarulHuq/asrarulHuq.github.io/actions/workflows/ci.yaml)

## About

This repository is a maintained fork of the upstream **filebrowser** project (v2.63.2), customized for personal use. All automation (CI, PR handling, upstream syncing, merging) is managed entirely through GitHub Actions — no manual intervention is required. Feedback drives the roadmap.

## Upstream

| | |
|---|---|
| **Source** | [filebrowser/filebrowser](https://github.com/filebrowser/filebrowser) |
| **Synced tag** | `v2.63.2` |
| **Sync schedule** | Every Monday (automated PR opened when a new upstream release is available) |

## Customizations

See [`CUSTOMIZATIONS.md`](./CUSTOMIZATIONS.md) for the full change log.

## Automation

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yaml` | push / PR | Build, lint, and test |
| `auto-merge.yaml` | PR labeled `auto-merge` | Squash-merges the PR automatically once CI passes |
| `upstream-sync.yaml` | Every Monday / manual dispatch | Detects new upstream releases and opens a sync PR |
| `pr-lint.yaml` | PR opened/edited | Validates PR title follows Conventional Commits |

## Development

```bash
# Requirements: Go ≥ 1.25, Node.js ≥ 22, pnpm

# Build everything (backend + frontend)
task build

# Run backend tests
go test ./...

# Run frontend in dev mode
cd frontend && pnpm dev
```

## License

[Apache 2.0](./LICENSE) — same as upstream.
