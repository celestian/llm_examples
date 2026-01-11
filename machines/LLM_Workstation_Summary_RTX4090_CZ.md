# Lokální LLM workstation -- technické shrnutí

## Cíl

Cílem je navrhnout desktopovou / workstation sestavu schopnou **svižně
provozovat 32--34B LLM modely** v kvantizaci **Q5_K\_M**, bez stresu z
nedostatku VRAM, se zaměřením na **přesné instrukční chování, práci se
strukturou a každodenní produktivní použití**.

Větší modely (**70B a více**) jsou záměrně řešeny **vzdáleně (remote
inference)**.

------------------------------------------------------------------------

## Předpokládané použití

Primárně **tooling a knowledge work**, nikoliv obecný chat:

-   **Kvalitní instruct**
    -   přesné nahrazování v textech
    -   deterministické transformace `.txt ↔ .yaml / .md`
-   **Code assistant**
    -   primárně YAML a Markdown
    -   doplňkově Bash a Python
-   **Práce se strukturou**
    -   Markdown, YAML, konfigurační soubory
-   **Překlady CZ ↔ EN**
-   **Analýza textů a sumarizace**
    -   poznámky z meetingů
    -   decision logy
    -   podklady pro rozhodování

Klíčovým požadavkem je **disciplína modelu a konzistentní strukturovaný
výstup**.

------------------------------------------------------------------------

## Doporučená konfigurace (best value)

### Hardware

-   **GPU:** NVIDIA RTX 4090 (24 GB VRAM)
-   **CPU:** AMD Ryzen 9 7900 (12 jader / 24 vláken)
-   **RAM:** 128 GB DDR5
-   **Disk:** NVMe SSD 2 TB (PCIe 4.0)
-   **OS:** Ubuntu 22.04 LTS\
    (případně Linux Mint založený na Ubuntu)

### Proč tato kombinace

-   RTX 4090 nabízí:
    -   nejvyšší inference výkon v consumer třídě
    -   nejlepší podporu v AI toolchainu (CUDA, llama.cpp, Ollama)
-   128 GB RAM:
    -   umožňuje dlouhé kontexty
    -   paměťové mapování modelů (mmap)
    -   eliminuje nutnost agresivního offloadu
-   Ubuntu 22.04:
    -   stabilní NVIDIA ovladače
    -   minimum problémů s AI stackem

------------------------------------------------------------------------

## Modelová strategie

### Lokálně

-   **34B instruct model -- Q5_K\_M (výchozí volba)**
    -   nejlepší poměr kvalita / rychlost / VRAM
    -   chování blízké Q6, ale bez paměťových kompromisů
-   **Menší utility modely (7--14B, Q4)**
    -   rychlé úpravy
    -   jednoduché transformace

### Vzdáleně

-   **70B+ modely přes OpenRouter**
    -   hlubší analýza
    -   validace výstupů
    -   složitější reasoning

Hybridní přístup poskytuje **nejlepší TCO (Total Cost of Ownership)**.

------------------------------------------------------------------------

## Očekávaný výkon inference (orientačně)

### RTX 4090

  Model     Kvantizace    Výkon
  --------- ------------- -----------------------
  14B       Q4            \~30--50 tokenů/s
  **34B**   **Q5_K\_M**   **\~12--20 tokenů/s**
  34B       Q6            \~8--12 tokenů/s

Rozsah **12--20 tokenů/s** je plně použitelný pro interaktivní práci
(transformace, sumarizace, strukturovaný výstup).

------------------------------------------------------------------------

## Alternativní varianta -- RTX 3090

-   **RTX 3090 (24 GB VRAM, typicky z druhé ruky)**
-   přibližně **70 % výkonu RTX 4090**
-   stále plně použitelná pro **34B Q5_K\_M**

### Očekávaný výkon

-   34B Q5_K\_M: **\~8--14 tokenů/s**

------------------------------------------------------------------------

## Odhadované náklady (ČR)

### Varianta RTX 4090

-   celková cena sestavy: **\~80--90 tisíc Kč**

### Varianta RTX 3090

-   celková cena sestavy: **\~60--70 tisíc Kč**

------------------------------------------------------------------------

## Shrnutí

**RTX 4090 + Ryzen 9 7900 + 128 GB RAM + Ubuntu 22.04** představuje v
současnosti **nejrozumnější desktopové řešení** pro svižný provoz **34B
LLM modelů v kvantizaci Q5_K\_M**.

Použití **70B modelů formou vzdálené inference** umožňuje vyhnout se
drahému a komplikovanému multi-GPU řešení při zachování vysoké kvality
výstupů.
