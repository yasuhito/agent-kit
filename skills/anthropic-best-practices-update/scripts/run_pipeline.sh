#!/usr/bin/env bash
set -euo pipefail

SKIP_TRANSLATE=0
SOURCE_ID=""
INSECURE=0

SESSION_PREFIX="abp-translate"

usage() {
  cat <<'USAGE'
Usage: run_pipeline.sh [--id SOURCE_ID] [--skip-translate] [--insecure]

Runs the Anthropic Best Practices pipeline in order:
  fetch -> normalize -> split -> convert -> translate

Options:
  --id SOURCE_ID    Process a specific source (default: all enabled sources)
  --skip-translate  Skip the GPT-5 translation step.
  --insecure        Skip SSL certificate verification during fetch.
  -h, --help        Show this help.

Examples:
  run_pipeline.sh --id claude-code-best-practices
  run_pipeline.sh --id claude-prompt-best-practices --skip-translate --insecure
  run_pipeline.sh
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      SOURCE_ID="$2"
      shift 2
      ;;
    --skip-translate)
      SKIP_TRANSLATE=1
      shift
      ;;
    --insecure)
      INSECURE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

find_root() {
  local dir="$1"
  local i
  for i in $(seq 1 8); do
    if [ -d "$dir/data/anthropic" ]; then
      echo "$dir"
      return 0
    fi
    local parent
    parent="$(cd "$dir/.." && pwd)"
    if [ "$parent" = "$dir" ]; then
      break
    fi
    dir="$parent"
  done
  echo "$(cd "$1/../../.." && pwd)"
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(find_root "$SCRIPT_DIR")"

run() {
  "$ROOT/$@"
}

# Determine source selector
if [ -n "$SOURCE_ID" ]; then
  SOURCE_SELECTOR="--id $SOURCE_ID"
else
  SOURCE_SELECTOR="--all"
fi

# Determine insecure flag
INSECURE_FLAG=""
if [ "$INSECURE" -eq 1 ]; then
  INSECURE_FLAG="--insecure"
fi

echo "=== Fetching sources ==="
run skills/doc-fetcher/scripts/doc_fetcher.rb $SOURCE_SELECTOR $INSECURE_FLAG

echo "=== Normalizing sources ==="
run skills/md-normalizer/scripts/anthropic_normalize.rb $SOURCE_SELECTOR

echo "=== Splitting sections ==="
run skills/md-section-splitter/scripts/anthropic_split_sections.rb $SOURCE_SELECTOR

echo "=== Converting to markdown ==="
run skills/md-converter/scripts/anthropic_convert.rb $SOURCE_SELECTOR

if [ "$SKIP_TRANSLATE" -eq 1 ]; then
  echo "Translation skipped."
  exit 0
fi

# Determine source ids for translation
if [ -n "$SOURCE_ID" ]; then
  IDS=("$SOURCE_ID")
else
  mapfile -t IDS < <(ruby -ryaml -e 'data = YAML.safe_load_file("data/anthropic/sources.yaml"); list = data.is_a?(Hash) ? data["sources"] : data; list ||= []; list.each { |s| puts s["id"] if s["enabled"] != false }')
fi

echo "=== Translating to Japanese ==="
if [ -n "${OPENAI_API_KEY:-}" ]; then
  echo "OPENAI_API_KEY detected in environment."
  # If API key is provided via env, run directly without tmux/op.
  for id in "${IDS[@]}"; do
    INPUT_FILE="${ROOT}/data/anthropic/generated/${id}.en.md"
    OUTPUT_FILE="${ROOT}/docs/best-practices/${id}.md"
    META_FILE="${ROOT}/data/anthropic/generated/${id}.meta.json"
    run skills/md-translator/scripts/openai_translate_markdown.rb \
      --input "$INPUT_FILE" \
      --output "$OUTPUT_FILE" \
      --meta "$META_FILE" \
      $INSECURE_FLAG
  done
  exit 0
fi

# No API key in env: require op (tmux guard).
echo "OPENAI_API_KEY not set; falling back to op."
if [ -n "${TMUX:-}" ]; then
  for id in "${IDS[@]}"; do
    INPUT_FILE="${ROOT}/data/anthropic/generated/${id}.en.md"
    OUTPUT_FILE="${ROOT}/docs/best-practices/${id}.md"
    META_FILE="${ROOT}/data/anthropic/generated/${id}.meta.json"
    run skills/md-translator/scripts/openai_translate_markdown.rb \
      --use-1password \
      --input "$INPUT_FILE" \
      --output "$OUTPUT_FILE" \
      --meta "$META_FILE" \
      $INSECURE_FLAG
  done
  exit 0
fi

SESSION_NAME="${SESSION_PREFIX}-$$"
WAIT_NAME="${SESSION_PREFIX}-wait-$$"
STATUS_FILE="$(mktemp /tmp/abp-translate-status.XXXXXX)"
IDS_FILE="$(mktemp /tmp/abp-translate-ids.XXXXXX)"
printf "%s\n" "${IDS[@]}" > "${IDS_FILE}"

echo "TMUX not detected. Running translation in temporary tmux session: ${SESSION_NAME}"
echo "If it hangs (1Password sign-in), attach with: tmux attach -t ${SESSION_NAME}"

tmux new-session -d -s "${SESSION_NAME}" "cd \"${ROOT}\" && while IFS= read -r id; do INPUT_FILE=\"${ROOT}/data/anthropic/generated/\\${id}.en.md\"; OUTPUT_FILE=\"${ROOT}/docs/best-practices/\\${id}.md\"; META_FILE=\"${ROOT}/data/anthropic/generated/\\${id}.meta.json\"; skills/md-translator/scripts/openai_translate_markdown.rb --use-1password --input \"\\${INPUT_FILE}\" --output \"\\${OUTPUT_FILE}\" --meta \"\\${META_FILE}\" ${INSECURE_FLAG} || exit 1; done < \"${IDS_FILE}\"; echo \$? > \"${STATUS_FILE}\"; rm -f \"${IDS_FILE}\"; tmux wait-for -S \"${WAIT_NAME}\""
tmux wait-for "${WAIT_NAME}"

TRANSLATE_STATUS="1"
if [ -f "${STATUS_FILE}" ]; then
  TRANSLATE_STATUS="$(cat "${STATUS_FILE}")"
  rm -f "${STATUS_FILE}"
fi

tmux kill-session -t "${SESSION_NAME}" >/dev/null 2>&1 || true

if [ "${TRANSLATE_STATUS}" -ne 0 ]; then
  echo "Translation failed with status ${TRANSLATE_STATUS}" >&2
  exit "${TRANSLATE_STATUS}"
fi
