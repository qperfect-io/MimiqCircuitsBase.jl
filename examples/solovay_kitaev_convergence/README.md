# Solovay-Kitaev Convergence Analysis

This directory contains scripts to analyze the convergence, runtime, and resource usage of the Solovay-Kitaev decomposition algorithm implemented in `MimiqCircuitsBase.jl`.

## Directory Structure

- `src/SolovayKitaevAnalysis.jl`: Shared module containing data structures, plotting logic, and basis definitions.
- `bin/`: Executable scripts for running experiments and generating reports.
    - `run_convergence.jl`: Run SK decomposition on random unitaries or specific gates.
    - `run_basis_comparison.jl`: Compare performance across different universal basis sets.
    - `plot_convergence.jl`: Regenerate plots from `run_convergence` data.
    - `plot_basis_comparison.jl`: Regenerate plots from `run_basis_comparison` data.
    - `generate_table.jl`: Generate ASCII and LaTeX tables from comparison data.
    - `run_full_report.jl`: Orchestration script to run a comprehensive suite of experiments.

## Usage

All scripts should be run from the `solovay_kitaev_convergence` directory, creating a Julia project environment if necessary.

### 1. Single Convergence Experiment

Approximates random unitaries (or subsets like Random RZ) using a specific configuration.

```bash
julia --project=. bin/run_convergence.jl \
    --name my_experiment \
    --max-depth 5 \
    --samples 100 \
    --basis clifford+t \
    --net-depth 12 \
    --net-points 2000 \
    --net-min-dist 0.08 \
    --output-dir results/my_run
```

**Options:**
- `--name`: Unified prefix for all outputs (CSV, Metadata, Plots).
- `--basis`: `clifford+t`, `clifford+sqrtt`, `rx(1.0)+rz(1.0)`, `clifford+t+rx(π/8)`.
- `--net-depth`: Maximum recursion depth for generating the ε-net (pre-computation).
- `--net-points`: Maximum number of points in the ε-net.
- `--net-min-dist`: Minimum distance between points in the ε-net (density control).

### 2. Basis Comparison

Runs the same random unitaries against multiple basis sets to compare their convergence rates.

```bash
julia --project=. bin/run_basis_comparison.jl \
    --name sk_basis_comp \
    --max-depth 5 \
    --samples 50 \
    --net-depth 10 \
    --output-dir results/comparison
```

### 3. Report Generation

To generate specific tables or re-plot data:

```bash
# Generate LaTeX/ASCII table from comparison results (saves to .txt and .tex)
julia --project=. bin/generate_table.jl --csv results/comparison/sk_basis_comp.csv

# Re-plot
julia --project=. bin/plot_basis_comparison.jl --output-dir results/comparison --csv sk_basis_comp.csv
```

## Output

- **CSV Files**: Raw data containing error, time, and gate counts.
- **Metadata**: JSON file (`<name>_meta.json`) with exact experiment configuration.
- **Plots**: 
    - `<name>.pdf`: Aggregated metrics (Error, Time, Gates) vs Depth.
    - `<name>_detail_*.pdf`: Individual metric plots with variance bands.
- **Tables**: Saved as `<name>_table.txt` (ASCII) and `<name>_table.tex` (LaTeX).

## Full Report Automation

To run a standard suite of experiments (varying net sizes and depths) and organize the results:

```bash
julia --project=. bin/run_full_report.jl
```
