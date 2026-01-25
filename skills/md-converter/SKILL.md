---
name: md-converter
description: Convert normalized markdown to clean output, transforming MDX tags to standard markdown.
---

# Markdown Converter

## Overview

Converts normalized markdown documents to clean output format, transforming MDX-specific tags (`<Tip>`, `<Warning>`, `<Info>`, `<section>`) into standard markdown blockquotes.

## Usage

```bash
# list sources and their last normalized path
skills/md-converter/scripts/md_converter.rb list

# convert all sources in state.json
skills/md-converter/scripts/md_converter.rb convert --all

# convert a single source by id
skills/md-converter/scripts/md_converter.rb convert --id best-practices
```

## Options

- `list`: List sources and their normalized paths (from state.json)
- `convert --all`: Convert all sources in state.json
- `convert --id ID`: Convert a single source (repeatable)
- `convert --dry-run`: Do not write files

## Prerequisites

The following must be completed before running this script:

1. Source fetched via `doc-fetcher`
2. Source normalized via `md-normalizer`

## Inputs

- `data/doc-fetcher/state.json` - State file with source metadata
- Normalized markdown from `data/doc-fetcher/normalized/<source-id>/`

## Outputs

- `data/doc-fetcher/generated/<source-id>.en.md` - Converted markdown document

## Content Processing

- Converts `<Tip>` → `> **Tip:**`
- Converts `<Warning>` → `> **Warning:**`
- Converts `<Info>` → `> **Info:**`
- Converts `<section title="...">` → `**...**`
- Adds source metadata header (URL, snapshot, fetch date)
- Preserves code blocks unchanged
