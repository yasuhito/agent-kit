---
name: md-converter
description: Convert normalized markdown to clean output, transforming MDX tags to standard markdown.
---

# Markdown Converter

## Overview

Converts normalized markdown documents to clean output format, transforming MDX-specific tags (`<Tip>`, `<Warning>`, `<Info>`, `<section>`) into standard markdown blockquotes.

## Usage

```bash
ruby skills/md-converter/scripts/anthropic_convert.rb [options]
```

## Options

- `--all`: Convert all sources in state.json
- `--id ID`: Convert a single source (repeatable)
- `--dry-run`: Do not write files
- `--list`: List sources and their normalized paths (from state.json)

## Prerequisites

The following must be completed before running this script:

1. Source fetched via `doc-fetcher`
2. Source normalized via `md-normalizer`

## Inputs

- `data/anthropic/state.json` - State file with source metadata
- Normalized markdown from `data/anthropic/normalized/<source-id>/`

## Outputs

- `data/anthropic/generated/<source-id>.en.md` - Converted markdown document

## Content Processing

- Converts `<Tip>` → `> **Tip:**`
- Converts `<Warning>` → `> **Warning:**`
- Converts `<Info>` → `> **Info:**`
- Converts `<section title="...">` → `**...**`
- Adds source metadata header (URL, snapshot, fetch date)
- Preserves code blocks unchanged
