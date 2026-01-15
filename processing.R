# =============================================================================
# Processing Script: Generate Input Data for Bolivia Threat Assessment
# =============================================================================
# Author: Updated by AI Assistant based on original work by Johannes Schielein
# Date: 2026-01-12
# Purpose: Generate forest cover loss and burned area statistics for 
#          Protected Areas in Bolivia using mapme.biodiversity package
# Period: 2000-2024
# =============================================================================

cat("\n")
cat("=============================================================================\n")
cat("  MAPME Biodiversity - Bolivia Threat Assessment Data Processing\n")
cat("=============================================================================\n")
cat("  Start time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")

# ----- Load Required Libraries -----
cat("[1/8] Loading required libraries...\n")

suppressPackageStartupMessages({
  library(mapme.biodiversity)
  library(sf)
  library(dplyr)
  library(tidyr)
})

cat("      ✓ Libraries loaded successfully\n")
cat("      Package version: mapme.biodiversity", as.character(packageVersion("mapme.biodiversity")), "\n\n")

# ----- Configuration -----
cat("[2/8] Setting up configuration...\n")

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

# ----- Define Bolivia WDPA IDs -----
# Case specific IDs for Bolivian protected areas
bol_wdpa_ids <- c(
  303891, 555592639, 555592671, 555592663, 555592664, 342481, 9308,
  342482, 342484, 555592677, 555592678, 555592685, 342466,
  555592641, 555592656, 555592600, 342494, 342495, 342496, 342497,
  342498, 555592646, 555592673, 555592608, 20037, 31, 2037, 303887,
  9779, 303884, 303894, 98183, 303885, 303883, 30, 342464, 35,
  342483, 555592593, 342484, 555592669, 342490, 555592668, 342465,
  555592608
)

# Remove duplicates
bol_wdpa_ids <- unique(bol_wdpa_ids)

# =============================================================================
# PART 1: Load Protected Areas from WDPA Geodatabase
# =============================================================================
cat("[3/8] Loading protected areas from WDPA geodatabase...\n")

# Load all Bolivia PAs from WDPA file geodatabase
wdpa_allPAs <- st_read(
  "data/wdpa.gdb",
  layer = "WDPA_WDOECM_poly_Jan2026_BOL",
  quiet = TRUE
)

cat("      ✓ Loaded WDPA geodatabase:", nrow(wdpa_allPAs), "features\n")

# Rename columns to standard names
wdpa_allPAs <- wdpa_allPAs %>%
  rename(
    WDPAID = SITE_ID,
    WDPA_PID = SITE_PID,
    ORIG_NAME = NAME
  )

# Filter for our target WDPA IDs
portfolio <- wdpa_allPAs %>%
  filter(WDPAID %in% bol_wdpa_ids)

cat("      ✓ Filtered to target areas:", nrow(portfolio), "features\n")

# Remove UNESCO-MAB Biosphere Reserves and Proposed areas
portfolio <- portfolio %>%
  filter(
    DESIG_ENG != "UNESCO-MAB Biosphere Reserve" | is.na(DESIG_ENG),
    STATUS != "Proposed" | is.na(STATUS)
  )

cat("      ✓ After filtering status:", nrow(portfolio), "features\n")

# Make geometries valid
portfolio <- st_make_valid(portfolio)

# Transform to WGS84 if needed
if (st_crs(portfolio)$epsg != 4326) {
  cat("      Transforming to EPSG:4326...\n")
  portfolio <- st_transform(portfolio, 4326)
}

cat("      ✓ Portfolio ready:", nrow(portfolio), "protected areas\n\n")

# =============================================================================
# PART 2: Load KfW Portfolio for Reference
# =============================================================================
cat("[4/8] Loading KfW portfolio for reference...\n")

portfolio_kfw <- read_sf("data/portfolio.gpkg")
portfolio_kfw <- portfolio_kfw %>%
  filter(grepl("BOL", country))

cat("      ✓ KfW portfolio has", nrow(portfolio_kfw), "Bolivia-related entries\n\n")

# =============================================================================
# PART 3: Get Forest Cover Resources
# =============================================================================
cat("[5/8] Downloading forest cover data (GFC-2024-v1.12)...\n")
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
# PART 4: Calculate Treecover Area Indicator
# =============================================================================
cat("[6/8] Calculating forest cover statistics...\n")
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

# Extract and save forest loss data
cat("      Extracting results...\n")

gfw_lossstats <- portfolio %>%
  st_drop_geometry() %>%
  select(WDPAID, WDPA_PID, ORIG_NAME, treecover_area) %>%
  unnest(treecover_area)

# Standardize column names
gfw_lossstats <- gfw_lossstats %>%
  mutate(
    year = as.integer(format(datetime, "%Y")),
    name = "area",
    value = value
  ) %>%
  select(WDPAID, WDPA_PID, ORIG_NAME, year, name, value)

# Calculate annual loss
gfw_loss <- gfw_lossstats %>%
  group_by(WDPAID, WDPA_PID, ORIG_NAME) %>%
  arrange(year) %>%
  mutate(
    loss_value = lag(value, 1) - value,
    name = "loss"
  ) %>%
  filter(!is.na(loss_value)) %>%
  mutate(value = loss_value) %>%
  select(-loss_value) %>%
  ungroup()

# Combine
gfw_lossstats_final <- bind_rows(gfw_lossstats, gfw_loss)

write.csv(
  gfw_lossstats_final,
  "data/bolivia_forest_loss_2000_2024.csv",
  row.names = FALSE
)

cat("      ✓ Saved: data/bolivia_forest_loss_2000_2024.csv\n\n")

# =============================================================================
# PART 5: Get Burned Area Resources (MODIS MCD64A1)
# =============================================================================
cat("[7/8] Downloading burned area data (MODIS MCD64A1)...\n")
cat("      This may take additional time...\n")

tryCatch({
  portfolio <- get_resources(
    portfolio,
    get_mcd64a1(years = analysis_years)
  )
  
  cat("      ✓ MCD64A1 resources downloaded\n")
  
  # Calculate burned area
  cat("      Calculating burned area statistics...\n")
  
  portfolio <- calc_indicators(
    portfolio,
    calc_burned_area(
      engine = "zonal",
      years = analysis_years
    )
  )
  
  cat("      ✓ Burned area calculated\n")
  
  # Extract and save burned area data
  burned_area_stats <- portfolio %>%
    st_drop_geometry() %>%
    select(WDPAID, WDPA_PID, ORIG_NAME, burned_area) %>%
    unnest(burned_area)
  
  # Annual burned area
  burned_annual <- burned_area_stats %>%
    mutate(year = as.integer(format(datetime, "%Y"))) %>%
    group_by(WDPAID, year) %>%
    summarise(
      burned_area_ha = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    rename(wdpa_id = WDPAID)
  
  # Total burned area
  burned_total <- burned_annual %>%
    group_by(wdpa_id) %>%
    summarise(
      total_burned_area_ha = sum(burned_area_ha, na.rm = TRUE),
      .groups = "drop"
    )
  
  write.csv(burned_annual, "data/bolivia_burned_area_annual_2000_2024.csv", row.names = FALSE)
  write.csv(burned_total, "data/bolivia_burned_area_total_2000_2024.csv", row.names = FALSE)
  
  cat("      ✓ Saved: data/bolivia_burned_area_annual_2000_2024.csv\n")
  cat("      ✓ Saved: data/bolivia_burned_area_total_2000_2024.csv\n")
  
}, error = function(e) {
  cat("      ⚠ Warning: Burned area processing failed:", conditionMessage(e), "\n")
  cat("      Continuing without burned area data...\n")
})

cat("\n")

# =============================================================================
# PART 6: Save Processed Portfolio and Summary
# =============================================================================
cat("[8/8] Saving processed portfolio...\n")

write_portfolio(
  x = portfolio,
  dsn = "data/bolivia_portfolio_processed.gpkg",
  overwrite = TRUE
)

writeLines(capture.output(sessionInfo()), "data/processing_session_info.txt")

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
cat("  1. data/bolivia_forest_loss_2000_2024.csv\n")
cat("  2. data/bolivia_burned_area_annual_2000_2024.csv\n")
cat("  3. data/bolivia_burned_area_total_2000_2024.csv\n")
cat("  4. data/bolivia_portfolio_processed.gpkg\n")
cat("  5. data/processing_session_info.txt\n\n")

cat("Summary:\n")
cat("  - Protected areas:", nrow(portfolio), "\n")
cat("  - Analysis period:", min(analysis_years), "-", max(analysis_years), "\n")
cat("  - GFW Version: GFC-2024-v1.12\n\n")
