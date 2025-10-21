#' Access files in the current app
#'
#' NOTE: If you manually change your package name in the DESCRIPTION,
#' don't forget to change it here too, and in the config file.
#' For a safer name change mechanism, use the `golem::set_golem_name()` function.
#'
#' @param ... character vectors, specifying subdirectory and file(s)
#' within your package. The default, none, returns the root of the app.
#'
#' @noRd
app_sys <- function(...) {
  system.file(..., package = "sarcDash")
}


#' Read App Config
#'
#' @param value Value to retrieve from the config file.
#' @param config GOLEM_CONFIG_ACTIVE value. If unset, R_CONFIG_ACTIVE.
#' If unset, "default".
#' @param use_parent Logical, scan the parent directory for config file.
#' @param file Location of the config file
#'
#' @noRd
get_golem_config <- function(
  value,
  config = Sys.getenv(
    "GOLEM_CONFIG_ACTIVE",
    Sys.getenv(
      "R_CONFIG_ACTIVE",
      "default"
    )
  ),
  use_parent = TRUE,
  # Modify this if your config file is somewhere else
  file = app_sys("golem-config.yml")
) {
  config::get(
    value = value,
    config = config,
    file = file,
    use_parent = use_parent
  )
}


#' Get data directory path
#'
#' @description
#' Returns the correct path to data files, switching between development
#' and production environments automatically.
#'
#' @return Character string path to data directory
#'
#' @details
#' In development mode (golem.app.prod = FALSE), data is expected in
#' the parent project's "data" directory (../../data).
#'
#' In production mode (golem.app.prod = TRUE), data is bundled in the
#' package at inst/extdata and accessed via app_sys().
#'
#' @noRd
get_data_dir <- function() {
  # Check if in production mode
  is_prod <- getOption("golem.app.prod", default = FALSE)

  if (isTRUE(is_prod)) {
    # Production: data in inst/extdata
    app_sys("extdata")
  } else {
    # Development: data in parent project directory
    here::here("data")
  }
}
