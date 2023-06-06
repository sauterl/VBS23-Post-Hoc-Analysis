# VBS23-Post-Hoc-Analysis
Shared code for the post-hoc analysis of Video Browser Showdown 2023

## Repository Structure

* `data/` Shared data parent folder
* `data/raw` The raw audit and run information from DRES
* `data/logs` Relevant logs per-team
* `data/processed` Extracted data from `data/raw` for detailed analysis (e.g. AVS data separated from KIS data etc.)
* `data/datasets_mdetadata` Metadata from V3C and MVK datasets (segments, FPS, etc.)
* `src/*` Analysis code per language (e.g. `src/julia` for Julia)
* `plots/` Plots produced with the code in `src/*` based on the data in `data/*`
* `tex/` LaTeX output, produced with code in `src/*`, based on the data in `data/*`
