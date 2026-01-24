---
name: md-normalizer
description: Normalize Markdown or HTML snapshots into canonical Markdown using skills/md-normalizer/scripts/anthropic_normalize.rb with optional pandoc fallback. Use when you need deterministic normalization before section splitting or extraction.
---

# MD Normalizer

## Overview

Normalize snapshot content (Markdown or HTML) into stable GitHub-flavored Markdown and write metadata/state updates.

## Quick Start

```bash
# list sources and their last snapshot path
skills/md-normalizer/scripts/anthropic_normalize.rb --list

# normalize all enabled sources
skills/md-normalizer/scripts/anthropic_normalize.rb --all

# normalize a single source by id
skills/md-normalizer/scripts/anthropic_normalize.rb --id best-practices
```

## Inputs

- `data/anthropic/state.json` (last snapshot path per source)
- Snapshot files under `data/anthropic/snapshots/<id>/`
- Optional CLI flags: `--all`, `--id`, `--force`, `--dry-run`, `--list`

## Outputs

- Normalized Markdown: `data/anthropic/normalized/<id>/<sha>.md`
- Normalization metadata: `data/anthropic/normalized/<id>/<sha>.json`
- State updates: `data/anthropic/state.json`

## Workflow

1. Ensure snapshots exist (run doc-fetcher first).
2. Run normalization with `--all` or `--id`.
3. Confirm normalized output and state updates.

## Options

- `--force`: Overwrite existing normalized output.
- `--dry-run`: Do not write files.
- `--list`: Print sources and last snapshot path.

## Notes

- Prefers `.md` snapshot passthrough; uses `pandoc` for HTML.
- A wrapper exists at `scripts/anthropic_normalize.rb` for backward compatibility.
