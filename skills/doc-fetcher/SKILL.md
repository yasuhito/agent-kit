---
name: doc-fetcher
description: Deterministically fetch documentation from one or more URLs using skills/doc-fetcher/scripts/doc_fetcher.rb, storing snapshots and state. Use when you need repeatable HTTP fetching with conditional headers and local snapshotting.
---

# Doc Fetcher

## Overview

Fetch documentation from URLs and store immutable snapshots plus fetch state. Uses conditional requests (ETag/If-Modified-Since) for deterministic change tracking.

## Quick Start

```bash
# list tracked sources from state
skills/doc-fetcher/scripts/doc_fetcher.rb --list

# fetch a single URL
skills/doc-fetcher/scripts/doc_fetcher.rb --url https://code.claude.com/docs/en/best-practices.md

# fetch with an explicit id (repeatable --url / --id)
skills/doc-fetcher/scripts/doc_fetcher.rb --url https://example.com/docs.md --id example-docs
```

## Inputs

- URLs passed via `--url` (repeatable, required unless using `--list`)
- Optional CLI flags: `--id`, `--force`, `--dry-run`, `--list`

## Outputs

- Snapshots: `data/anthropic/snapshots/<id>/<sha256>.md|.html`
- Snapshot metadata: `data/anthropic/snapshots/<id>/<sha256>.json`
- State file: `data/anthropic/state.json`

## Workflow

1. Decide the URL(s) to fetch.
2. Run `skills/doc-fetcher/scripts/doc_fetcher.rb --url <url>` (repeat for multiple URLs).
3. Confirm new snapshots and `state.json` updates.

## Options

- `--force`: Skip conditional headers and always download.
- `--dry-run`: Do not write files.
- `--list`: Print sources tracked in `data/anthropic/state.json` (or provided URLs).
- `--id`: Explicit id for the corresponding `--url` (repeatable, order matters).

## Notes

- Prefer `.md` endpoints when available to avoid HTML normalization.
- The data root is fixed to `data/anthropic/`. For other pipelines, copy the script and update `DATA_DIR`.
