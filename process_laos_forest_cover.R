# =============================================================================
# Processing Script: Generate Forest Cover Data for Laos Protected Areas
# =============================================================================
# Author: Generated for Laos Evaluation Report
# Date: 2026-01-12
# Purpose: Generate forest cover loss statistics for 4 Protected Areas in Laos
#          using mapme.biodiversity package
# Period: 2000-2024
# =============================================================================

cat("\n")
cat("=============================================================================\n")
cat("  MAPME Biodiversity - Laos Forest Cover Evaluation Data Processing\n")
cat("=============================================================================\n")
cat("  Start time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")

# ----- Load Required Libraries -----
cat("[1/7] Loading required libraries...\n")

suppressPackageStartupMessages({
  library(mapme.biodiversity)
  library(sf)
  library(dplyr)
  library(tidyr)
})

cat("      ✓ Libraries loaded successfully\n")
cat("      Package version: mapme.biodiversity", as.character(packageVersion("mapme.biodiversity")), "\n\n")

# ----- Configuration -----
cat("[2/7] Setting up configuration...\n")

# Set output directory for downloaded resources
output_dir <- file.path(getwd(), "data", "mapme_resources")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Configure mapme.biodiversity options
mapme_options(
  outdir = output_dir,
  verbose = TRUE
)

# Analysis years - GFC-2024-v1.12 provides data through 2024
analysis_years <- 2000:2024

cat("      ✓ Output directory:", output_dir, "\n")
cat("      ✓ Analysis period:", min(analysis_years), "-", max(analysis_years), "\n\n")

# ----- Define Laos WDPA IDs -----
# Target protected areas for evaluation
# Nam Kan: 71253
# Nam Ha: 555756396 / 71252 (check which exists)
# Hin Nam No: 555703744
# Kounxe Nongma: 555703750
target_wdpa_ids <- c(71253, 555756396, 71252, 555703744, 555703750)

cat("      ✓ Target WDPA IDs:", paste(target_wdpa_ids, collapse = ", "), "\n\n")

# =============================================================================
# PART 1: Load Protected Areas from WDPA Geodatabase
# =============================================================================
cat("[3/7] Loading protected areas from WDPA geodatabase...\n")

# Load all Laos PAs from WDPA file geodatabase
wdpa_lao <- st_read(
  "data/wdpa_lao.gdb",
  layer = "WDPA_WDOECM_poly_Feb2026_LAO",
  quiet = TRUE
)

cat("      ✓ Loaded WDPA geodatabase:", nrow(wdpa_lao), "features\n")

# Check column names
cat("      Available columns:", paste(head(names(wdpa_lao), 10), collapse = ", "), "...\n")

# Check which WDPA IDs exist in the database
available_ids <- unique(wdpa_lao$WDPAID)
cat("      Available WDPA IDs in database:", length(available_ids), "total\n")

# Check which target IDs are present
found_ids <- target_wdpa_ids[target_wdpa_ids %in% available_ids]
missing_ids <- target_wdpa_ids[!target_wdpa_ids %in% available_ids]

cat("      ✓ Found target IDs:", paste(found_ids, collapse = ", "), "\n")
if (length(missing_ids) > 0) {
  cat("      ⚠ Missing IDs:", paste(missing_ids, collapse = ", "), "\n")
}

# Rename columns to standard names (check actual column names first)
# Common column names in WDPA: SITE_ID, WDPAID, NAME, ORIG_NAME
if ("SITE_ID" %in% names(wdpa_lao)) {
  wdpa_lao <- wdpa_lao %>%
    rename(WDPAID = SITE_ID)
}

if ("NAME" %in% names(wdpa_lao) && !"ORIG_NAME" %in% names(wdpa_lao)) {
  wdpa_lao <- wdpa_lao %>%
    rename(ORIG_NAME = NAME)
}

# Filter for our target WDPA IDs
portfolio <- wdpa_lao %>%
  filter(WDPAID %in% target_wdpa_ids)

cat("      ✓ Filtered to target areas:", nrow(portfolio), "features\n")

# Display which areas were found
if (nrow(portfolio) > 0) {
  cat("      Found protected areas:\n")
  for (i in 1:nrow(portfolio)) {
    cat("        -", portfolio$ORIG_NAME[i], "(WDPAID:", portfolio$WDPAID[i], ")\n")
  }
}

# Make geometries valid
portfolio <- st_make_valid(portfolio)

# Transform to WGS84 if needed
if (st_crs(portfolio)$epsg != 4326) {
  cat("      Transforming to EPSG:4326...\n")
  portfolio <- st_transform(portfolio, 4326)
}

cat("      ✓ Portfolio ready:", nrow(portfolio), "protected areas\n\n")

# =============================================================================
# PART 2: Get Forest Cover Resources
# =============================================================================
cat("[4/7] Downloading forest cover data (GFC-2024-v1.12)...\n")
cat("      This may take 30-60 minutes depending on your connection...\n")
cat("      Progress:\n")

# Get GFW treecover and lossyear resources
portfolio <- get_resources(
  portfolio,
  get_gfw_treecover(version = "GFC-2024-v1.12"),
  get_gfw_lossyear(version = "GFC-2024-v1.12")
)

cat("      ✓ GFW resources downloaded\n\n")

# =============================================================================
# PART 3: Calculate Treecover Area Indicator
# =============================================================================
cat("[5/7] Calculating forest cover statistics...\n")
cat("      Processing", nrow(portfolio), "protected areas...\n")

portfolio <- calc_indicators(
  portfolio,
  calc_treecover_area(
    years = analysis_years,
    min_cover = 10,
    min_size = 1
  )
)

cat("      ✓ Treecover area calculated\n")

# Extract and save forest cover data
cat("      Extracting results...\n")

gfw_stats <- portfolio %>%
  st_drop_geometry() %>%
  select(WDPAID, ORIG_NAME, treecover_area) %>%
  unnest(treecover_area)

# Standardize column names and calculate annual loss
gfw_stats <- gfw_stats %>%
  mutate(
    year = as.integer(format(datetime, "%Y")),
    area_ha = value
  ) %>%
  select(WDPAID, ORIG_NAME, year, area_ha) %>%
  arrange(WDPAID, year)

# Calculate annual loss (loss = previous year area - current year area)
gfw_stats <- gfw_stats %>%
  group_by(WDPAID, ORIG_NAME) %>%
  arrange(year) %>%
  mutate(
    loss_ha = lag(area_ha, 1) - area_ha,
    loss_ha = ifelse(is.na(loss_ha), 0, loss_ha),
    loss_ha = ifelse(loss_ha < 0, 0, loss_ha)  # Loss cannot be negative
  ) %>%
  ungroup()

# Calculate cumulative loss from 2000 baseline
gfw_stats <- gfw_stats %>%
  group_by(WDPAID, ORIG_NAME) %>%
  arrange(year) %>%
  mutate(
    baseline_2000 = first(area_ha),
    cumulative_loss_ha = baseline_2000 - area_ha
  ) %>%
  ungroup()

# Save full dataset
write.csv(
  gfw_stats,
  "data/laos_forest_cover_2000_2024.csv",
  row.names = FALSE
)

cat("      ✓ Saved: data/laos_forest_cover_2000_2024.csv\n\n")

# =============================================================================
# PART 4: Create Summary Table for Excel
# =============================================================================
cat("[6/7] Creating summary table...\n")

# Create summary with cumulative loss for specific periods
summary_table <- gfw_stats %>%
  select(WDPAID, ORIG_NAME, year, area_ha, loss_ha, cumulative_loss_ha) %>%
  # Calculate cumulative loss for each period from period start
  group_by(WDPAID, ORIG_NAME) %>%
  mutate(
    # Get baseline values for each period
    baseline_2009 = ifelse(any(year == 2009), area_ha[year == 2009][1], NA),
    baseline_2014 = ifelse(any(year == 2014), area_ha[year == 2014][1], NA),
    baseline_2019 = ifelse(any(year == 2019), area_ha[year == 2019][1], NA),
    
    # Cumulative loss from 2009 baseline (for 2009-2013 period)
    cum_loss_2009_2013 = ifelse(
      year >= 2009 & year <= 2013 & !is.na(baseline_2009),
      baseline_2009 - area_ha,
      NA
    ),
    # Cumulative loss from 2014 baseline (for 2014-2018 period)
    cum_loss_2014_2018 = ifelse(
      year >= 2014 & year <= 2018 & !is.na(baseline_2014),
      baseline_2014 - area_ha,
      NA
    ),
    # Cumulative loss from 2019 baseline (for 2019-2023 period)
    cum_loss_2019_2023 = ifelse(
      year >= 2019 & year <= 2023 & !is.na(baseline_2019),
      baseline_2019 - area_ha,
      NA
    )
  ) %>%
  ungroup() %>%
  # Rename columns for Excel compatibility
  rename(
    `Protected Area Name` = ORIG_NAME,
    `Year` = year,
    `Forest Cover (ha)` = area_ha,
    `Annual Loss (ha)` = loss_ha,
    `Cumulative Loss 2009-2013 (ha)` = cum_loss_2009_2013,
    `Cumulative Loss 2014-2018 (ha)` = cum_loss_2014_2018,
    `Cumulative Loss 2019-2023 (ha)` = cum_loss_2019_2023
  ) %>%
  select(-WDPAID, -cumulative_loss_ha, -baseline_2009, -baseline_2014, -baseline_2019)  # Remove internal columns

# Save summary table
write.csv(
  summary_table,
  "data/laos_forest_cover_summary.csv",
  row.names = FALSE
)

cat("      ✓ Saved: data/laos_forest_cover_summary.csv\n")
cat("      Summary table has", nrow(summary_table), "rows\n\n")

# =============================================================================
# PART 5: Save Processed Portfolio and Summary
# =============================================================================
cat("[7/7] Saving processed portfolio...\n")

write_portfolio(
  x = portfolio,
  dsn = "data/laos_portfolio_processed.gpkg",
  overwrite = TRUE
)

writeLines(capture.output(sessionInfo()), "data/laos_processing_session_info.txt")

cat("      ✓ Portfolio saved\n")
cat("      ✓ Session info saved\n\n")

# =============================================================================
# Final Summary
# =============================================================================
cat("=============================================================================\n")
cat("  Processing Complete!\n")
cat("=============================================================================\n")
cat("  End time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")

cat("Generated files:\n")
cat("  1. data/laos_forest_cover_2000_2024.csv\n")
cat("  2. data/laos_forest_cover_summary.csv\n")
cat("  3. data/laos_portfolio_processed.gpkg\n")
cat("  4. data/laos_processing_session_info.txt\n\n")

cat("Summary:\n")
cat("  - Protected areas processed:", nrow(portfolio), "\n")
cat("  - Analysis period:", min(analysis_years), "-", max(analysis_years), "\n")
cat("  - GFW Version: GFC-2024-v1.12\n")
cat("  - Total years of data:", length(analysis_years), "\n\n")

cat("Next steps:\n")
cat("  1. Review the generated CSV files\n")
cat("  2. Render the Quarto report: quarto render reports/evaluation_laos_forest_cover.qmd\n\n")

