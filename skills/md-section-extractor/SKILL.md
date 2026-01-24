---
name: md-section-extractor
description: Extract specific sections from normalized Markdown into a focused output using skills/md-section-extractor/scripts/anthropic_generate_claude_md.rb. Use when you need deterministic extraction of the CLAUDE.md best-practices section from Anthropic docs.
---

# MD Section Extractor

## Overview

Extract the “Write an effective CLAUDE.md” section and a related failure-pattern snippet into a standalone Markdown file.

## Quick Start

```bash
skills/md-section-extractor/scripts/anthropic_generate_claude_md.rb
```

Custom output path:

```bash
skills/md-section-extractor/scripts/anthropic_generate_claude_md.rb --output data/anthropic/generated/claude-md.en.md
```

## Inputs

- `data/anthropic/state.json`
- Normalized Markdown referenced by `last_normalized_path` for source id `claude-code-best-practices`

## Outputs

- Default: `data/anthropic/generated/claude-md.en.md`

## Workflow

1. Ensure normalization has run (md-normalizer).
2. Run the extractor script.
3. Confirm output file is updated.

## Options

- `--output PATH`: override output path
- `--dry-run`: do not write files

## Notes

- This script is specific to the “Write an effective CLAUDE.md” section. For other sections, copy and adjust `SOURCE_ID` and `heading` logic.
- A wrapper exists at `scripts/anthropic_generate_claude_md.rb` for backward compatibility.
