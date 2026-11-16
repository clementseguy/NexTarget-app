#!/usr/bin/env bash
set -euo pipefail

MODE="full"
if [[ ${1-} == "fast" ]]; then
  MODE="fast"
fi

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; NC="\033[0m"

log() { echo -e "${YELLOW}[verify]${NC} $*"; }
ok() { echo -e "${GREEN}[ok]${NC} $*"; }
err() { echo -e "${RED}[fail]${NC} $*"; }

run_check() {
  local label=$1
  shift
  local output_file
  output_file=$(mktemp "${TMPDIR:-/tmp}/nextarget-verify.XXXXXX")

  log "$label..."
  if "$@" >"$output_file" 2>&1; then
    rm -f "$output_file"
    ok "$label passed"
    return 0
  fi

  err "$label failed"
  cat "$output_file"
  echo "Full output: $output_file" >&2
  return 1
}

run_check "Flutter analyze" flutter analyze

run_check "Hive schema" dart run tool/verify_hive_schema.dart

if [[ "$MODE" == "fast" ]]; then
  run_check "Tests ($MODE mode)" flutter test \
    test/services/rolling_stats_service_test.dart test/widget_test.dart
else
  run_check "Tests ($MODE mode)" flutter test
fi

log "Deprecation scan (withOpacity) ..."
WITH_OPACITY_COUNT=$(grep -R "withOpacity(" -n lib || true | wc -l | tr -d ' ')
if [[ "$WITH_OPACITY_COUNT" != "0" ]]; then
  log "Found $WITH_OPACITY_COUNT usages of deprecated withOpacity (consider replacing)."
fi

ok "All pre-commit checks succeeded."
