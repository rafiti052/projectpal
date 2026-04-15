#!/bin/sh

set -eu

if [ "$#" -eq 0 ]; then
  set -- .
fi

stale_copy=$(
  rg -n -S --pcre2 \
    --glob '!scripts/projectpal-copy-audit.sh' \
    -e 'Critic' \
    -e 'Judge' \
    -e 'PRD' \
    -e 'Tech Spec' \
    -e 'Scope Framing' \
    -e 'critic-agent' \
    -e 'judge-agent' \
    -e 'prd-generate' \
    -e 'tech-spec-generate' \
    -e 'artifacts/prd' \
    -e 'artifacts/tech-spec' \
    -e 'artifacts/debate' \
    -e 'type: prd' \
    -e 'type: tech-spec' \
    -e 'type: debate(?!-)' \
    -e '\bcheckpoint\b' \
    -e '\bcheckpoints\b' \
    "$@" || true
)

stale_paths=$(
  rg --files "$@" | rg '(^|/)(critic-agent|judge-agent|prd-generate|tech-spec-generate)\.md$' || true
)

if [ -n "$stale_copy" ] || [ -n "$stale_paths" ]; then
  printf '%s\n' "projectpal-copy audit failed" >&2
  if [ -n "$stale_copy" ]; then
    printf '\n%s\n' "stale copy hits:" >&2
    printf '%s\n' "$stale_copy" >&2
  fi
  if [ -n "$stale_paths" ]; then
    printf '\n%s\n' "stale file names:" >&2
    printf '%s\n' "$stale_paths" >&2
  fi
  exit 1
fi

printf '%s\n' "projectpal-copy audit passed"
