---
name: doc-fetcher
description: Deterministically fetch documentation from one or more URLs using skills/doc-fetcher/scripts/doc_fetcher.rb, storing snapshots and state. Use when you need repeatable HTTP fetching with conditional headers and local snapshotting.
---

# Doc Fetcher

## Overview

Fetch documentation from URLs and store immutable snapshots plus fetch state. Uses conditional requests (ETag/If-Modified-Since) for deterministic change tracking.

## CLI Shape

- Subcommand-based: `list` or `fetch` only.
- If unsure, run `skills/doc-fetcher/scripts/doc_fetcher.rb --help` first.
- Always invoke `skills/doc-fetcher/scripts/doc_fetcher.rb` (there is no `doc-fetcher` binary in PATH).

## Intent → Command

- "登録済み/追跡中の URL 一覧がほしい" -> `list`
- "この URL を取得してほしい" -> `fetch --url <url>`
- URL が無い場合は質問してから `fetch`
- 書き込み不要と言われたら `fetch --dry-run`

## Quick Start

```bash
# list tracked sources from state
skills/doc-fetcher/scripts/doc_fetcher.rb list

# fetch a single URL
skills/doc-fetcher/scripts/doc_fetcher.rb fetch --url https://code.claude.com/docs/en/best-practices.md

# fetch a URL (id is derived from the URL)
skills/doc-fetcher/scripts/doc_fetcher.rb fetch --url https://example.com/docs.md
```

## Inputs

- `list` subcommand (optional `--url`)
- `fetch` subcommand requires `--url` (repeatable)
- Optional flags for `fetch`: `--force`, `--dry-run`, `--insecure`

## Outputs

- Snapshots: `data/doc-fetcher/snapshots/<id>/<sha256>.md|.html`
- Snapshot metadata: `data/doc-fetcher/snapshots/<id>/<sha256>.json`
- State file: `data/doc-fetcher/state.json`

## Workflow

1. Decide the URL(s) to fetch.
2. Run `skills/doc-fetcher/scripts/doc_fetcher.rb fetch --url <url>` (repeat for multiple URLs).
3. Confirm new snapshots and `state.json` updates.

## Options

- `list`: Print sources tracked in `data/doc-fetcher/state.json` (or provided URLs via `--url`).
- `fetch`: Download snapshots for provided URLs.
- `fetch --force`: Skip conditional headers and always download.
- `fetch --dry-run`: Do not write files.
- `fetch --insecure`: Skip SSL certificate verification.

## Notes

- Prefer `.md` endpoints when available to avoid HTML normalization.
- IDs are derived from URLs. Use `list --url <url>` to preview the generated id.
- The data root is fixed to `data/doc-fetcher/`. For other pipelines, copy the script and update `DATA_DIR`.
