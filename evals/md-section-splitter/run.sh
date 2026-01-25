#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
bundle exec cucumber "$ROOT/features/md_section_splitter_evals.feature"
