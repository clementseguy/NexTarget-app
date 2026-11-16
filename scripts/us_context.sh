#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: bash scripts/us_context.sh NT-XXX" >&2
}

if [[ $# -ne 1 || ! $1 =~ ^NT-[0-9]{3}$ ]]; then
  usage
  exit 2
fi

US_ID=$1
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
BACKLOG="$REPO_ROOT/docs/backlog/backlog-unifie.md"
DESCRIPTIONS="$REPO_ROOT/docs/backlog/descriptions.md"
PRIORITIES="$REPO_ROOT/docs/backlog/priorites.md"

BACKLOG_LINE=$(grep -F "| [$US_ID](" "$BACKLOG" || true)
if [[ -z $BACKLOG_LINE ]]; then
  echo "$US_ID est absent du backlog actif." >&2
  exit 1
fi

PRIORITY_LINE=$(grep -F "[$US_ID](" "$PRIORITIES" || true)
DESCRIPTION=$(awk -v us_id="$US_ID" '
  index($0, "### " us_id " ") == 1 { printing = 1 }
  printing && printed && ($0 ~ /^<a id="NT-[0-9][0-9][0-9]"><\/a>$/ || $0 ~ /^## /) { exit }
  printing { print; printed = 1 }
' "$DESCRIPTIONS")

if [[ -z $DESCRIPTION ]]; then
  echo "Description introuvable pour $US_ID." >&2
  exit 1
fi

printf 'Backlog\n%s\n\n' "$BACKLOG_LINE"
if [[ -n $PRIORITY_LINE ]]; then
  printf 'Priorité\n%s\n\n' "$PRIORITY_LINE"
else
  printf 'Priorité\nNon priorisée\n\n'
fi
printf 'Description\n%s\n' "$DESCRIPTION"
