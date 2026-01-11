#!/usr/bin/env bash
set -euo pipefail

# Render template using envsubst
# Usage: ./render_template.sh <template_file> <output_file> [VAR=value ...]
# Example: ./render_template.sh template.tmpl output.txt INPUT_TEXT="Hello"

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <template_file> <output_file> [VAR=value ...]" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 template.tmpl output.txt INPUT_TEXT=\"Hello World\"" >&2
  exit 1
fi

TEMPLATE_FILE="$1"
OUTPUT_FILE="$2"
shift 2

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: template file not found: $TEMPLATE_FILE" >&2
  exit 1
fi

# Export all VAR=value arguments as environment variables
for arg in "$@"; do
  export "$arg"
done

# Render template using envsubst
envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"
