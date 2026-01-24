---
name: md-translator
description: Translate Markdown to Japanese using OpenAI GPT-5 while preserving Markdown structure, code blocks, and URLs. Use when asked to translate .md files (docs or generated outputs) or to produce Japanese versions via skills/md-translator/scripts/openai_translate_markdown.rb with 1Password + tmux.
---

# Markdown Translator (JA)

## Overview

Translate Markdown to Japanese using `skills/md-translator/scripts/openai_translate_markdown.rb` (OpenAI Responses API). Preserve Markdown structure and code blocks, and avoid adding commentary.

## Quick Start

Use tmux and 1Password to set the API key, then run:

```bash
skills/md-translator/scripts/openai_translate_markdown.rb --use-1password --input path/to/input.md --output path/to/output.md
```

Defaults (no flags):

```bash
skills/md-translator/scripts/openai_translate_markdown.rb --use-1password
```

## Workflow

1. Identify input and output paths. Use defaults if translating the Anthropic pipeline output.
2. Run the translation script from the repo root.
3. Verify the output file exists and Markdown structure is intact (headings, lists, tables, blockquotes, code blocks).

## Options

- `--model MODEL` (default: `gpt-5`)
- `--temperature N` (only if the model supports it)
- `--meta PATH` (write metadata JSON)
- `--dry-run` (no file writes)
- `--insecure` (skip SSL certificate verification)
- `--open-timeout SECONDS` (HTTP open timeout)
- `--read-timeout SECONDS` (HTTP read timeout)

## Constraints

- `--use-1password` reads `OPENAI_API_KEY` via `op read op://Personal/OpenAI API Key/credential`.
- The script refuses to call `op` outside tmux.
- Code blocks and inline code are masked; URLs are kept unchanged.
- A wrapper exists at `scripts/openai_translate_markdown.rb` for backward compatibility.
