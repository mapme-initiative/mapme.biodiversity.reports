# MAPME Biodiversity Reports

This repository contains threat assessment reports and conservation analyses for protected areas, built using [Quarto](https://quarto.org/) and the [mapme.biodiversity](https://github.com/mapme-initiative/mapme.biodiversity) R package.

## 📋 Overview

The project provides reproducible analyses of environmental threats to protected areas, including:

- **Forest Cover Loss**: Annual deforestation tracking using Global Forest Watch data
- **Burned Areas**: Fire impact assessment using MODIS MCD64A1 burned area product
- **Interactive Visualizations**: Maps and charts for exploring the data

## 📁 Repository Structure

```
mapme.biodiversity.reports/
├── _quarto.yml              # Quarto project configuration
├── index.qmd                # Homepage
├── about.qmd                # About page
├── processing.R             # Data processing script (run first!)
├── reports/
│   └── threat_assessment_bolivia.qmd  # Bolivia analysis report
├── data/
│   ├── portfolio.gpkg       # KfW/GIZ supported protected areas
│   └── wdpa.gdb/            # WDPA file geodatabase
├── assets/
│   └── custom.scss          # Custom styling
├── docs/                    # Generated HTML output (for GitHub Pages)
└── README.md
```

## 🚀 Getting Started

### Prerequisites

1. **R** (version 4.2 or higher)
2. **Quarto** (version 1.3 or higher) - [Install Quarto](https://quarto.org/docs/get-started/)
3. Required R packages:

```r
# Core packages
install.packages(c(
  "tidyverse",
  "sf",
  "leaflet",
  "leaflet.extras",
  "leaflet.extras2",
  "plotly",
  "DT",
  "RColorBrewer",
  "ggsci",
  "scales",
  "htmltools",
  "future",
  "progressr"
))

# mapme.biodiversity package
install.packages("mapme.biodiversity")

# Or development version
# remotes::install_github("mapme-initiative/mapme.biodiversity")
```

### Step 1: Process the Data

Before rendering reports, you need to generate the input statistics:

```r
# This script downloads data and calculates indicators
# It may take several hours depending on your internet connection
source("processing.R")
```

**Note**: The processing script:
- Downloads Global Forest Watch treecover and lossyear data
- Downloads MODIS MCD64A1 burned area data
- Calculates indicators for all protected areas
- Saves results to the `data/` folder

### Step 2: Render the Website

```bash
# Render the entire website
quarto render

# Or render a single report
quarto render reports/threat_assessment_bolivia.qmd

# Preview locally
quarto preview
```

### Step 3: Deploy to GitHub Pages

The rendered HTML files are output to the `docs/` folder. To publish:

1. Enable GitHub Pages in your repository settings
2. Set source to "Deploy from a branch"
3. Select the `main` branch and `/docs` folder
4. Commit and push your changes

## ⚙️ Technical Setup & Troubleshooting

### macOS Setup Requirements

The `mapme.biodiversity` package requires specific system dependencies and configurations on macOS. Here are critical setup requirements learned through extensive troubleshooting:

#### 1. GDAL Version Compatibility (CRITICAL)

**Issue**: Both `sf` and `terra` packages must use the same GDAL version ≥ 3.7.0
- MCD64A1 data from Microsoft Planetary Computer requires GDAL ≥ 3.7.0 for URL signing (`pc_url_signing`)
- Older GDAL versions cause HTTP 409 errors or "unknown option(s): others" errors

**Solution**:
```bash
# Install system GDAL via Homebrew
brew install gdal proj geos

# Check versions
gdal-config --version  # Should be ≥ 3.7.0

# In R, verify both packages use the same GDAL
sf::sf_extSoftVersion()["GDAL"]
terra::gdal()

# If terra shows older version, reinstall from source
export PATH="/usr/local/bin:$PATH"
export GDAL_CONFIG=/usr/local/bin/gdal-config
R -e 'install.packages("Rcpp")' # Update Rcpp first
R -e 'install.packages("terra", type="source")'
```

#### 2. R Package Compilation on macOS

**Issue**: `sf` package compilation may fail with "cmath file not found" error

**Solution**: Create `~/.R/Makevars` with proper SDK and compiler flags:
```makefile
# ~/.R/Makevars for macOS
SDK = /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk

CC = /usr/bin/clang -isysroot $(SDK)
CXX = /usr/bin/clang++ -isysroot $(SDK) -I$(SDK)/usr/include/c++/v1 -stdlib=libc++
CXX11 = /usr/bin/clang++ -isysroot $(SDK) -I$(SDK)/usr/include/c++/v1 -stdlib=libc++ -std=gnu++11
CXX14 = /usr/bin/clang++ -isysroot $(SDK) -I$(SDK)/usr/include/c++/v1 -stdlib=libc++ -std=gnu++14
CXX17 = /usr/bin/clang++ -isysroot $(SDK) -I$(SDK)/usr/include/c++/v1 -stdlib=libc++ -std=gnu++17

CPPFLAGS = -I/usr/local/include -I$(SDK)/usr/include
LDFLAGS = -L/usr/local/lib
```

#### 3. Environment Variables

**Issue**: PROJ and GDAL need to find their data files

**Solution**: Create `~/.Renviron`:
```bash
# ~/.Renviron
PROJ_LIB=/usr/local/share/proj
GDAL_DATA=/usr/local/Cellar/gdal/3.10.2/share/gdal  # Adjust version as needed
```

Or set in each R session:
```r
Sys.setenv(
  PROJ_LIB = "/usr/local/share/proj",
  GDAL_DATA = "/usr/local/Cellar/gdal/3.10.2/share/gdal"
)
```

#### 4. Rate Limiting (Microsoft Planetary Computer)

**Issue**: MCD64A1 downloads may fail with rate limiting errors

**Solution**: Set GDAL HTTP retry parameters:
```r
Sys.setenv(
  GDAL_HTTP_MAX_RETRY = "10",
  GDAL_HTTP_RETRY_DELAY = "30"
)
```

#### 5. mapme.biodiversity Processing Quirks

**Known Issues**:
1. **Batch processing limitation**: Processing multiple areas at once fails with "Did not find equal number of tiles per timestep" when areas overlap with different MODIS tile subsets
   - **Solution**: Process areas individually (see `process_burned_area.R`)

2. **Resource accumulation**: Calling `get_resources()` multiple times with different years **replaces** rather than accumulates resources
   - **Solution**: Request all years in a single call: `get_mcd64a1(years = 2015:2022)`

3. **Caching behavior**: The package automatically caches downloaded tiles in `outdir`
   - **Best practice**: Never delete cached resources; the package skips existing files

### Reproducibility Recommendations

To make this analysis more reproducible across different environments:

#### Option 1: Docker Container (Recommended)
```dockerfile
# Example Dockerfile structure
FROM rocker/geospatial:4.3
RUN apt-get update && apt-get install -y \
    gdal-bin \
    libgdal-dev \
    libproj-dev \
    libgeos-dev
RUN R -e "install.packages('mapme.biodiversity')"
# ... additional setup
```

#### Option 2: renv for Package Management
```r
# Initialize renv in project
renv::init()
renv::snapshot()  # Capture package versions
# Commit renv.lock to version control
```

#### Option 3: Conda Environment
```yaml
# environment.yml
name: mapme-analysis
channels:
  - conda-forge
dependencies:
  - r-base>=4.2
  - gdal>=3.7
  - proj
  - geos
  - r-sf
  - r-terra
```

### Quick Verification Script

Run this to verify your setup:
```r
# Verify GDAL versions match
cat("sf GDAL:", sf::sf_extSoftVersion()["GDAL"], "\n")
cat("terra GDAL:", terra::gdal(), "\n")
stopifnot(sf::sf_extSoftVersion()["GDAL"] == terra::gdal())

# Verify GDAL >= 3.7.0
gdal_version <- as.numeric(strsplit(sf::sf_extSoftVersion()["GDAL"], "\\.")[[1]][1:2])
stopifnot(gdal_version[1] >= 3 && gdal_version[2] >= 7)

# Verify PROJ database
stopifnot(file.exists(file.path(Sys.getenv("PROJ_LIB"), "proj.db")))

cat("✓ Setup verified successfully!\n")
```

## 📊 Available Reports

### Bolivia Threat Assessment (2000-2024)

Analysis of protected areas in the Bolivian Amazon Basin:

- **45 protected areas** analyzed
- **Forest cover loss trends** from Global Forest Watch
- **Burned area dynamics** from MODIS MCD64A1
- Interactive maps and visualizations

[View the Report →](reports/threat_assessment_bolivia.qmd)

## 🔧 Data Sources

| Dataset | Description | Source |
|---------|-------------|--------|
| GFW Treecover | Tree canopy cover in year 2000 | [Global Forest Watch](https://www.globalforestwatch.org/) |
| GFW Lossyear | Year of forest loss event | [Global Forest Watch](https://www.globalforestwatch.org/) |
| MCD64A1 | Monthly burned area | [NASA MODIS](https://modis-fire.umd.edu/ba.html) |
| WDPA | Protected area boundaries | [Protected Planet](https://www.protectedplanet.net/) |

## 🔄 Updating the Analysis

To update the analysis with new data:

1. Download updated WDPA data and place in `data/wdpa.gdb/`
2. Update the portfolio file if needed (`data/portfolio.gpkg`)
3. Re-run `processing.R`
4. Re-render the Quarto documents

## 📚 Key Changes from Previous Version

This updated version includes several improvements:

1. **Extended time period**: Analysis now covers 2000-2024 (previously 2000-2021)
2. **Burned area instead of fire counts**: Using MODIS MCD64A1 burned area (hectares) instead of active fire counts for more accurate fire impact assessment
3. **Modern Quarto format**: Migrated from workflowr/Rmd to Quarto for better maintainability and GitHub Pages integration
4. **Updated packages**: Uses current mapme.biodiversity API

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📜 License

This project is open source. Code is available under the MIT License. Please refer to original data providers for data licensing terms.

## 📧 Contact

- **GitHub Issues**: For bugs and feature requests
- **MAPME Initiative**: [mapme-initiative.org](https://mapme-initiative.org)

---

*Built with ❤️ using [mapme.biodiversity](https://github.com/mapme-initiative/mapme.biodiversity) and [Quarto](https://quarto.org/)*

