---
name: anthropic-best-practices-update
description: Run the full Anthropic Best Practices pipeline in order (fetch, normalize, split, extract, translate) using existing skills. Use when asked to update docs/best-practices/claude-md.md in one shot.
---

# Anthropic Best Practices Update

## Overview

Execute the end-to-end Anthropic Best Practices update workflow in a deterministic order. Includes translation to Japanese via GPT-5.

## Quick Start

If not already in tmux, the script will create a temporary tmux session for translation:

```bash
skills/anthropic-best-practices-update/scripts/run_pipeline.sh
```

Skip translation:

```bash
skills/anthropic-best-practices-update/scripts/run_pipeline.sh --skip-translate
```

## Workflow

1. Fetch sources (doc-fetcher).
2. Normalize snapshots (md-normalizer).
3. Split into sections (md-section-splitter).
4. Extract CLAUDE.md section (md-section-extractor).
5. Translate to Japanese (md-translator).

## Inputs

- `data/anthropic/sources.yaml`
- `data/anthropic/state.json`

## Outputs

- `data/anthropic/snapshots/`
- `data/anthropic/normalized/`
- `data/anthropic/sections/`
- `data/anthropic/generated/claude-md.en.md`
- `docs/best-practices/claude-md.md`

## Options

- `--skip-translate`: run everything except GPT-5 translation.

## Notes

- Translation uses tmux + 1Password (`op`) to read `OPENAI_API_KEY`.
- If translation stalls, attach to the temporary session printed by the script.
