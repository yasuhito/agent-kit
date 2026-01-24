---
name: doc-fetcher
description: Deterministically fetch documentation sources listed in data/anthropic/sources.yaml using skills/doc-fetcher/scripts/anthropic_fetch.rb, storing snapshots and state. Use when you need repeatable HTTP fetching with conditional headers and local snapshotting.
---

# Doc Fetcher

## Overview

Fetch documentation sources from a YAML list and store immutable snapshots plus fetch state. Uses conditional requests (ETag/If-Modified-Since) for deterministic change tracking.

## Quick Start

```bash
# list enabled sources
skills/doc-fetcher/scripts/anthropic_fetch.rb --list

# fetch all enabled sources
skills/doc-fetcher/scripts/anthropic_fetch.rb --all

# fetch a single source by id
skills/doc-fetcher/scripts/anthropic_fetch.rb --id best-practices
```

## Inputs

- `data/anthropic/sources.yaml` (source list)
- Optional CLI flags: `--all`, `--id`, `--force`, `--dry-run`, `--list`

Example `sources.yaml`:

```yaml
sources:
  - id: best-practices
    url: https://code.claude.com/docs/en/best-practices.md
    enabled: true
```

## Outputs

- Snapshots: `data/anthropic/snapshots/<id>/<sha256>.md|.html`
- Snapshot metadata: `data/anthropic/snapshots/<id>/<sha256>.json`
- State file: `data/anthropic/state.json`

## Workflow

1. Update `data/anthropic/sources.yaml` with `id` + `url`.
2. Run `skills/doc-fetcher/scripts/anthropic_fetch.rb --all` (or `--id`).
3. Confirm new snapshots and `state.json` updates.

## Options

- `--force`: Skip conditional headers and always download.
- `--dry-run`: Do not write files.
- `--list`: Print enabled sources.

## Notes

- Prefer `.md` endpoints when available to avoid HTML normalization.
- The data root is fixed to `data/anthropic/`. For other pipelines, copy the script and update `DATA_DIR` and `SOURCES_FILE`.
- A wrapper exists at `scripts/anthropic_fetch.rb` for backward compatibility.
