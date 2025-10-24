# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================
#
# General utility functions used across the application
# - Input validation
# - Data formatting
# - Helper functions
#
# SAFE TO MODIFY
# ============================================================================

#' Validate Numeric Input
#'
#' Checks if input is valid numeric value within range
#'
#' @param value Input value to validate
#' @param min_val Minimum allowed value
#' @param max_val Maximum allowed value
#' @return TRUE if valid, FALSE otherwise
#' @export
validate_numeric_input <- function(value, min_val = -Inf, max_val = Inf) {
  if (is.null(value) || is.na(value)) return(FALSE)
  if (!is.numeric(value)) return(FALSE)
  if (value < min_val || value > max_val) return(FALSE)
  return(TRUE)
}


#' Format P-value
#'
#' Formats p-value for display
#'
#' @param p_value P-value to format
#' @param digits Number of decimal places
#' @return Formatted string
#' @export
format_p_value <- function(p_value, digits = 3) {
  if (is.na(p_value)) return("NA")
  if (p_value < 0.001) return("< 0.001")
  return(format(round(p_value, digits), nsmall = digits))
}


#' Get Numeric Analysis Column Name
#'
#' Helper to get the _numeric version of a variable name
#'
#' @param var_name Original variable name
#' @return Analysis column name (_numeric suffix)
#' @export
get_numeric_col_name <- function(var_name) {
  paste0(var_name, "_numeric")
}


#' Get Factor Analysis Column Name
#'
#' Helper to get the _factor version of a variable name
#'
#' @param var_name Original variable name
#' @return Analysis column name (_factor suffix)
#' @export
get_factor_col_name <- function(var_name) {
  paste0(var_name, "_factor")
}


#' Get Date Analysis Column Name
#'
#' Helper to get the _date version of a variable name
#'
#' @param var_name Original variable name
#' @return Analysis column name (_date suffix)
#' @export
get_date_col_name <- function(var_name) {
  paste0(var_name, "_date")
}
