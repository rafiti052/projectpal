#!/bin/sh

set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf '%s\n' "usage: sh scripts/markdown-word-budget.sh <markdown-path> [budget-limit]" >&2
  exit 1
fi

MARKDOWN_PATH=$1
BUDGET_LIMIT=${2:-1000}

if [ ! -f "$MARKDOWN_PATH" ]; then
  printf '%s\n' "markdown-word-budget: file not found: $MARKDOWN_PATH" >&2
  exit 1
fi

WORD_COUNT=$(
  awk '
    BEGIN {
      in_frontmatter = 0
      frontmatter_checked = 0
      count = 0
    }
    NR == 1 {
      frontmatter_checked = 1
      if ($0 == "---") {
        in_frontmatter = 1
        next
      }
    }
    in_frontmatter && $0 == "---" {
      in_frontmatter = 0
      next
    }
    !in_frontmatter {
      for (i = 1; i <= NF; i++) {
        count++
      }
    }
    END {
      print count
    }
  ' "$MARKDOWN_PATH"
)

WITHIN_BUDGET=false
if [ "$WORD_COUNT" -le "$BUDGET_LIMIT" ]; then
  WITHIN_BUDGET=true
fi

cat <<EOF
word_count: $WORD_COUNT
budget_limit: $BUDGET_LIMIT
within_budget: $WITHIN_BUDGET
EOF
