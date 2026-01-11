# Local LLM Workstation -- Technical Summary

## Goal

The goal is to design a desktop / workstation setup capable of
**smoothly running 32--34B LLM models** using **Q5_K\_M quantization**,
without VRAM pressure, and with a strong focus on **instruction
accuracy, structured output, and everyday productive use**.

Larger models (**70B and above**) are intentionally handled via **remote
inference**.

------------------------------------------------------------------------

## Intended Usage

Primarily **tooling and knowledge work**, not a generic chat use case:

-   **High‑quality instruction following**
    -   precise text replacements
    -   deterministic transformations `.txt ↔ .yaml / .md`
-   **Code assistant**
    -   primarily YAML and Markdown
    -   optionally Bash and Python
-   **Structured document work**
    -   Markdown, YAML, configuration files
-   **CZ ↔ EN translation**
-   **Text analysis and summarization**
    -   meeting notes
    -   decision logs
    -   supporting materials for decision‑making

The key requirement is **model discipline and consistent structured
output**.

------------------------------------------------------------------------

## Recommended Configuration (Best Value)

### Hardware

-   **GPU:** NVIDIA RTX 4090 (24 GB VRAM)
-   **CPU:** AMD Ryzen 9 7900 (12 cores / 24 threads)
-   **RAM:** 128 GB DDR5
-   **Storage:** NVMe SSD 2 TB (PCIe 4.0)
-   **OS:** Ubuntu 22.04 LTS\
    (optionally Linux Mint based on Ubuntu)

### Why This Combination

-   RTX 4090 provides:
    -   the highest inference throughput in the consumer class
    -   best ecosystem support (CUDA, llama.cpp, Ollama)
-   128 GB RAM:
    -   supports long contexts
    -   enables memory‑mapped models (mmap)
    -   avoids aggressive layer offloading
-   Ubuntu 22.04:
    -   stable NVIDIA drivers
    -   minimal friction with AI toolchains

------------------------------------------------------------------------

## Model Strategy

### Local

-   **34B instruct model -- Q5_K\_M (default)**
    -   best balance of quality / speed / VRAM usage
    -   behavior close to Q6, without memory stress
-   **Smaller utility models (7--14B, Q4)**
    -   fast edits
    -   simple transformations

### Remote

-   **70B+ models via OpenRouter**
    -   deep analysis
    -   output validation
    -   complex reasoning

This hybrid approach provides the **best Total Cost of Ownership
(TCO)**.

------------------------------------------------------------------------

## Expected Inference Performance (Approximate)

### RTX 4090

  Model     Quantization   Performance
  --------- -------------- -----------------------
  14B       Q4             \~30--50 tokens/s
  **34B**   **Q5_K\_M**    **\~12--20 tokens/s**
  34B       Q6             \~8--12 tokens/s

The **12--20 tokens/s** range is fully suitable for interactive work
(transformations, summarization, structured outputs).

------------------------------------------------------------------------

## Alternative Option -- RTX 3090

-   **RTX 3090 (24 GB VRAM, typically second‑hand)**
-   approximately **70% of RTX 4090 inference performance**
-   still fully capable of running **34B Q5_K\_M** models

### Expected Performance

-   34B Q5_K\_M: **\~8--14 tokens/s**

------------------------------------------------------------------------

## Estimated Cost (EU / CZ Market)

### RTX 4090 Configuration

-   total system cost: **\~€3,200--3,600 / \~80--90k CZK**

### RTX 3090 Configuration

-   total system cost: **\~€2,400--2,800 / \~60--70k CZK**

------------------------------------------------------------------------

## Summary

**RTX 4090 + Ryzen 9 7900 + 128 GB RAM + Ubuntu 22.04** currently
represents the **most reasonable desktop solution** for smooth operation
of **34B LLM models using Q5_K\_M quantization**.

Handling **70B models via remote inference** avoids expensive and
complex multi‑GPU setups while preserving high‑quality outputs.
