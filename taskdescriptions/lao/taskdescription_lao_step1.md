# Task Description: Laos Protected Areas Evaluation Report - Step 1

## Repository Context

This repository (`mapme.biodiversity.reports`) contains Quarto-based reports for analyzing environmental threats and forest dynamics in protected areas. The project uses:

- **Quarto** for dynamic report generation (HTML output for GitHub Pages)
- **R** programming language for data processing and analysis
- **mapme.biodiversity** R package for geospatial data acquisition (GFW forest cover loss, MODIS burned area)
- **sf** for spatial data handling
- **leaflet** for interactive maps
- **ggplot2/plotly** for visualizations
- **DT** for interactive tables

### Key Files to Understand

Before starting, read these files to understand the structure and approach:

1. **`reports/threat_assessment_bolivia.qmd`**: 
   - Reference implementation of a threat assessment report
   - Shows how to structure sections, load data, create maps, generate plots
   - **Note**: This Laos report should be framed as an **evaluation report**, not a threat assessment
   - Use similar structure but adapt language and framing for evaluation context

2. **`processing.R`**: 
   - Shows how to process forest cover loss data using `mapme.biodiversity`
   - Uses `get_gfw_treecover()` and `get_gfw_lossyear()` to download GFW data
   - Uses `calc_treecover_area()` to calculate annual forest cover statistics
   - Processes data for 2000-2024 period

3. **`README.md`**: 
   - Repository structure, setup instructions, technical requirements
   - Important: GDAL version requirements, macOS setup notes. Everything is alreay installed so it might be less relevant. 

4. **`_quarto.yml`**: 
   - Quarto project configuration
   - Output directory set to `docs/` for GitHub Pages

### Data Structure

- **Protected Areas Data**: `data/wdpa_lao.gdb` (File Geodatabase)
  - Layer: `WDPA_WDOECM_poly_Feb2026_LAO` (30 polygon features)
  - Contains all protected areas in Laos
  - Filter for the 4 target areas using WDPA IDs (see below)

## Task Overview

Generate an **evaluation report** for the evaluation department analyzing forest cover development in 4 protected areas in Laos. The report should focus on **forest cover loss only** (no burned area analysis). The comparative analysis with all Lao PAs vs KfW-supported areas should be placed in the **last section** of the report.

### Target Protected Areas

| Protected Area Name | Area (km²) | WDPA ID (Protected Planet) |
|---------------------|------------|----------------------------|
| Nam Kan | 1,360 | 71253 |
| Nam Ha | 2,224 | 555756396 / 71252 |
| Hin Nam No | 941 | 555703744 |
| Kounxe Nongma | 538 | 555703750 |

**Note**: Nam Ha has two WDPA IDs. Check which one is correct in the GDB or use both if they represent different designations but make this very clear in the report. 

## Specific Requirements

### 1. Data Processing

- [ ] **Download shapefiles of 4 protected areas**
  - Load from `data/wdpa_lao.gdb` layer `WDPA_WDOECM_poly_Feb2026_LAO`
  - Filter by WDPA IDs: `71253, 555756396, 71252, 555703744, 555703750`
  - Verify geometry validity and transform to WGS84 (EPSG:4326) if needed

- [ ] **Process forest cover data**
  - Use `mapme.biodiversity` package to download GFW data:
    - `get_gfw_treecover(version = "GFC-2024-v1.12")`
    - `get_gfw_lossyear(version = "GFC-2024-v1.12")`
  - Calculate annual forest cover area using `calc_treecover_area()` for years 2000-present
  - Save processed data to CSV: `data/laos_forest_cover_2000_2024.csv`
  - Format: columns should include `WDPAID`, `ORIG_NAME`, `year`, `area_ha` (forest cover), `loss_ha` (annual loss)

### 2. Excel Summary Table

- [ ] **Create summary table**: Forest cover per year per protected area (2000-present)
  - Columns: Protected Area Name, Year, Forest Cover (ha), Annual Loss (ha), Cumulative Loss (ha) for the years 2009-2013, 2014-2018 and 2019-2023
  - Include all 4 areas
  - Export as CSV (can be opened in Excel)
  - Also include as interactive DT table in the Quarto report

### 3. Required Graphs

- [ ] **Graph 1**: Cumulative deforestation (2009-2013) for each of the 4 PAs
  - X-axis: Year (2009, 2010, 2011, 2012, 2013)
  - Y-axis: Cumulative forest loss (ha)
  - One line per PA, clearly labeled
  - Use `ggplot2` with `plotly` for interactivity if possible

- [ ] **Graph 2**: Cumulative deforestation (2014-2018) for each of the 4 PAs
  - Same format as Graph 1
  - Years: 2014, 2015, 2016, 2017, 2018

- [ ] **Graph 3**: Cumulative deforestation (2019-2023) for each of the 4 PAs
  - Same format as Graph 1
  - Years: 2019, 2020, 2021, 2022, 2023

**Note**: "Cumulative deforestation" means the total loss accumulated from the start of each period (e.g., for 2009-2013, show cumulative loss starting from 2009 baseline).

### 4. Descriptive Statements

- [ ] **Prepare descriptive statements** about deforestation development:
  - Compare deforestation rates **before and after project start**. Before is likely 2009-2013, during is 2014-2018, after is 2019-2023... make this assumption explicit. 
  - Identify which areas show increasing/decreasing trends
  - Highlight any notable patterns or outliers
  - Base statements on empirical data from the analyses
  - Frame in evaluation context (supporting evaluation of forest stock development)

### 5. Comparative Analysis (Last Section)

- [ ] **Compare 4 target areas with all Lao PAs**
  - Load all protected areas from `data/wdpa_lao.gdb`
  - Process forest cover loss for all Lao PAs (or use summary statistics if processing all is too time-consuming)
  - Create comparative visualizations (boxplots, bar charts, etc.)
  - Highlight how the 4 target areas compare to the national average

- [ ] **Compare with KfW-supported areas** (if data available)
  - Load KfW portfolio from `data/portfolio.gpkg`
  - Filter for Laos entries
  - Compare forest cover loss trends between KfW-supported areas and the 4 target areas
  - Discuss implications for evaluation

## Report Structure and Formatting

### Report Title and Framing

- **Title**: Should reflect evaluation purpose, e.g., "Evaluation of Forest Cover Development in Protected Areas in Laos" or similar
- **Framing**: Use evaluation language throughout:
  - "Evaluation of forest cover development"
  - "Assessment of conservation outcomes"
  - "Analysis of forest cover trends"
  - Avoid "threat assessment" terminology

### Suggested Report Sections

1. **Introduction**
   - Background on the 4 protected areas
   - Purpose of the evaluation
   - Data sources and methodology

2. **Analyzed Protected Areas**
   - Table with key information about the 4 areas
   - Include: Name, WDPA ID, Area (ha), Designation, Status, etc.

3. **Forest Cover Development (2000-Present)**
   - Summary table (Excel-compatible CSV)
   - Overall trends description

4. **Temporal Analysis of Deforestation for the project period**
   - Graph 1: Cumulative deforestation (2009-2013)
   - Graph 2: Cumulative deforestation (2014-2018)
   - Graph 3: Cumulative deforestation (2019-2023)
   - Interpretation of trends before/after project start

5. **Descriptive Analysis**
   - Detailed statements about deforestation development
   - Comparison of periods
   - Identification of most/least affected areas

6. **Comparative Context** (Last Section)
   - Comparison with all Lao protected areas
   - Comparison with KfW-supported areas (if available)
   - Discussion of relative performance

7. **Conclusions and Recommendations**
   - Summary of findings
   - Evaluation conclusions
   - Recommendations for future monitoring

### Visual Style

- Follow the style from `threat_assessment_bolivia.qmd`:
  - Interactive maps using `leaflet`
  - Interactive plots using `plotly`
  - Clean, professional formatting
  - Consistent color schemes
  - Map width: 80% with light grey border (if maps are included)

### Technical Implementation Notes

1. **Data Processing Script**
   - Create `process_laos_forest_cover.R` similar to `processing.R`
   - Use `mapme.biodiversity` workflow:
     ```r
     library(mapme.biodiversity)
     library(sf)
     library(dplyr)
     
     # Load PAs
     wdpa_lao <- st_read("data/wdpa_lao.gdb", layer = "WDPA_WDOECM_poly_Feb2026_LAO")
     
     # Filter for target areas
     target_ids <- c(71253, 555756396, 71252, 555703744, 555703750)
     portfolio <- wdpa_lao %>% filter(WDPAID %in% target_ids)
     
     # Get resources
     portfolio <- get_resources(
       portfolio,
       get_gfw_treecover(version = "GFC-2024-v1.12"),
       get_gfw_lossyear(version = "GFC-2024-v1.12")
     )
     
     # Calculate indicators
     portfolio <- calc_indicators(
       portfolio,
       calc_treecover_area(years = 2000:2024, min_cover = 10, min_size = 1)
     )
     
     # Extract and save results
     # ... (see processing.R for details)
     ```

2. **Quarto Report File**
   - Create `reports/evaluation_laos_forest_cover.qmd`
   - Follow structure of `threat_assessment_bolivia.qmd` but adapt for evaluation context
   - Use similar chunk structure and code organization

3. **Data Files**
   - Save processed data to `data/laos_forest_cover_2000_2024.csv`
   - Format: `WDPAID`, `ORIG_NAME`, `year`, `area_ha`, `loss_ha`, `cumulative_loss_ha`

## Important Considerations

1. **Project Start Date**: The requester mentions "before and after the start of the project" but doesn't specify the exact project start date. You may need to:
   - Check if there's documentation about project start dates
   - Use a reasonable assumption (e.g., 2014 as a common project start year)
   - Or analyze multiple potential breakpoints

2. **Cumulative Deforestation Calculation**:
   - For each period (2009-2013, 2014-2018, 2019-2023), calculate cumulative loss from the start of that period
   - Example: For 2009-2013, show cumulative loss from 2009 baseline (not from 2000)

3. **Nam Ha WDPA ID Issue**:
   - Two IDs listed: `555756396` and `71252`
   - Check which one exists in the GDB
   - If both exist, determine which is the correct one or include both if they represent different designations

4. **Data Availability**:
   - GFW data is available through 2024 (GFC-2024-v1.12)
   - Ensure all calculations use consistent data version

5. **Evaluation Context**:
   - Frame all findings in terms of evaluation of forest stock development
   - Focus on outcomes and trends rather than threats
   - Use language appropriate for evaluation reports

## Output Files Expected

1. **Processing Script**: `process_laos_forest_cover.R`
2. **Processed Data**: `data/laos_forest_cover_2000_2024.csv`
3. **Summary Table**: `data/laos_forest_cover_summary.csv` (Excel-compatible)
4. **Quarto Report**: `reports/evaluation_laos_forest_cover.qmd`
5. **Rendered HTML**: `docs/reports/evaluation_laos_forest_cover.html` (after rendering)

## Next Steps After Implementation

1. Render the report: `quarto render reports/evaluation_laos_forest_cover.qmd`
2. Review the HTML output locally
3. Verify all requirements are met
4. Check that graphs show cumulative deforestation correctly
5. Ensure descriptive statements are data-driven and accurate
6. Commit changes to Git repository

---

**Note**: This task description should be comprehensive enough to allow implementation in a fresh context window. All necessary context, file locations, technical details, and requirements are included above.

