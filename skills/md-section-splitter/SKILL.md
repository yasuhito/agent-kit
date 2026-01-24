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
skills/md-section-splitter/scripts/anthropic_split_sections.rb --list

# split all enabled sources
skills/md-section-splitter/scripts/anthropic_split_sections.rb --all

# split a single source by id
skills/md-section-splitter/scripts/anthropic_split_sections.rb --id best-practices
```

## Inputs

- `data/anthropic/state.json` (last normalized path per source)
- Normalized Markdown under `data/anthropic/normalized/<id>/`
- Optional CLI flags: `--all`, `--id`, `--force`, `--dry-run`, `--list`

## Outputs

- Sections: `data/anthropic/sections/<id>/<snapshot_sha>/`
- Index: `data/anthropic/sections/<id>/<snapshot_sha>/index.json`
- State updates: `data/anthropic/state.json`

## Workflow

1. Ensure normalization has run (md-normalizer).
2. Run the splitter with `--all` or `--id`.
3. Confirm section files and `index.json` exist.

## Options

- `--force`: Overwrite existing section output.
- `--dry-run`: Do not write files.
- `--list`: Print sources and last normalized path.

## Notes

- H2 is treated as a section boundary; code fences are respected.
- A wrapper exists at `scripts/anthropic_split_sections.rb` for backward compatibility.
