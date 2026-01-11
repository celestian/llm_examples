#!/usr/bin/env bash
set -euo pipefail

# Sanitizer Pipeline - Anonymize Czech person names using LLM
# Usage: ./pipeline.sh <input_text_file>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_stage() { echo -e "${CYAN}[STAGE]${NC} $*"; }

# Check dependencies
check_dependencies() {
  log_info "Checking dependencies..."
  
  local missing=0
  for cmd in ollama jq envsubst; do
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Missing dependency: $cmd"
      missing=1
    else
      log_success "Found: $cmd ($(command -v "$cmd"))"
    fi
  done
  
  if [ "$missing" -eq 1 ]; then
    log_error "Please install missing dependencies"
    echo "" >&2
    echo "Installation hints:" >&2
    echo "  - ollama: https://ollama.ai" >&2
    echo "  - jq: apt install jq / brew install jq" >&2
    echo "  - envsubst: apt install gettext-base / brew install gettext" >&2
    exit 1
  fi
}

# Usage check
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <input_text_file>" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 data/input/sample.txt" >&2
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  log_error "Input file not found: $INPUT_FILE"
  exit 1
fi

# Configuration
OLLAMA_MODEL="${OLLAMA_MODEL:-qwen2.5-coder:7b}"
OLLAMA_TEMPERATURE="${OLLAMA_TEMPERATURE:-0}"

# Create timestamped output directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="$PROJECT_ROOT/data/output/run_$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

echo ""
echo "========================================="
echo "  Sanitizer Pipeline"
echo "========================================="
echo ""
log_info "Output directory: $OUTPUT_DIR"

# Check dependencies first
check_dependencies

log_info "Using Ollama model: $OLLAMA_MODEL"
log_info "Input file: $INPUT_FILE"
echo ""

# Read input text
INPUT_TEXT=$(<"$INPUT_FILE")

# ============================================================================
# STAGE A: Extract person names
# ============================================================================
log_stage "Stage A: Extracting person names from text..."
echo ""

PROMPT_A="$OUTPUT_DIR/prompt_a.txt"
OUTPUT_A_JSON="$OUTPUT_DIR/stage_a.json"

export INPUT_TEXT
"$SCRIPT_DIR/render_template.sh" \
  "$PROJECT_ROOT/templates/stage_a_extract.tmpl" \
  "$PROMPT_A"

log_info "Rendered prompt: $PROMPT_A"
log_info "Running Ollama (Stage A)... this may take a minute"

# Run Ollama and clean output (remove ANSI codes and markdown)
OUTPUT_A_RAW="$OUTPUT_DIR/stage_a_raw.txt"
if ! OLLAMA_NUM_PREDICT=2000 ollama run "$OLLAMA_MODEL" \
  --nowordwrap \
  < "$PROMPT_A" > "$OUTPUT_A_RAW" 2>&1; then
  log_error "Ollama failed at Stage A"
  exit 1
fi

# Clean Ollama output (remove ANSI escape codes and markdown blocks)
"$SCRIPT_DIR/clean_ollama_output.sh" "$OUTPUT_A_RAW" "$OUTPUT_A_JSON"

# Validate Stage A output
if ! "$SCRIPT_DIR/validate_json.sh" \
  "$OUTPUT_A_JSON" \
  "$PROJECT_ROOT/config/json_schemas/stage_a.schema.json"; then
  log_error "Stage A validation failed"
  log_error "Check output: $OUTPUT_A_JSON"
  exit 1
fi

log_success "Stage A complete: $OUTPUT_A_JSON"
log_info "Persons found: $(jq '.persons | length' "$OUTPUT_A_JSON")"
echo ""

# ============================================================================
# STAGE B: Create mapping
# ============================================================================
log_stage "Stage B: Creating name-to-placeholder mapping..."
echo ""

PROMPT_B="$OUTPUT_DIR/prompt_b.txt"
OUTPUT_B_JSON="$OUTPUT_DIR/stage_b.json"

PERSONS_JSON=$(<"$OUTPUT_A_JSON")
export PERSONS_JSON

"$SCRIPT_DIR/render_template.sh" \
  "$PROJECT_ROOT/templates/stage_b_mapping.tmpl" \
  "$PROMPT_B"

log_info "Rendered prompt: $PROMPT_B"
log_info "Running Ollama (Stage B)..."

OUTPUT_B_RAW="$OUTPUT_DIR/stage_b_raw.txt"
if ! OLLAMA_NUM_PREDICT=1000 ollama run "$OLLAMA_MODEL" \
  --nowordwrap \
  < "$PROMPT_B" > "$OUTPUT_B_RAW" 2>&1; then
  log_error "Ollama failed at Stage B"
  exit 1
fi

# Clean Ollama output
"$SCRIPT_DIR/clean_ollama_output.sh" "$OUTPUT_B_RAW" "$OUTPUT_B_JSON"

# Validate Stage B output
if ! "$SCRIPT_DIR/validate_json.sh" \
  "$OUTPUT_B_JSON" \
  "$PROJECT_ROOT/config/json_schemas/stage_b.schema.json"; then
  log_error "Stage B validation failed"
  log_error "Check output: $OUTPUT_B_JSON"
  exit 1
fi

log_success "Stage B complete: $OUTPUT_B_JSON"
log_info "Mappings created: $(jq '.mapping | length' "$OUTPUT_B_JSON")"
echo ""

# ============================================================================
# STAGE C: Replace names with placeholders
# ============================================================================
log_stage "Stage C: Anonymizing text..."
echo ""

PROMPT_C="$OUTPUT_DIR/prompt_c.txt"
OUTPUT_C_JSON="$OUTPUT_DIR/stage_c.json"
OUTPUT_C_TXT="$OUTPUT_DIR/stage_c.txt"

MAPPING_JSON=$(<"$OUTPUT_B_JSON")
ORIGINAL_TEXT=$(<"$INPUT_FILE")
export MAPPING_JSON
export ORIGINAL_TEXT

"$SCRIPT_DIR/render_template.sh" \
  "$PROJECT_ROOT/templates/stage_c_replace.tmpl" \
  "$PROMPT_C"

log_info "Rendered prompt: $PROMPT_C"
log_info "Running Ollama (Stage C)..."

OUTPUT_C_RAW="$OUTPUT_DIR/stage_c_raw.txt"
if ! OLLAMA_NUM_PREDICT=2000 ollama run "$OLLAMA_MODEL" \
  --nowordwrap \
  < "$PROMPT_C" > "$OUTPUT_C_RAW" 2>&1; then
  log_error "Ollama failed at Stage C"
  exit 1
fi

# Clean Ollama output
"$SCRIPT_DIR/clean_ollama_output.sh" "$OUTPUT_C_RAW" "$OUTPUT_C_JSON"

# Validate Stage C output
if ! "$SCRIPT_DIR/validate_json.sh" \
  "$OUTPUT_C_JSON" \
  "$PROJECT_ROOT/config/json_schemas/stage_c.schema.json"; then
  log_error "Stage C validation failed"
  log_error "Check output: $OUTPUT_C_JSON"
  exit 1
fi

# Extract final anonymized text to TXT file
jq -r '.anonymized_text' "$OUTPUT_C_JSON" > "$OUTPUT_C_TXT"

log_success "Stage C complete: $OUTPUT_C_JSON"
log_success "Final anonymized text: $OUTPUT_C_TXT"
echo ""

# ============================================================================
# Summary
# ============================================================================
echo "========================================="
log_success "Pipeline completed successfully!"
echo "========================================="
echo ""
echo "Results in: $OUTPUT_DIR"
echo ""
echo "Stage A (Persons):     $OUTPUT_A_JSON"
echo "Stage B (Mapping):     $OUTPUT_B_JSON"
echo "Stage C (Anonymized):  $OUTPUT_C_JSON"
echo "Final text:            $OUTPUT_C_TXT"
echo ""
echo "View final output:"
echo "  cat $OUTPUT_C_TXT"
echo ""
echo "View mapping:"
echo "  jq '.mapping' $OUTPUT_C_JSON"
echo ""
