# =============================================================================
# Process Burned Area Data
# =============================================================================
# This script processes MCD64A1 burned area data for Bolivia's protected areas
# 
# The mapme.biodiversity package handles caching automatically:
# - Downloaded tiles are stored in outdir
# - Existing tiles are reused (not re-downloaded)
#
# NOTE: Processing areas individually because batch processing fails when
# different areas overlap with different MODIS tile subsets.
# =============================================================================

suppressPackageStartupMessages({
  library(mapme.biodiversity)
  library(sf)
  library(dplyr)
  library(tidyr)
})

cat("\n")
cat("=============================================================================\n")
cat("  MAPME Biodiversity - Burned Area Processing\n")
cat("=============================================================================\n")
cat("  Start time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")

# =============================================================================
# GDAL Configuration for Rate Limit Handling
# =============================================================================
Sys.setenv(
  "GDAL_HTTP_MAX_RETRY" = "10",
  "GDAL_HTTP_RETRY_DELAY" = "30"
)

# =============================================================================
# Configuration
# =============================================================================
output_dir <- file.path(getwd(), "data", "mapme_resources")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

mapme_options(
  outdir = output_dir,
  verbose = FALSE
)

# Analysis years for burned area
analysis_years <- 2015:2022

cat("Configuration:\n")
cat("  Output directory:", output_dir, "\n")
cat("  Analysis years:", min(analysis_years), "-", max(analysis_years), "\n\n")

# =============================================================================
# Load Protected Areas
# =============================================================================
cat("[1/3] Loading protected areas...\n")

wdpa_allPAs <- st_read(
  "data/wdpa.gdb",
  layer = "WDPA_WDOECM_poly_Jan2026_BOL",
  quiet = TRUE
)

wdpa_allPAs <- wdpa_allPAs %>%
  rename(
    WDPAID = SITE_ID,
    WDPA_PID = SITE_PID,
    ORIG_NAME = NAME
  )

# Target WDPA IDs for Bolivia
bol_wdpa_ids <- c(
  303891, 555592639, 555592671, 555592663, 555592664, 342481, 9308,
  342482, 342484, 555592677, 555592678, 555592685, 342466,
  555592641, 555592656, 555592600, 342494, 342495, 342496, 342497,
  342498, 555592646, 555592673, 555592608, 20037, 31, 2037, 303887,
  9779, 303884, 303894, 98183, 303885, 303883, 30, 342464, 35,
  342483, 555592593, 342484, 555592669, 342490, 555592668, 342465,
  555592608
)
bol_wdpa_ids <- unique(bol_wdpa_ids)

portfolio <- wdpa_allPAs %>%
  filter(WDPAID %in% bol_wdpa_ids) %>%
  filter(DESIG_ENG != "UNESCO-MAB Biosphere Reserve" | is.na(DESIG_ENG)) %>%
  filter(STATUS != "Proposed" | is.na(STATUS))

portfolio <- st_make_valid(portfolio)
portfolio <- st_transform(portfolio, 4326)

cat("      ✓ Loaded", nrow(portfolio), "protected areas\n\n")

# =============================================================================
# Process Each Area Individually
# =============================================================================
# NOTE: Batch processing fails due to different areas overlapping with different
# MODIS tile subsets. Processing individually works and reuses cached tiles.
# =============================================================================
cat("[2/3] Processing burned area for each protected area...\n")
cat("      (Processing individually to handle varying tile footprints)\n\n")

all_results <- list()
success_count <- 0
error_count <- 0

for (i in seq_len(nrow(portfolio))) {
  area <- portfolio[i, ]
  name <- area$ORIG_NAME[1]
  id <- area$WDPAID[1]
  
  cat(sprintf("      [%2d/%d] %s... ", i, nrow(portfolio), name))
  
  result <- tryCatch({
    # Get resources (uses cache)
    area <- get_resources(area, get_mcd64a1(years = analysis_years))
    
    # Calculate burned area
    area <- calc_indicators(area, calc_burned_area(engine = "zonal"))
    
    # Extract results
    ba <- area$burned_area[[1]]
    if (!is.null(ba) && nrow(ba) > 0) {
      ba$WDPAID <- id
      ba$ORIG_NAME <- name
      cat(sprintf("✓ (%d records)\n", nrow(ba)))
      success_count <<- success_count + 1
      ba
    } else {
      cat("(no data)\n")
      NULL
    }
  }, error = function(e) {
    cat(sprintf("✗ %s\n", conditionMessage(e)))
    error_count <<- error_count + 1
    NULL
  })
  
  if (!is.null(result)) {
    all_results[[length(all_results) + 1]] <- result
  }
}

cat("\n")
cat(sprintf("      Processed: %d success, %d errors\n\n", success_count, error_count))

# =============================================================================
# Save Results
# =============================================================================
cat("[3/3] Saving results...\n")

if (length(all_results) > 0) {
  # Combine all results
  burned_area_all <- bind_rows(all_results)
  
  # Annual burned area
  burned_annual <- burned_area_all %>%
    mutate(year = as.integer(format(datetime, "%Y"))) %>%
    group_by(WDPAID, ORIG_NAME, year) %>%
    summarise(
      burned_area_ha = sum(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    rename(wdpa_id = WDPAID)
  
  # Total burned area
  burned_total <- burned_annual %>%
    group_by(wdpa_id, ORIG_NAME) %>%
    summarise(
      total_burned_area_ha = sum(burned_area_ha, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Save files
  write.csv(burned_annual, "data/bolivia_burned_area_annual_2000_2022.csv", row.names = FALSE)
  write.csv(burned_total, "data/bolivia_burned_area_total_2000_2022.csv", row.names = FALSE)
  
  cat("      ✓ Saved: data/bolivia_burned_area_annual_2000_2022.csv\n")
  cat("      ✓ Saved: data/bolivia_burned_area_total_2000_2022.csv\n")
  cat("      ✓ Protected areas with data:", length(unique(burned_annual$wdpa_id)), "\n")
  cat("      ✓ Years covered:", paste(sort(unique(burned_annual$year)), collapse = ", "), "\n")
  cat("      ✓ Total records:", nrow(burned_annual), "\n")
} else {
  cat("      ⚠ No burned area data extracted\n")
}

cat("\n")
cat("=============================================================================\n")
cat("  Processing Complete!\n")
cat("  End time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")
