#!/usr/bin/env bash
set -euo pipefail

# Clean Ollama output - remove ANSI codes and markdown code blocks
# Usage: ./clean_ollama_output.sh <input_file> <output_file>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_file> <output_file>" >&2
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: input file not found: $INPUT_FILE" >&2
  exit 1
fi

# Strategy: 
# 1. Remove all ANSI escape sequences and control characters
# 2. Extract content from first { to matching }
# 3. Remove markdown code fences

# First, strip ANSI codes and control chars, keep only printable + newlines
perl -pe 's/\x1b\[[0-9;?]*[a-zA-Z]//g; s/\x1b\[?[0-9]*[hl]//g; tr/\000-\010\013\014\016-\037//d' \
  "$INPUT_FILE" | \
  grep -v '```' | \
  awk '
    BEGIN { depth=0; printing=0; }
    {
      for (i=1; i<=length($0); i++) {
        c = substr($0, i, 1);
        if (c == "{") {
          if (depth == 0) printing = 1;
          depth++;
        }
        if (printing) printf "%s", c;
        if (c == "}") {
          depth--;
          if (depth == 0) { printf "\n"; printing = 0; exit; }
        }
      }
      if (printing) printf "\n";
    }
  ' > "$OUTPUT_FILE"

# Verify output is valid JSON
if ! jq empty "$OUTPUT_FILE" 2>/dev/null; then
  echo "Warning: Cleaned output is not valid JSON" >&2
  echo "Showing first 30 lines:" >&2
  head -30 "$OUTPUT_FILE" >&2
fi
