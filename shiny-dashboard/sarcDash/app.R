# Launch the ShinyApp (Do not remove this comment)
# This is the entry point for Posit Connect Cloud deployment

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options("golem.app.prod" = TRUE)
sarcDash::run_app()
