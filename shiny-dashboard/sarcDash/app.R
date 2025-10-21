# Launch the ShinyApp (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue button on top of this file

# Smart loading for different environments
# Priority: pkgload (dev) > installed package > source files (shinyapps.io)
if (requireNamespace("pkgload", quietly = TRUE) && dir.exists("R")) {
  # Development mode: Load from source using pkgload
  message("Running in DEVELOPMENT mode (using pkgload)")
  pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
  options("golem.app.prod" = FALSE)
} else if (requireNamespace("sarcDash", quietly = TRUE)) {
  # Production mode with installed package
  message("Running in PRODUCTION mode (using library)")
  library(sarcDash)
  options("golem.app.prod" = TRUE)
} else {
  # shinyapps.io mode: Source R/ files directly
  message("Running on shinyapps.io (sourcing R/ files)")
  options("golem.app.prod" = TRUE)

  # Load required libraries that aren't auto-loaded
  library(shiny)
  library(golem)

  # Source all R files in correct order
  r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
  # Sort to ensure dependencies load first
  r_files <- sort(r_files)
  for (f in r_files) {
    source(f, local = FALSE)
  }
}

# Run the app
# Use :: notation if package is loaded, otherwise call directly
if (requireNamespace("sarcDash", quietly = TRUE)) {
  sarcDash::run_app()
} else {
  run_app()
}