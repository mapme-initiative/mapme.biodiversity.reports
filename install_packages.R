# =============================================================================
# Install Required R Packages for MAPME Biodiversity Reports
# =============================================================================
# Run this script once to install all required packages
# =============================================================================

# Function to install package if not already installed
install_if_missing <- function(package) {
  if (!require(package, character.only = TRUE, quietly = TRUE)) {
    message(paste("Installing package:", package))
    install.packages(package, dependencies = TRUE)
  } else {
    message(paste("Package already installed:", package))
  }
}

# ----- Core tidyverse packages -----
install_if_missing("tidyverse")
install_if_missing("dplyr")
install_if_missing("tidyr")
install_if_missing("readr")
install_if_missing("ggplot2")

# ----- Spatial packages -----
install_if_missing("sf")
install_if_missing("terra")

# ----- Interactive visualization -----
install_if_missing("leaflet")
install_if_missing("leaflet.extras")
install_if_missing("leaflet.extras2")
install_if_missing("plotly")
install_if_missing("DT")

# ----- Color and styling -----
install_if_missing("RColorBrewer")
install_if_missing("ggsci")
install_if_missing("scales")
install_if_missing("htmltools")

# ----- Parallel processing -----
install_if_missing("future")
install_if_missing("progressr")

# ----- Additional dependencies for burned area processing -----
install_if_missing("rstac")

# ----- mapme.biodiversity package -----
# Check if mapme.biodiversity is installed
if (!require("mapme.biodiversity", character.only = TRUE, quietly = TRUE)) {
  message("Installing mapme.biodiversity package from CRAN...")
  install.packages("mapme.biodiversity")
  
  # If CRAN version doesn't work, try GitHub
  if (!require("mapme.biodiversity", character.only = TRUE, quietly = TRUE)) {
    message("Trying to install from GitHub...")
    if (!require("remotes", quietly = TRUE)) {
      install.packages("remotes")
    }
    remotes::install_github("mapme-initiative/mapme.biodiversity")
  }
} else {
  message("mapme.biodiversity already installed")
}

# ----- Verify all packages load correctly -----
message("\n========================================")
message("Verifying package installations...")
message("========================================\n")

packages <- c(
  "tidyverse", "sf", "leaflet", "leaflet.extras", "leaflet.extras2",
  "plotly", "DT", "RColorBrewer", "ggsci", "scales", "htmltools",
  "future", "progressr", "mapme.biodiversity"
)

success <- TRUE
for (pkg in packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    message(paste("✓", pkg))
  } else {
    message(paste("✗", pkg, "- FAILED TO LOAD"))
    success <- FALSE
  }
}

if (success) {
  message("\n========================================")
  message("All packages installed successfully!")
  message("========================================")
  message("\nYou can now run processing.R to generate the data,")
  message("then use Quarto to render the reports.")
} else {
  message("\n========================================")
  message("Some packages failed to install.")
  message("Please check the error messages above.")
  message("========================================")
}

# Print session info
message("\n========================================")
message("Session Information:")
message("========================================")
sessionInfo()

