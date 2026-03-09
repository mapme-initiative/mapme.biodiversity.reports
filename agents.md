# Agent Guide: mapme.biodiversity.reports

This document orients AI coding agents on how to work in this repository.

## What this repo is

A collection of reproducible conservation analysis reports. Each report analyzes geospatial indicators (forest cover loss, burned area, etc.) for a specific geographic context using the [`mapme.biodiversity`](https://github.com/mapme-initiative/mapme.biodiversity) R package. Reports are rendered with [Quarto](https://quarto.org/) and published to GitHub Pages via the `docs/` folder.

## Repository structure

```
mapme.biodiversity.reports/
├── _quarto.yml               # Quarto website configuration
├── index.qmd                 # Homepage
├── about.qmd                 # About page
├── assets/custom.scss        # Shared styling
├── reports/                  # Quarto report files (.qmd)
│   ├── threat_assessment_bolivia.qmd
│   ├── evaluation_laos_forest_cover.qmd
│   └── references.bib
├── scripts/                  # R processing scripts (run before rendering)
│   ├── install_packages.R    # One-time package setup
│   ├── bolivia/
│   │   ├── process_forest_cover.R
│   │   └── process_burned_area.R
│   ├── laos/
│   │   └── process_forest_cover.R
│   └── india/
│       └── process_forest_cover.R
├── data/                     # All data (gitignored — not version controlled)
│   ├── shared/
│   │   ├── mapme_resources/  # Cached GFW/MODIS tiles (reused across use-cases)
│   │   └── portfolio.gpkg    # KfW reference portfolio
│   ├── bolivia/
│   │   ├── input/            # Raw input data (WDPA geodatabase, admin boundaries)
│   │   └── output/           # Processed CSVs and geopackages
│   ├── laos/
│   │   ├── input/            # Raw input data (WDPA geodatabase)
│   │   └── output/           # Processed CSVs and geopackages
│   └── india/
│       ├── input/            # Village geojson files
│       └── output/           # Processed CSVs and geopackages
└── docs/                     # Rendered HTML (GitHub Pages output)
```

## Conventions

### Adding a new use-case

1. **Create input data folder**: `data/<country>/input/` with raw geospatial files.
2. **Write processing script**: `scripts/<country>/process_<indicator>.R` following the pattern in existing scripts. Scripts are run from the **project root** directory.
3. **Run the script** to generate output in `data/<country>/output/`.
4. **Write a Quarto report**: `reports/<report_name>.qmd` following existing report structure.
5. **Register the report** in `_quarto.yml` (navbar menu and sidebar).
6. **Update `index.qmd`** to list the new report.

### Path conventions

- Scripts run from project root: use paths like `"data/bolivia/input/wdpa.gdb"`.
- QMD reports live in `reports/` and reference data with `"../data/..."`.
- Shared tile cache is always `data/shared/mapme_resources/` — never delete it.

### Processing scripts

All scripts follow the same structure:
1. Load libraries
2. Configure `mapme_options(outdir = "data/shared/mapme_resources/")`
3. Load input geometries (from `data/<country>/input/`)
4. Call `get_resources()` to download/cache indicator data
5. Call `calc_indicators()` to compute statistics
6. Save CSV outputs to `data/<country>/output/`
7. Save processed portfolio with `write_portfolio()` to `data/<country>/output/`

### mapme.biodiversity key facts

- **Resource caching**: Downloaded tiles are cached in `outdir`. Never delete `data/shared/mapme_resources/`. Re-runs reuse cached data.
- **GFW version**: Use `"GFC-2024-v1.12"` for treecover and lossyear (covers 2001–2024).
- **Forest cover threshold**: Use `min_cover = 10` (10% canopy density) unless context requires otherwise.
- **Burned area processing**: Process protected areas individually when they span different MODIS tile subsets (see `scripts/bolivia/process_burned_area.R`).
- **CRS**: Always ensure input geometries are in EPSG:4326 before processing.

### Quarto reports

- Use `freeze: auto` in `_quarto.yml` so reports only re-render when source changes.
- Load pre-computed CSVs from `data/<country>/output/` — do not run heavy processing inside QMD files.
- Use `file.exists()` checks before loading optional output files.
- Visualizations use `leaflet` (interactive maps), `plotly` (charts), and `DT` (tables).

## Workflow for a new report

```bash
# 1. Install packages (first time only)
Rscript scripts/install_packages.R

# 2. Run the processing script
Rscript scripts/<country>/process_<indicator>.R

# 3. Render the report
quarto render reports/<report_name>.qmd

# 4. Preview the site
quarto preview
```

## Data quality checks

After finishing any data processing or wrangling step — in both R scripts and QMD files — **always verify correctness before moving on**:

- **Check group keys**: When using `group_by()` + `summarise()` or `pivot_wider()`, confirm that the grouping key uniquely identifies each observation. Shared keys (e.g. multiple rows with `lgd_villagecode=0`) will silently produce wrong summary values (`first()`, `min()`, etc. picking up another group's data).
- **Cross-check derived columns**: Any column derived from another (e.g. `baseline_2001`, `rel_loss`) should be spot-checked against the raw input: `summary()`, `table()`, and comparing a few rows manually.
- **Check for implausible values**: After computing relative or annualized metrics, check `summary()` for values that are physically impossible (e.g. annual forest loss > 100% of baseline). These indicate a data wrangling bug, not an outlier.
- **Verify join cardinality**: After `left_join()` or `inner_join()`, compare `nrow()` before and after to detect unexpected duplicates or row loss. Many-to-many joins silently inflate row counts.
- **Check NA propagation**: After any transformation, run `sum(is.na(...))` on key columns to ensure NAs haven't spread unexpectedly.
- **Render and review**: After writing a QMD report, always render it (`quarto render reports/<file>.qmd`) and visually inspect the output — tables, chart axes, and map layers — before committing.

## What NOT to do

- Do not run `get_resources()` or `calc_indicators()` inside `.qmd` files.
- Do not delete `data/shared/mapme_resources/` — it caches large tile downloads.
- Do not commit files in `data/` (gitignored). Commit only scripts and `.qmd` reports.
- Do not render the full site (`quarto render`) when only updating one report — use `quarto render reports/<file>.qmd` to save time.
