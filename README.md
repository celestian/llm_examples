# Sanitizer

Czech text anonymization using local LLM (Ollama). Three-stage pipeline handles declension forms.

## Quick Start

```bash
# Install dependencies
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b

# Run pipeline
./scripts/pipeline.sh data/input/sample.txt

# Check output
cat data/output/run_*/stage_c.txt
```

## How It Works

Stage A: Extract persons → Stage B: Create mapping → Stage C: Anonymize

**Example:**
```
Input:  "Jan Novák se setkal s Petrou. Později Jan mluvil s panem Novákem."
Output: "[person 1] se setkal s [person 2]. Později [person 1] mluvil s panem [person 1]."
```

Handles Czech declension (Jan/Jana/Janu/Janem = same person).

## Pipeline Stages

**Stage A** - Extract person names with all grammatical forms
- Input: Czech text
- Output: `{"persons": [{"canonical": "Jan Novák", "occurrences": [...]}]}`

**Stage B** - Map persons to placeholders  
- Input: Stage A JSON
- Output: `{"mapping": [{"placeholder": "[person 1]", "name": "Jan Novák"}]}`

**Stage C** - Replace all occurrences
- Input: Stage B JSON + original text
- Output: Anonymized text + mapping

## Configuration

Pipeline works with defaults (qwen2.5-coder:7b, temperature=0). Optional configuration:

```bash
# Override via environment variable
OLLAMA_MODEL=llama3.2:latest ./scripts/pipeline.sh input.txt

# Or source config file (optional)
source config/ollama.env
./scripts/pipeline.sh input.txt
```

Available settings in `config/ollama.env`:
- `OLLAMA_MODEL` - LLM model to use
- `OLLAMA_TEMPERATURE` - Temperature (0=deterministic)
- `OLLAMA_NUM_PREDICT` - Max tokens per stage
- `OLLAMA_NUM_CTX` - Context window size

## Project Structure

```
scripts/pipeline.sh          # Main orchestrator
templates/*.tmpl             # LLM prompts (English)
config/json_schemas/         # Output validation
data/input/                  # Your text files
data/output/run_*/           # Timestamped results
```

## Outputs

Each run creates timestamped directory:
- `stage_a.json` - Extracted persons
- `stage_b.json` - Name→placeholder mapping  
- `stage_c.json` - Full result with metadata
- `stage_c.txt` - Final anonymized text
- `prompt_*.txt` - Rendered LLM prompts

## Troubleshooting

**Invalid JSON from LLM**
```bash
# Increase token limit
export OLLAMA_NUM_PREDICT=2048
```

**Czech characters broken**
```bash
# Check encoding
file -i input.txt  # Should be UTF-8
```

## Development

See [AGENTS.md](AGENTS.md) for detailed guidelines on:
- Code style (bash, templates, JSON)
- Naming conventions  
- Error handling
- Adding new stages

## Dependencies

- Bash 4.0+
- Ollama 0.13+
- jq 1.6+
- envsubst (gettext)

## License

MIT