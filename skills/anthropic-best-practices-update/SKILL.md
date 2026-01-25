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
4. Convert normalized markdown (md-converter).
5. Translate to Japanese (md-translator).

## Inputs

- `data/anthropic/state.json`
- The pipeline uses a built-in list of Anthropic best-practices URLs in
  `skills/anthropic-best-practices-update/scripts/run_pipeline.sh`.
  Source ids are derived from URLs.

## Outputs

- `data/anthropic/snapshots/`
- `data/anthropic/normalized/`
- `data/anthropic/sections/`
- `data/anthropic/generated/claude-md.en.md`
- `docs/best-practices/<source-id>.md`

## Options

- `--skip-translate`: run everything except GPT-5 translation.
- `--id <source-id>`: run a single source from the built-in list (id is URL-derived).

## Notes

- `OPENAI_API_KEY` が env にある場合は **tmux なしで直接翻訳**する。
- env が無い場合は tmux + 1Password (`op`) を使う。
- tmux 翻訳が止まったら、出力されたセッションに attach する。
