#!/bin/sh
# Validate the host adapter contract: allowed inputs, allowed outputs, and generated files.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)

usage() {
  cat <<'EOF'
usage:
  sh scripts/validate-platform.sh [all|claude|codex|cursor ...]
EOF
}

normalize_hosts() {
  if [ "$#" -eq 0 ]; then
    printf '%s\n' claude codex cursor
    return
  fi

  for host in "$@"; do
    case "$host" in
      all)
        printf '%s\n' claude codex cursor
        return
        ;;
      claude|codex|cursor)
        printf '%s\n' "$host"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        printf '%s\n' "validate-platform: unknown host '$host'" >&2
        exit 1
        ;;
    esac
  done
}

contains_line() {
  needle=$1
  haystack=$2

  printf '%s\n' "$haystack" | grep -Fx -- "$needle" >/dev/null 2>&1
}

validate_host() {
  host=$1
  manifest="$ROOT_DIR/platforms/$host/manifest.sh"

  if [ ! -f "$manifest" ]; then
    printf '%s\n' "validate-platform: missing manifest for $host" >&2
    exit 1
  fi

  PLATFORM_NAME=''
  PLATFORM_INPUTS=''
  PLATFORM_OUTPUTS=''
  # shellcheck source=/dev/null
  . "$manifest"

  if [ "$PLATFORM_NAME" != "$host" ]; then
    printf '%s\n' "validate-platform: manifest name mismatch for $host" >&2
    exit 1
  fi

  for input in $PLATFORM_INPUTS; do
    case "$input" in
      src/*|platforms/"$host"/*)
        ;;
      *)
        printf '%s\n' "validate-platform: disallowed input for $host: $input" >&2
        exit 1
        ;;
    esac

    if [ ! -f "$ROOT_DIR/$input" ]; then
      printf '%s\n' "validate-platform: missing input for $host: $input" >&2
      exit 1
    fi
  done

  for output in $PLATFORM_OUTPUTS; do
    case "$output" in
      build/"$host"/*)
        ;;
      *)
        printf '%s\n' "validate-platform: disallowed output for $host: $output" >&2
        exit 1
        ;;
    esac
  done

  sh "$ROOT_DIR/scripts/build-platform.sh" "$host" >/dev/null

  for output in $PLATFORM_OUTPUTS; do
    if [ ! -f "$ROOT_DIR/$output" ]; then
      printf '%s\n' "validate-platform: missing generated output for $host: $output" >&2
      exit 1
    fi
  done

  find "$ROOT_DIR/build/$host" -type f | while IFS= read -r file_path; do
    rel_path=${file_path#"$ROOT_DIR/"}
    if ! contains_line "$rel_path" "$PLATFORM_OUTPUTS"; then
      printf '%s\n' "validate-platform: undeclared build output for $host: $rel_path" >&2
      exit 1
    fi
  done

  printf '%s\n' "validated $host"
}

for host in $(normalize_hosts "$@"); do
  validate_host "$host"
done
