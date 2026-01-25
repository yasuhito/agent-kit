#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
EVAL_DIR="$ROOT/evals/doc-fetcher"
RUNS_DIR="$EVAL_DIR/runs"
PROMPTS_FILE="$EVAL_DIR/prompts.tsv"

mkdir -p "$RUNS_DIR"

while IFS=$'\t' read -r id prompt should_trigger; do
  if [[ "$id" == "id" || -z "$id" ]]; then
    continue
  fi

  out="$RUNS_DIR/$id.jsonl"
  echo "==> $id"
  codex exec --json --full-auto "$prompt" | tee "$out"
done < "$PROMPTS_FILE"
