# Agent Guide: mapme.biodiversity.reports

> **READ THIS FIRST.** This document is the single source of truth for coding agents working in this repository. Follow its protocols exactly. Skipping verification steps has caused real bugs in production reports.

## Session start protocol

**Every time you begin a new session or conversation**, follow these steps before writing any code:

1. **Identify the use-case.** Ask or infer which country/report the user is referring to. The active reports are:
   - `reports/threat_assessment_bolivia.qmd` — Bolivia threat assessment
   - `reports/evaluation_laos_forest_cover.qmd` — Laos forest cover evaluation
   - `reports/forest_cover_india.qmd` — India (Tripura) forest cover assessment
2. **Read the task history.** Check `taskdescriptions/<country>/` for all task files (Task1.md, Task2.md, etc.) in chronological order. These contain the user's instructions and context from prior sessions. Read them to understand what has already been done and what decisions were made.
3. **Read the relevant source files.** Depending on the task:
   - For data issues → read `scripts/<country>/process_*.R` first, then the `.qmd`
   - For report/visualization issues → read `reports/<report>.qmd` first
   - For structural issues → read `_quarto.yml`, `index.qmd`, this file
4. **Check git state.** Run `git status`, `git branch`, and `git log --oneline -10` to understand what branch you're on and what recent changes exist.
5. **Summarize your understanding** back to the user in 2-3 sentences before starting work.

## What this repo is

A collection of reproducible conservation analysis reports. Each report analyzes geospatial indicators (forest cover loss, burned area, etc.) for a specific geographic context using the [`mapme.biodiversity`](https://github.com/mapme-initiative/mapme.biodiversity) R package. Reports are rendered with [Quarto](https://quarto.org/) and published to GitHub Pages via the `docs/` folder.

## Repository structure

```
mapme.biodiversity.reports/
├── agents.md                    # THIS FILE — read first
├── _quarto.yml                  # Quarto website configuration
├── index.qmd                    # Homepage
├── about.qmd                    # About page
├── assets/custom.scss           # Shared styling
├── reports/                     # Quarto report source files (.qmd)
│   ├── threat_assessment_bolivia.qmd
│   ├── evaluation_laos_forest_cover.qmd
│   ├── forest_cover_india.qmd
│   └── references.bib
├── scripts/                     # R processing scripts (run before rendering)
│   ├── install_packages.R       # One-time package setup
│   ├── bolivia/
│   ├── laos/
│   └── india/
├── taskdescriptions/            # Task history per country (read for context)
│   ├── bolivia/
│   ├── lao/
│   └── india/
├── data/                        # All data (gitignored — not version controlled)
│   ├── shared/mapme_resources/  # Cached GFW/MODIS tiles (never delete)
│   ├── <country>/input/         # Raw input data
│   └── <country>/output/        # Processed CSVs and geopackages
└── docs/                        # Rendered HTML (GitHub Pages output)
```

## Development workflow

**Follow this workflow for every change, no exceptions.**

### 1. Branch

Create a new branch from the latest `main`:

```bash
git fetch origin main
git checkout -b YYYYMMDD-ShortDescription origin/main
```

Branch naming convention: `YYYYMMDD-ShortDescription` (e.g., `20260309-FixIndiaTableCalculations`). Use the current date.

### 2. Develop

Make your changes in the `.qmd` report and/or R scripts. Follow the conventions in this document.

### 3. Verify (MANDATORY — do not skip)

Before committing, run the **full verification protocol** described in the next section. This is not optional. Past bugs have shipped to production because verification was skipped or done superficially.

### 4. Render

```bash
# Render only the report you changed — never the full site
quarto render reports/<report_name>.qmd
```

Visually inspect the rendered HTML output. Check tables, chart axes, map layers, and hover labels.

### 5. Commit

Stage specific files (never `git add .` or `git add -A`):

```bash
git add reports/<file>.qmd docs/reports/<file>.html docs/search.json
# Add any other changed docs/ assets (CSS, JS libs, etc.)
git commit -m "Descriptive message of what and why"
```

### 6. Push

```bash
git push -u origin <branch-name>
```

Then inform the user so they can review and create a PR if needed.

---

## Numerical verification protocol

> **This section exists because a calculation bug shipped to production.** An agent was told to "check calculations" and reported that everything was correct, but period-level forest losses did not sum to the total loss because of an off-by-one error in time-period boundaries. The checks below are designed to catch exactly these kinds of errors.

After **every** data processing or wrangling step — in R scripts and QMD files — run these checks. Do not just read the code and reason about it. **Execute the checks in R and examine the actual output.**

### A. Arithmetic invariant checks (MOST IMPORTANT)

**Whenever you compute a breakdown of a total into parts, verify that the parts sum to the whole.** This is the single most important check and the one most often skipped.

```r
# Example: period losses must sum to total loss
village_check <- period_stats %>%
  group_by(vid) %>%
  summarise(sum_period_loss = sum(period_loss_ha)) %>%
  left_join(village_summary %>% select(vid, abs_loss), by = "vid") %>%
  mutate(diff = abs(sum_period_loss - abs_loss))

# This MUST be zero (or < 0.01 for floating point)
stopifnot(max(village_check$diff, na.rm = TRUE) < 0.01)
```

Apply this pattern to:
- Period losses summing to total loss (ha and %)
- Spatial aggregates (village totals = sum of pixel-level values)
- Any table where sub-columns should sum to a total column
- Percentage breakdowns that should sum to 100%

**If an invariant check fails, do not proceed. Investigate and fix the root cause.**

### B. Temporal boundary checks

When defining time periods from time-series data, **always verify there are no gaps or overlaps**:

```r
# The end value of period N must equal the start value of period N+1
# If using area_ha[year == Y] where Y represents state AFTER year Y's events:
#   Period "2011-2020" must START from the END point of period "2001-2010"
#   i.e., start = area_ha[year == 2010], NOT area_ha[year == 2011]
```

Specific rule for GFW data: `area_ha[year == Y]` = forest remaining **after** year Y's loss events. Therefore:
- To capture losses in years 2011-2020, use: `area[2010] - area[2020]`
- **NOT** `area[2011] - area[2020]` (this misses year 2011 losses)

### C. Group key uniqueness

```r
# Before group_by + summarise: verify key uniqueness
stopifnot(nrow(df) == n_distinct(df$key_column))
```

When grouping by composite keys, check that the combination is unique. Shared keys (e.g., multiple rows with `lgd_villagecode=0`) silently produce wrong summaries.

### D. Cross-check derived columns

Any column derived from another (e.g., `baseline_2001`, `rel_loss`) must be spot-checked:

```r
# Pick 3-5 rows and manually verify the calculation
sample_rows <- df %>% slice_sample(n = 5)
# Print input columns and derived columns side by side
# Verify with mental arithmetic or calculator
```

### E. Plausibility checks

```r
# After computing relative or annualized metrics:
summary(df$annual_rel_loss)
# Flag: values > 100% are physically impossible for annual forest loss
# Flag: negative loss values indicate a formula error
stopifnot(all(df$rel_loss >= 0, na.rm = TRUE))
```

### F. Join cardinality

```r
nrow_before <- nrow(df)
df <- df %>% left_join(other, by = "key")
# Must be equal (unless you expect row multiplication)
stopifnot(nrow(df) == nrow_before)
```

### G. NA propagation

```r
# After any transformation, check key columns for unexpected NAs
sapply(df %>% select(key_columns), function(x) sum(is.na(x)))
```

### H. Render and visual review

After all code changes, render the report and check:
- Do table columns sum correctly (spot-check 3-5 rows manually)?
- Are chart axes scaled reasonably (no extreme outliers distorting the view)?
- Do map layers align spatially?
- Do hover labels show correct information?

---

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
- **GFW temporal semantics**: `area_ha[year == Y]` = treecover2000 minus cumulative losses through year Y. This means year Y's losses are ALREADY subtracted from the year-Y observation. When building time periods, use contiguous boundaries (end of period N = start of period N+1) to avoid gaps.
- **Burned area processing**: Process protected areas individually when they span different MODIS tile subsets (see `scripts/bolivia/process_burned_area.R`).
- **CRS**: Always ensure input geometries are in EPSG:4326 before processing.

### Quarto reports

- Use `freeze: auto` in `_quarto.yml` so reports only re-render when source changes.
- Load pre-computed CSVs from `data/<country>/output/` — do not run heavy processing inside QMD files.
- Use `file.exists()` checks before loading optional output files.
- Visualizations use `leaflet` (interactive maps), `plotly` (charts), and `DT` (tables).

## What NOT to do

- Do not run `get_resources()` or `calc_indicators()` inside `.qmd` files.
- Do not delete `data/shared/mapme_resources/` — it caches large tile downloads.
- Do not commit files in `data/` (gitignored). Commit only scripts, `.qmd` reports, and rendered `docs/`.
- Do not render the full site (`quarto render`) when only updating one report — use `quarto render reports/<file>.qmd`.
- Do not skip the verification protocol. Ever. Even for "minor" changes. The period boundary bug was also a "minor" calculation.
- Do not just read code and conclude it is correct. Execute verification checks in R and examine actual output values.
