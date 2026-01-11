# Agent Guidelines for Sanitizer Project

## Project Overview

This is a proof-of-concept project for anonymizing personal names in Czech text using local LLM models (Ollama). The project uses a three-stage pipeline to extract, map, and replace person names with placeholders, handling Czech declension forms.

## Project Structure

```
sanitizer/
├── README.md                    # Main documentation (English)
├── AGENTS.md                    # This file - AI agent guidelines
├── templates/                   # LLM prompt templates
│   ├── stage_a_extract.tmpl     # Extract person names → JSON
│   ├── stage_b_mapping.tmpl     # Create name→placeholder mapping → JSON
│   └── stage_c_replace.tmpl     # Replace names in text → JSON
├── data/
│   ├── input/                   # Input text files (Czech)
│   │   └── sample.txt
│   └── output/                  # Pipeline outputs (gitignored)
│       └── run_YYYYMMDD_HHMMSS/ # Timestamped runs
│           ├── prompt_a.txt
│           ├── stage_a.json
│           ├── prompt_b.txt
│           ├── stage_b.json
│           ├── prompt_c.txt
│           ├── stage_c.json
│           └── stage_c.txt      # Final anonymized text
├── scripts/
│   ├── pipeline.sh              # Main orchestrator (run full pipeline)
│   ├── render_template.sh       # Template renderer using envsubst
│   └── validate_json.sh         # JSON schema validator
└── config/
    ├── ollama.env               # Ollama configuration
    └── json_schemas/            # JSON Schema definitions
        ├── stage_a.schema.json  # Persons extraction schema
        ├── stage_b.schema.json  # Mapping schema
        └── stage_c.schema.json  # Anonymization result schema
```

## Build/Test/Run Commands

### Running the Complete Pipeline

```bash
# Basic usage - runs all three stages
./scripts/pipeline.sh data/input/sample.txt

# With custom Ollama model
OLLAMA_MODEL=llama3.2:latest ./scripts/pipeline.sh data/input/sample.txt

# Source config first (optional)
source config/ollama.env
./scripts/pipeline.sh data/input/sample.txt
```

### Running Individual Stages

```bash
# Stage A: Extract person names
export INPUT_TEXT=$(cat data/input/sample.txt)
./scripts/render_template.sh \
  templates/stage_a_extract.tmpl \
  /tmp/prompt_a.txt

ollama run qwen2.5-coder:7b --nowordwrap < /tmp/prompt_a.txt > /tmp/stage_a.json

# Validate Stage A output
./scripts/validate_json.sh \
  /tmp/stage_a.json \
  config/json_schemas/stage_a.schema.json

# Stage B: Create mapping
export PERSONS_JSON=$(cat /tmp/stage_a.json)
./scripts/render_template.sh \
  templates/stage_b_mapping.tmpl \
  /tmp/prompt_b.txt

ollama run qwen2.5-coder:7b --nowordwrap < /tmp/prompt_b.txt > /tmp/stage_b.json

# Stage C: Anonymize
export MAPPING_JSON=$(cat /tmp/stage_b.json)
export ORIGINAL_TEXT=$(cat data/input/sample.txt)
./scripts/render_template.sh \
  templates/stage_c_replace.tmpl \
  /tmp/prompt_c.txt

ollama run qwen2.5-coder:7b --nowordwrap < /tmp/prompt_c.txt > /tmp/stage_c.json

# Extract final text
jq -r '.anonymized_text' /tmp/stage_c.json > /tmp/stage_c.txt
```

### Testing

```bash
# Quick test with simple input
echo "Jan Novák mluvil s Marií." > test.txt
./scripts/pipeline.sh test.txt

# Verify outputs
jq '.' data/output/run_*/stage_*.json
cat data/output/run_*/stage_c.txt

# Test individual script
./scripts/validate_json.sh \
  data/output/run_*/stage_a.json \
  config/json_schemas/stage_a.schema.json
```

## Code Style Guidelines

### Shell Scripting (Bash)

#### Shebang and Options
- **Always** use `#!/usr/bin/env bash` for portability
- **Always** enable strict mode: `set -euo pipefail`
  - `-e`: Exit on error (fail-fast)
  - `-u`: Treat unset variables as errors
  - `-o pipefail`: Exit if any command in pipeline fails

#### Variables
- Use UPPERCASE for script-level constants and environment variables
- Use lowercase or snake_case for local variables
- Quote all variable expansions: `"$VARIABLE"` not `$VARIABLE`
- Prefer meaningful names: `INPUT_FILE` over `f`

#### Parameter Validation
```bash
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <arg1> <arg2>" >&2
  exit 1
fi
```

#### File Checks
- Always validate file existence before use:
```bash
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: file not found: $INPUT_FILE" >&2
  exit 1
fi
```

#### Error Messages
- Write errors to stderr using `>&2`
- Include context in error messages (which file, which stage)
- Use descriptive prefixes: `"Error: "`, `"Warning: "`
- Provide hints for common issues

#### Colored Output (pipeline.sh style)
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
```

### Template Files (.tmpl)

#### Format Convention
- Use `${VARIABLE}` syntax (envsubst format)
- **NOT** `<<<TAG>>>` (old format - deprecated)
- Common variables:
  - `${INPUT_TEXT}` - Input file content
  - `${PERSONS_JSON}` - Stage A JSON output
  - `${MAPPING_JSON}` - Stage B JSON output
  - `${ORIGINAL_TEXT}` - Original input text

#### Prompt Structure
- English prompts for LLM (better model performance)
- Clear task description
- Explicit rules as bullet points
- JSON schema definition with examples
- Instruction: "Return ONLY the JSON output, no additional text"

#### Example Template Structure
```
You are a <role> system.

Task: <description>

Rules:
- <rule 1>
- <rule 2>

Output format (JSON schema):
{
  "field": "value"
}

Example output:
{...}

INPUT DATA:
${VARIABLE}

Return ONLY the JSON output, no additional text.
```

### JSON Files

#### Schema Files
- Use JSON Schema Draft 7
- Include `$schema`, `title`, `description`
- Define all required fields in `required` array
- Use `pattern` for placeholder validation: `^\\[person \\d+\\]$`
- Include field descriptions

#### Output Format
- All LLM outputs must be valid JSON
- Use `jq` for validation and extraction
- Common structure:
  - Stage A: `{"persons": [{"canonical": "...", "occurrences": [...]}]}`
  - Stage B: `{"mapping": [{"placeholder": "...", "name": "..."}]}`
  - Stage C: `{"anonymized_text": "...", "mapping": [...]}`

### Data Files

#### Input Format
- UTF-8 encoding required
- Plain text format
- Czech language with full diacritics (ě, š, č, ř, ž, ý, á, í, é, ú, ů, ň, ť, ď)
- One or more sentences per file

#### Output Format
- Timestamped directories: `data/output/run_YYYYMMDD_HHMMSS/`
- Both JSON and TXT outputs
- Preserve original text structure in anonymized output

## Naming Conventions

### Files
- Use snake_case for shell scripts: `pipeline.sh`, `validate_json.sh`
- Use descriptive names: `stage_a_extract.tmpl` not `a.tmpl`
- Templates use `.tmpl` extension (no `.txt`)
- JSON schema files: `stage_X.schema.json`
- Output files: `stage_X.json` and `stage_c.txt`

### Variables
- UPPERCASE for environment/constants: `INPUT_FILE`, `OLLAMA_MODEL`
- Lowercase for local variables: `missing=0`, `timestamp=$(date)`
- Multi-word: `OUTPUT_DIR` not `OUTPUTDIR`

### Functions
- snake_case: `check_dependencies()`, `log_info()`
- Verb-noun pattern: `validate_json()`, `render_template()`

## Error Handling

### Shell Scripts
- Use `set -euo pipefail` for automatic error propagation
- Validate all inputs before processing
- Provide clear error messages with context
- Exit with non-zero status: `exit 1`
- Check file existence before reading
- Show helpful hints for common errors

### Pipeline Execution
- Stop on first error (strict mode)
- Validate JSON after each stage
- Log stage progress with timestamps
- Preserve all intermediate outputs for debugging

### Common Issues

**Invalid JSON from LLM:**
- Solution: Check prompt clarity, increase `OLLAMA_NUM_PREDICT`
- Use `--nowordwrap` flag with Ollama
- Validate raw output with `jq empty`

**Missing Czech diacritics:**
- Solution: Ensure UTF-8 encoding: `file -i input.txt`
- Convert if needed: `iconv -f ISO-8859-2 -t UTF-8`

**Validation failures:**
- Solution: Check JSON structure matches schema
- Review required fields in schema
- Verify LLM returned correct format

## Development Workflow

### Making Changes

1. **Modify templates** - Edit `.tmpl` files to change prompts
2. **Test template rendering** - Use `render_template.sh` to verify
3. **Run single stage** - Test with Ollama manually
4. **Validate output** - Use `validate_json.sh`
5. **Run full pipeline** - Test complete three-stage process
6. **Check results** - Verify JSON and TXT outputs

### Adding New Stages

1. Create new template: `templates/stage_X_description.tmpl`
2. Define JSON schema: `config/json_schemas/stage_X.schema.json`
3. Update `pipeline.sh` to include new stage
4. Add validation step
5. Update README.md with documentation

### Debugging

```bash
# Check template rendering
export INPUT_TEXT="Test text"
./scripts/render_template.sh templates/stage_a_extract.tmpl /tmp/test.txt
cat /tmp/test.txt

# Validate JSON manually
jq '.' data/output/run_*/stage_a.json

# Check specific fields
jq '.persons[] | .canonical' data/output/run_*/stage_a.json

# Test schema validation
./scripts/validate_json.sh <json_file> <schema_file>
```

## Testing Considerations

- No formal test framework (POC project)
- Manual testing via pipeline execution
- Verify each stage output format
- Test with different Czech texts (various declensions)
- Check placeholder consistency across stages
- Validate Czech character handling (UTF-8)
- Test error conditions (invalid input, missing files)

## Dependencies

- **Bash** 4.0+ - Shell interpreter
- **Ollama** 0.13+ - Local LLM runtime
- **qwen2.5-coder:7b** - Default model (configurable via `OLLAMA_MODEL`)
- **jq** 1.6+ - JSON processor and validator
- **envsubst** (gettext) - Template substitution
- **Standard Unix tools** - cat, date, mkdir

Installation:
```bash
# Ollama
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b

# jq and envsubst (usually pre-installed)
# Ubuntu/Debian:
sudo apt install jq gettext-base

# macOS:
brew install jq gettext
```

## Configuration

### Environment Variables

- `OLLAMA_MODEL` - Model to use (default: `qwen2.5-coder:7b`)
- `OLLAMA_TEMPERATURE` - Temperature 0-1 (default: `0` for deterministic)
- `OLLAMA_NUM_PREDICT` - Max tokens to generate
- `OLLAMA_NUM_CTX` - Context window size

### Config Files

- `config/ollama.env` - Default Ollama settings (can be sourced)
- `config/json_schemas/*.schema.json` - JSON Schema definitions

## Pipeline Details

### Stage A: Person Extraction
- **Input**: Czech text with person names
- **Output**: JSON with persons and their declension forms
- **Key challenge**: Grouping different grammatical cases as same person
- **Example**: "Jan Novák", "Janu Novákovi", "Janem Novákem" → all "Jan Novák"

### Stage B: Mapping Creation
- **Input**: Stage A JSON (persons)
- **Output**: JSON mapping persons to placeholders
- **Format**: `[person 1]`, `[person 2]`, etc.
- **Ordering**: By first occurrence in original text

### Stage C: Text Anonymization
- **Input**: Stage B JSON (mapping) + original text
- **Output**: JSON with anonymized text + mapping
- **Key challenge**: Replace ALL declension forms with same placeholder
- **Final output**: Both JSON and plain TXT file

## Notes for AI Agents

- This is a POC (proof-of-concept), not production code
- Focus on Czech language text processing
- Pipeline is sequential - each stage depends on previous output
- Temperature=0 is critical for reproducible results
- Prompts are in English (better LLM performance) but operate on Czech text
- Person name detection must handle Czech declension (7 grammatical cases)
- All outputs use timestamped directories - never overwrite
- JSON validation is strict - pipeline fails on invalid output
- Templates use `envsubst` (${VARIABLE}) not sed (<<<TAG>>>)
- Always use `--nowordwrap` flag with Ollama for clean JSON output

## Common Agent Tasks

### Running the pipeline
```bash
./scripts/pipeline.sh data/input/sample.txt
```

### Modifying prompts
Edit files in `templates/` directory. Use `${VARIABLE}` for substitutions.

### Adding validation
1. Create JSON schema in `config/json_schemas/`
2. Add validation call in `pipeline.sh`

### Debugging failed runs
```bash
# Check latest run
ls -lt data/output/ | head -2

# View raw LLM output
cat data/output/run_*/stage_a.json

# Validate manually
./scripts/validate_json.sh data/output/run_*/stage_a.json config/json_schemas/stage_a.schema.json
```

### Testing changes
```bash
# Quick test
echo "Jan Novák navštívil Prahu." > test.txt
./scripts/pipeline.sh test.txt

# Check result
cat data/output/run_*/stage_c.txt
```
