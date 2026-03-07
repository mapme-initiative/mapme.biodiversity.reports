# MAPME Biodiversity Reports

A collection of reproducible conservation analysis reports for protected areas and land-use interventions, built with [Quarto](https://quarto.org/) and the [mapme.biodiversity](https://github.com/mapme-initiative/mapme.biodiversity) R package.

## Available reports

| Report | Country | Indicators | Status |
|--------|---------|------------|--------|
| [Bolivia Threat Assessment](reports/threat_assessment_bolivia.qmd) | Bolivia | Forest cover loss, burned area | Published |
| [Laos Forest Cover Evaluation](reports/evaluation_laos_forest_cover.qmd) | Laos | Forest cover loss | Published |
| [India Forest Cover (Tripura)](reports/forest_cover_india.qmd) | India | Forest cover loss | Published |

## Repository structure

```
mapme.biodiversity.reports/
├── _quarto.yml               # Quarto website configuration
├── index.qmd / about.qmd    # Site pages
├── assets/custom.scss        # Shared styling
├── reports/                  # Quarto report files (.qmd)
├── scripts/                  # R processing scripts
│   ├── install_packages.R
│   ├── bolivia/
│   ├── laos/
│   └── india/
└── data/                     # All data (gitignored)
    ├── shared/mapme_resources/   # Cached GFW/MODIS tiles
    ├── bolivia/input/ + output/
    ├── laos/input/ + output/
    └── india/input/ + output/
```

> See [agents.md](agents.md) for detailed conventions and workflow guidance.

## Getting started

### Prerequisites

- R ≥ 4.2
- Quarto ≥ 1.3
- GDAL ≥ 3.7.0 (required for MCD64A1 burned area data)

### Step 1: Install R packages

```r
source("scripts/install_packages.R")
```

### Step 2: Run the processing script for your report

```r
# Bolivia
source("scripts/bolivia/process_forest_cover.R")
source("scripts/bolivia/process_burned_area.R")

# Laos
source("scripts/laos/process_forest_cover.R")

# India
source("scripts/india/process_forest_cover.R")
```

Processing downloads raster tiles from Global Forest Watch and MODIS and may take 30–90 minutes on first run. Subsequent runs reuse cached tiles.

### Step 3: Render

```bash
# Render the full website
quarto render

# Render a single report
quarto render reports/threat_assessment_bolivia.qmd

# Preview locally
quarto preview
```

### Step 4: Publish to GitHub Pages

The rendered HTML is written to `docs/`. GitHub Pages is configured to serve from `main:/docs`.

## macOS setup notes

The `mapme.biodiversity` package requires GDAL ≥ 3.7.0 for burned area data.

```bash
brew install gdal proj geos
```

Both `sf` and `terra` must use the same GDAL version. Verify in R:

```r
sf::sf_extSoftVersion()["GDAL"]   # Should match terra::gdal()
terra::gdal()
```

If `terra` shows an older version, reinstall from source:

```bash
GDAL_CONFIG=/usr/local/bin/gdal-config R -e 'install.packages("terra", type="source")'
```

### Environment variables (`~/.Renviron`)

```
PROJ_LIB=/usr/local/share/proj
GDAL_DATA=/usr/local/Cellar/gdal/3.10.2/share/gdal
```

### Known mapme.biodiversity quirks

- **Burned area batch processing**: Processing multiple areas at once fails when they span different MODIS tile subsets. Process individually (see `scripts/bolivia/process_burned_area.R`).
- **Resource accumulation**: `get_resources()` replaces rather than accumulates resources. Request all years in one call.
- **Tile cache**: Never delete `data/shared/mapme_resources/`; the package skips already-downloaded files.

## Data sources

| Dataset | Description | Source |
|---------|-------------|--------|
| GFW Treecover / Lossyear | Annual forest cover (GFC-2024-v1.12) | [Global Forest Watch](https://www.globalforestwatch.org/) |
| MCD64A1 | Monthly burned area (MODIS) | [NASA / Microsoft Planetary Computer](https://modis-fire.umd.edu/ba.html) |
| WDPA | Protected area boundaries | [Protected Planet](https://www.protectedplanet.net/) |

## License

Code: MIT License. Data: see original provider terms.

---

*Built with [mapme.biodiversity](https://github.com/mapme-initiative/mapme.biodiversity) and [Quarto](https://quarto.org/) · [MAPME Initiative](https://mapme-initiative.org)*
