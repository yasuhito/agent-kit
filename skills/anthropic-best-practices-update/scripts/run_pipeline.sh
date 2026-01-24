#!/usr/bin/env bash
set -euo pipefail

SKIP_TRANSLATE=0

SESSION_PREFIX="abp-translate"

usage() {
  cat <<'USAGE'
Usage: run_pipeline.sh [--skip-translate]

Runs the Anthropic Best Practices pipeline in order:
  fetch -> normalize -> split -> extract -> translate

Options:
  --skip-translate  Skip the GPT-5 translation step.
  -h, --help        Show this help.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --skip-translate)
      SKIP_TRANSLATE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
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

run skills/doc-fetcher/scripts/anthropic_fetch.rb --all
run skills/md-normalizer/scripts/anthropic_normalize.rb --all
run skills/md-section-splitter/scripts/anthropic_split_sections.rb --all
run skills/md-section-extractor/scripts/anthropic_generate_claude_md.rb

if [ "$SKIP_TRANSLATE" -eq 1 ]; then
  echo "Translation skipped."
  exit 0
fi

if [ -n "${TMUX:-}" ]; then
  run skills/md-translator/scripts/openai_translate_markdown.rb --use-1password
  exit 0
fi

SESSION_NAME="${SESSION_PREFIX}-$$"
WAIT_NAME="${SESSION_PREFIX}-wait-$$"
STATUS_FILE="$(mktemp /tmp/abp-translate-status.XXXXXX)"

echo "TMUX not detected. Running translation in temporary tmux session: ${SESSION_NAME}"
echo "If it hangs (1Password sign-in), attach with: tmux attach -t ${SESSION_NAME}"

tmux new-session -d -s "${SESSION_NAME}" "cd \"${ROOT}\" && skills/md-translator/scripts/openai_translate_markdown.rb --use-1password; echo \$? > \"${STATUS_FILE}\"; tmux wait-for -S \"${WAIT_NAME}\""
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
