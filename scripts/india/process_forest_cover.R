# =============================================================================
# Processing Script: Generate Forest Cover Data for India (Tripura Villages)
# =============================================================================
# Author: Generated for India Forest Cover Report
# Date: 2026-03-07
# Purpose: Generate forest cover statistics for villages in Tripura, India
#          using mapme.biodiversity package and Global Forest Watch data
# Input:   data/india/input/tripura_villages_esri.geojson  (all 917 villages)
#          data/india/input/tripura_vdpic_matched.geojson  (99 project villages)
# Join:    villages$lgd_villagecode == vdpic$src_lgd_villagecode
# Output:  data/india/output/
# Period:  2001-2024
# =============================================================================

cat("\n")
cat("=============================================================================\n")
cat("  MAPME Biodiversity - India Forest Cover Data Processing\n")
cat("=============================================================================\n")
cat("  Start time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")

# ----- Load Required Libraries -----
cat("[1/5] Loading required libraries...\n")

suppressPackageStartupMessages({
  library(mapme.biodiversity)
  library(sf)
  library(dplyr)
  library(tidyr)
})

cat("      ✓ Libraries loaded successfully\n")
cat("      Package version: mapme.biodiversity", as.character(packageVersion("mapme.biodiversity")), "\n\n")

# ----- Configuration -----
cat("[2/5] Setting up configuration...\n")

output_dir <- file.path(getwd(), "data", "shared", "mapme_resources")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(getwd(), "data", "india", "output"), showWarnings = FALSE, recursive = TRUE)

mapme_options(
  outdir = output_dir,
  verbose = TRUE
)

# GFC-2024-v1.12 tracks loss from 2001 (2000 = baseline treecover)
analysis_years <- 2001:2024
portfolio_path <- "data/india/output/india_portfolio_processed.gpkg"

cat("      ✓ Output directory:", output_dir, "\n")
cat("      ✓ Analysis period:", min(analysis_years), "-", max(analysis_years), "\n\n")

# =============================================================================
# PART 1: Load Village Polygons
# =============================================================================
cat("[3/5] Loading village polygons...\n")

all_villages <- st_read(
  "data/india/input/tripura_villages_esri.geojson",
  quiet = TRUE
)
all_villages <- st_make_valid(all_villages)
if (!is.na(st_crs(all_villages)) && st_crs(all_villages)$epsg != 4326)
  all_villages <- st_transform(all_villages, 4326)

cat("      ✓ Loaded all villages:", nrow(all_villages), "features\n")
cat("      Columns:", paste(names(all_villages), collapse = ", "), "\n\n")

# Load VDPIC matched (project) villages - keep sf for spatial fallback
vdpic_sf <- st_read(
  "data/india/input/tripura_vdpic_matched.geojson",
  quiet = TRUE
)
vdpic <- st_drop_geometry(vdpic_sf)  # attribute-only version

cat("      ✓ Loaded project (VDPIC matched) villages:", nrow(vdpic), "rows\n")
cat("      Join key: lgd_villagecode <-> src_lgd_villagecode\n\n")

# =============================================================================
# PART 2: Download Resources and Calculate Indicators
# (Skipped if portfolio geopackage already exists)
# =============================================================================
if (file.exists(portfolio_path)) {
  cat("[4/5] Portfolio geopackage found — loading cached results...\n")
  all_villages <- read_portfolio(portfolio_path)
  cat("      ✓ Loaded:", nrow(all_villages), "villages from", portfolio_path, "\n\n")
} else {
  cat("[4/5] Downloading forest cover data (GFC-2024-v1.12)...\n")
  cat("      This may take 30-60 minutes on first run...\n\n")

  all_villages <- get_resources(
    all_villages,
    get_gfw_treecover(version = "GFC-2024-v1.12"),
    get_gfw_lossyear(version = "GFC-2024-v1.12")
  )
  cat("      ✓ GFW resources downloaded\n")

  cat("      Calculating forest cover statistics for", nrow(all_villages), "villages...\n")
  all_villages <- calc_indicators(
    all_villages,
    calc_treecover_area(
      years = analysis_years,
      min_cover = 10,
      min_size = 1
    )
  )
  cat("      ✓ Treecover area calculated\n")

  write_portfolio(x = all_villages, dsn = portfolio_path, overwrite = TRUE)
  cat("      ✓ Portfolio saved:", portfolio_path, "\n\n")
}

# =============================================================================
# PART 3: Extract Stats and Join Project Village Attributes
# =============================================================================
cat("[5/5] Extracting results and joining project village attributes...\n")

# =============================================================================
# Two-stage matching — unified via objectid lookup:
#   Stage 1: attribute join on lgd_villagecode
#   Stage 2: spatial intersection for vdpic rows without an LGD code
# Both stages resolve to (objectid -> vdpic attributes) and are combined
# into a single lookup before joining to all_villages.
# =============================================================================

# --- Stage 1: attribute join ---
vdpic_with_code <- vdpic %>%
  filter(!is.na(src_lgd_villagecode)) %>%
  distinct(src_lgd_villagecode, .keep_all = TRUE) %>%
  mutate(match_stage = "attribute_join")

vdpic_no_code <- vdpic_sf %>%
  filter(is.na(src_lgd_villagecode))

cat("      Stage 1 (attribute join): ", nrow(vdpic_with_code), "vdpic rows with LGD code\n")
cat("      Stage 2 (spatial fallback):", nrow(vdpic_no_code), "vdpic rows without LGD code\n")

# Resolve attribute matches to objectid (via lgd_villagecode)
attr_lookup <- st_drop_geometry(all_villages) %>%
  select(objectid, lgd_villagecode) %>%
  inner_join(vdpic_with_code, by = c("lgd_villagecode" = "src_lgd_villagecode")) %>%
  select(-lgd_villagecode)

gb_only <- st_sf(geom = st_sfc(), crs = 4326)  # empty placeholder for Stage 3

# --- Stage 2: spatial matching for rows without LGD code ---
# These were matched to geoBoundaries (2011 Census), which has no LGD codes.
# Strategy: compute polygon centroid and find which ESRI village polygon contains it.
# This is more reliable than full polygon intersection when boundary vintages differ.
spatial_lookup <- tibble()

if (nrow(vdpic_no_code) > 0 && any(!st_is_empty(vdpic_no_code))) {
  vdpic_no_code  <- st_transform(vdpic_no_code, st_crs(all_villages))
  gb_centroids   <- suppressWarnings(st_centroid(vdpic_no_code))
  hits           <- st_within(gb_centroids, all_villages)

  matched_idx   <- which(lengths(hits) > 0)
  no_match_idx  <- which(lengths(hits) == 0 & !st_is_empty(vdpic_no_code))

  if (length(matched_idx) > 0) {
    spatial_lookup <- st_drop_geometry(vdpic_no_code)[matched_idx, ] %>%
      mutate(
        objectid    = all_villages$objectid[vapply(hits[matched_idx], `[[`, integer(1), 1)],
        match_stage = "spatial_centroid"
      )
  }
  # Preserve the unmatched GB features for Stage 3 direct processing
  if (length(no_match_idx) > 0) {
    gb_only <- vdpic_no_code[no_match_idx, ]
  }
  cat("      Stage 2 spatial matches found:", nrow(spatial_lookup), "/ 9\n")
  cat("      Stage 3 (direct GB processing):", nrow(gb_only), "polygons queued\n")
  cat("      Truly unmatched (no polygon): 9 sub-hamlets/RFs not in Census data\n")
}

# Combine both lookups (objectid is the key); attribute join wins if both match
combined_lookup <- bind_rows(attr_lookup, spatial_lookup) %>%
  distinct(objectid, .keep_all = TRUE)

cat("      Total project villages matched:", nrow(combined_lookup),
    "out of", nrow(vdpic), "\n\n")

# --- Join combined lookup to all_villages by objectid BEFORE unnesting ---
all_villages_df <- st_drop_geometry(all_villages) %>%
  select(-any_of(c("is_project_village", "match_stage"))) %>%
  left_join(combined_lookup, by = "objectid") %>%
  mutate(is_project_village = !is.na(match_stage))

# Extract all non-list columns (computed on the joined df so geometry is absent)
non_list_cols <- names(all_villages_df)[!sapply(all_villages_df, is.list)]

gfw_stats <- all_villages_df %>%
  select(all_of(non_list_cols), treecover_area) %>%
  unnest(treecover_area) %>%
  mutate(
    year    = as.integer(format(datetime, "%Y")),
    area_ha = value
  ) %>%
  select(-datetime, -unit, -value)

# Calculate annual loss and cumulative loss per village
gfw_stats <- gfw_stats %>%
  group_by(lgd_villagecode) %>%
  arrange(year) %>%
  mutate(
    loss_ha            = lag(area_ha, 1) - area_ha,
    loss_ha            = ifelse(is.na(loss_ha) | loss_ha < 0, 0, loss_ha),
    baseline_2001      = first(area_ha),
    cumulative_loss_ha = baseline_2001 - area_ha
  ) %>%
  ungroup() %>%
  arrange(lgd_villagecode, year)

# =============================================================================
# PART 4 (optional): Process geoBoundaries-only polygons directly
# These 4 vdpic villages have geoBoundaries geometry but no overlapping ESRI
# polygon. We run mapme on them directly — tiles are already cached, so fast.
# =============================================================================
gb_stats <- NULL

if (nrow(gb_only) > 0) {
  cat("Processing", nrow(gb_only), "geoBoundaries-only villages (tiles cached)...\n")

  gb_port <- gb_only %>%
    st_make_valid() %>%
    mutate(match_stage = "gb_direct", is_project_village = TRUE)

  gb_port <- get_resources(
    gb_port,
    get_gfw_treecover(version = "GFC-2024-v1.12"),
    get_gfw_lossyear(version = "GFC-2024-v1.12")
  )
  gb_port <- calc_indicators(
    gb_port,
    calc_treecover_area(years = analysis_years, min_cover = 10, min_size = 1)
  )

  gb_df           <- st_drop_geometry(gb_port)
  gb_non_list     <- names(gb_df)[!sapply(gb_df, is.list)]

  gb_stats <- gb_df %>%
    select(all_of(gb_non_list), treecover_area) %>%
    unnest(treecover_area) %>%
    mutate(year = as.integer(format(datetime, "%Y")), area_ha = value) %>%
    select(-datetime, -unit, -value) %>%
    group_by(csv_id) %>%
    arrange(year) %>%
    mutate(
      loss_ha            = lag(area_ha, 1) - area_ha,
      loss_ha            = ifelse(is.na(loss_ha) | loss_ha < 0, 0, loss_ha),
      baseline_2001      = first(area_ha),
      cumulative_loss_ha = baseline_2001 - area_ha
    ) %>%
    ungroup() %>%
    arrange(csv_id, year)

  # bind_rows fills missing columns with NA automatically
  gfw_stats <- bind_rows(gfw_stats, gb_stats)
  cat("      ✓ Added", nrow(gb_only), "geoBoundaries-only villages\n\n")
}

n_polygons <- nrow(all_villages) + nrow(gb_only)
n_project  <- sum(all_villages_df$is_project_village) + nrow(gb_only)
n_control  <- nrow(all_villages) - sum(all_villages_df$is_project_village)

cat("      ✓ Results extracted:", nrow(gfw_stats), "records\n")
cat("      Total village polygons:", n_polygons, "\n")
cat("      Project villages (VDPIC matched):", n_project, "\n")
cat("      Control villages:", n_control, "\n")
cat("      Note: source has", length(unique(gfw_stats$lgd_villagecode)),
    "unique LGD codes across", n_polygons, "polygons\n\n")

# =============================================================================
# Save Output
# =============================================================================
write.csv(
  gfw_stats,
  "data/india/output/india_forest_cover_2001_2024.csv",
  row.names = FALSE
)
cat("      ✓ Saved: data/india/output/india_forest_cover_2001_2024.csv\n")

writeLines(
  capture.output(sessionInfo()),
  "data/india/output/india_processing_session_info.txt"
)
cat("      ✓ Saved: data/india/output/india_processing_session_info.txt\n\n")

# =============================================================================
# Final Summary
# =============================================================================
cat("=============================================================================\n")
cat("  Processing Complete!\n")
cat("=============================================================================\n")
cat("  End time:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("=============================================================================\n\n")

cat("Generated files:\n")
cat("  1. data/india/output/india_forest_cover_2001_2024.csv\n")
cat("  2. data/india/output/india_portfolio_processed.gpkg\n")
cat("  3. data/india/output/india_processing_session_info.txt\n\n")

cat("Summary:\n")
cat("  - Total village polygons:", n_polygons, "\n")
cat("  - Project villages (VDPIC matched):", n_project, "\n")
cat("  - Control villages:", n_control, "\n")
cat("  - Analysis period:", min(analysis_years), "-", max(analysis_years), "\n")
cat("  - GFW Version: GFC-2024-v1.12\n")
cat("  - Canopy cover threshold: 10%\n\n")

cat("Next steps:\n")
cat("  1. Review data/india/output/india_forest_cover_2001_2024.csv\n")
cat("  2. Render the report: quarto render reports/forest_cover_india.qmd\n\n")
