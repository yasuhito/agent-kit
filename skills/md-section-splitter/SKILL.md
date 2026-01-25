---
name: md-section-splitter
description: Split normalized Markdown into H2 sections using skills/md-section-splitter/scripts/anthropic_split_sections.rb, producing per-section files and index metadata. Use when you need deterministic sectionization for extraction or review.
---

# MD Section Splitter

## Overview

Split normalized Markdown into H2 sections while preserving code fences and output an index for downstream processing.

## Quick Start

```bash
# list sources and their last normalized path
skills/md-section-splitter/scripts/anthropic_split_sections.rb list

# split all sources in state.json
skills/md-section-splitter/scripts/anthropic_split_sections.rb split --all

# split a single source by id
skills/md-section-splitter/scripts/anthropic_split_sections.rb split --id best-practices
```

## Inputs

- `data/doc-fetcher/state.json` (last normalized path per source)
- Normalized Markdown under `data/doc-fetcher/normalized/<id>/`
- Subcommands: `list`, `split`
- Optional flags for `split`: `--all`, `--id`, `--force`, `--dry-run`

## Outputs

- Sections: `data/doc-fetcher/sections/<id>/<snapshot_sha>/`
- Index: `data/doc-fetcher/sections/<id>/<snapshot_sha>/index.json`
- State updates: `data/doc-fetcher/state.json`

## Workflow

1. Ensure normalization has run (md-normalizer).
2. Run the splitter with `split --all` or `split --id`.
3. Confirm section files and `index.json` exist.

## Options

- `list`: Print sources and last normalized path (from state.json).
- `split --force`: Overwrite existing section output.
- `split --dry-run`: Do not write files.

## Notes

- H2 is treated as a section boundary; code fences are respected.
- A wrapper exists at `scripts/anthropic_split_sections.rb` for backward compatibility.
