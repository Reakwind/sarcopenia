# Launch the ShinyApp (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue button on top of this file

# Smart loading: Use pkgload in development, library() in production
if (requireNamespace("pkgload", quietly = TRUE) && dir.exists("R")) {
  # Development mode: Load from source using pkgload
  message("Running in DEVELOPMENT mode (using pkgload)")
  pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
  options("golem.app.prod" = FALSE)
} else {
  # Production mode: Load installed package
  message("Running in PRODUCTION mode (using library)")
  library(sarcDash)
  options("golem.app.prod" = TRUE)
}

# Run the app
sarcDash::run_app() # add parameters here (if any)