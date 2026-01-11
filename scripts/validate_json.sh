#!/usr/bin/env bash
set -euo pipefail

# Validate JSON file against JSON schema
# Usage: ./validate_json.sh <json_file> <schema_file>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <json_file> <schema_file>" >&2
  exit 1
fi

JSON_FILE="$1"
SCHEMA_FILE="$2"

if [ ! -f "$JSON_FILE" ]; then
  echo "Error: JSON file not found: $JSON_FILE" >&2
  exit 1
fi

if [ ! -f "$SCHEMA_FILE" ]; then
  echo "Error: Schema file not found: $SCHEMA_FILE" >&2
  exit 1
fi

# Validate JSON syntax first
if ! jq empty "$JSON_FILE" 2>/dev/null; then
  echo "Error: Invalid JSON syntax in $JSON_FILE" >&2
  echo "" >&2
  echo "Content preview:" >&2
  head -20 "$JSON_FILE" >&2
  exit 1
fi

# Basic validation: Check if required top-level fields exist
# Extract required fields from schema and check if they exist in JSON
REQUIRED_FIELDS=$(jq -r '.required // [] | .[]' "$SCHEMA_FILE")

for field in $REQUIRED_FIELDS; do
  if ! jq -e "has(\"$field\")" "$JSON_FILE" >/dev/null 2>&1; then
    echo "Error: Missing required field '$field' in $JSON_FILE" >&2
    echo "" >&2
    echo "Required fields in schema:" >&2
    jq -r '.required // [] | .[]' "$SCHEMA_FILE" >&2
    echo "" >&2
    echo "Available fields in JSON:" >&2
    jq -r 'keys | .[]' "$JSON_FILE" >&2
    exit 1
  fi
done

# All required fields present
echo "✓ JSON validation passed: $JSON_FILE"
