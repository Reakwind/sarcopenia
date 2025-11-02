# ============================================================================
# DATA PIPELINE UTILITIES
# ============================================================================
#
# Centralized utilities for working with cleaned data
# Handles column name resolution, data type conversion, and validation
#
# USE THESE UTILITIES IN ALL ANALYSIS FEATURES
# ============================================================================

#' Resolve Column Name from Dictionary to Cleaned Data
#'
#' Resolves a dictionary variable name to its actual column name in cleaned data.
#' Handles suffix logic for time-varying variables automatically.
#'
#' Time-varying variables get suffixes based on data_type:
#' - numeric → {name}_numeric
#' - binary/categorical → {name}_factor
#' - date → {name}_date
#'
#' Time-invariant variables keep their base name (no suffix).
#'
#' @param dict_var_name Variable name from dictionary (e.g., "cog_moca_total_score")
#' @param dict Data dictionary (tibble)
#' @param data Cleaned data (tibble)
#' @param prefer Preferred suffix when multiple exist ("numeric", "factor", "auto"). Default: "auto"
#' @return Actual column name in data, or NA if not found
#' @export
#' @examples
#' resolve_column_name("cog_moca_total_score", dict, data)
#' # Returns: "cog_moca_total_score_numeric"
resolve_column_name <- function(dict_var_name, dict, data, prefer = "auto") {

  # Look up variable in dictionary
  dict_row <- dict %>%
    dplyr::filter(.data[["new_name"]] == dict_var_name)

  if (nrow(dict_row) == 0) {
    # Not in dictionary - try as-is
    if (dict_var_name %in% names(data)) {
      return(dict_var_name)
    } else {
      return(NA_character_)
    }
  }

  # Get metadata about this variable
  var_category <- dict_row[["variable_category"]][1]
  data_type <- dict_row[["data_type"]][1]

  # Time-invariant variables don't get suffixes
  if (var_category == "time_invariant") {
    if (dict_var_name %in% names(data)) {
      return(dict_var_name)
    } else {
      return(NA_character_)
    }
  }

  # Time-varying variables get suffixes based on data_type
  # Build list of candidates in priority order
  candidates <- character()

  if (prefer == "numeric") {
    # Prefer numeric suffix first
    candidates <- c(
      paste0(dict_var_name, "_numeric"),
      paste0(dict_var_name, "_factor"),
      paste0(dict_var_name, "_date"),
      dict_var_name
    )
  } else if (prefer == "factor") {
    # Prefer factor suffix first
    candidates <- c(
      paste0(dict_var_name, "_factor"),
      paste0(dict_var_name, "_numeric"),
      paste0(dict_var_name, "_date"),
      dict_var_name
    )
  } else {
    # Auto: use data_type to determine priority
    if (data_type == "numeric") {
      candidates <- c(
        paste0(dict_var_name, "_numeric"),
        dict_var_name
      )
    } else if (data_type %in% c("binary", "categorical")) {
      candidates <- c(
        paste0(dict_var_name, "_factor"),
        dict_var_name
      )
    } else if (data_type == "date") {
      candidates <- c(
        paste0(dict_var_name, "_date"),
        dict_var_name
      )
    } else {
      # Text or other - try base name
      candidates <- dict_var_name
    }
  }

  # Find first candidate that exists in data
  for (candidate in candidates) {
    if (candidate %in% names(data)) {
      return(candidate)
    }
  }

  # Not found
  return(NA_character_)
}


#' Get Analysis Columns
#'
#' Resolves multiple dictionary variable names to actual column names in cleaned data.
#' Returns a named vector mapping dictionary names to actual column names.
#'
#' @param dict_var_names Character vector of dictionary variable names
#' @param dict Data dictionary (tibble)
#' @param data Cleaned data (tibble)
#' @param prefer Preferred suffix ("numeric", "factor", "auto"). Default: "auto"
#' @param warn_missing Warn about missing columns? Default: TRUE
#' @return Named character vector: dict_name = actual_name (only successfully resolved)
#' @export
#' @examples
#' cols <- get_analysis_columns(c("cog_moca_total_score", "cog_dsst_total_score"), dict, data)
#' # Returns: c(cog_moca_total_score = "cog_moca_total_score_numeric",
#' #            cog_dsst_total_score = "cog_dsst_total_score_numeric")
get_analysis_columns <- function(dict_var_names, dict, data, prefer = "auto", warn_missing = TRUE) {

  # Resolve each variable
  resolved <- sapply(dict_var_names, function(dict_var) {
    resolve_column_name(dict_var, dict, data, prefer)
  })

  # Find missing columns
  missing <- dict_var_names[is.na(resolved)]

  if (warn_missing && length(missing) > 0) {
    warning(sprintf(
      "Could not resolve %d columns: %s",
      length(missing),
      paste(missing, collapse = ", ")
    ))
  }

  # Filter to only successfully resolved
  resolved <- resolved[!is.na(resolved)]

  return(resolved)
}


#' Prepare Column for Display
#'
#' Prepares a data column for display in reactable or other UI components.
#' Handles factor-to-character conversion, date formatting, etc.
#'
#' @param data_col Vector of data from cleaned data
#' @param data_type Data type from dictionary ("numeric", "binary", "categorical", "date", "text")
#' @return Vector suitable for display (factors converted to character, dates formatted)
#' @export
#' @examples
#' display_col <- prepare_for_display(data$cog_moca_factor, "binary")
prepare_for_display <- function(data_col, data_type = NULL) {

  # Handle factors - convert to character for reactable
  if (is.factor(data_col)) {
    return(as.character(data_col))
  }

  # Handle dates - format for display
  if (lubridate::is.Date(data_col) || lubridate::is.POSIXt(data_col)) {
    return(format(data_col, "%Y-%m-%d"))
  }

  # Return as-is for numeric, character, logical
  return(data_col)
}


#' Validate Instrument Variables
#'
#' Validates that all expected instrument variables exist in cleaned data.
#' Returns a validation report with missing columns and type mismatches.
#'
#' @param dict Data dictionary (tibble)
#' @param instrument_name Name of instrument (e.g., "MoCA", "DSST")
#' @param data Cleaned data (tibble)
#' @return List with: valid (logical), missing_vars (character), message (character)
#' @export
#' @examples
#' validation <- validate_instrument_variables(dict, "DSST", data)
#' if (!validation$valid) {
#'   warning(validation$message)
#' }
validate_instrument_variables <- function(dict, instrument_name, data) {

  # Get instrument variables from dictionary
  instrument_vars <- dict %>%
    dplyr::filter(.data[["instrument"]] == instrument_name,
                  !is.na(.data[["instrument"]])) %>%
    dplyr::pull("new_name")

  if (length(instrument_vars) == 0) {
    return(list(
      valid = FALSE,
      missing_vars = character(),
      message = sprintf("Instrument '%s' not found in dictionary", instrument_name)
    ))
  }

  # Resolve to actual column names
  resolved <- get_analysis_columns(instrument_vars, dict, data, warn_missing = FALSE)

  # Find missing
  missing_vars <- instrument_vars[!instrument_vars %in% names(resolved)]

  # Build validation result
  if (length(missing_vars) == 0) {
    return(list(
      valid = TRUE,
      missing_vars = character(),
      resolved_vars = resolved,
      message = sprintf("All %d variables for '%s' found", length(instrument_vars), instrument_name)
    ))
  } else {
    return(list(
      valid = FALSE,
      missing_vars = missing_vars,
      resolved_vars = resolved,
      message = sprintf(
        "Instrument '%s': %d/%d variables found, missing: %s",
        instrument_name,
        length(resolved),
        length(instrument_vars),
        paste(missing_vars, collapse = ", ")
      )
    ))
  }
}


#' Get Metadata Column Name
#'
#' Returns the conventional metadata column name for a variable.
#' Ensures consistent naming across features.
#'
#' @param base_var Base variable name (actual column name in data)
#' @param metadata_type Type of metadata ("is_missing", "outlier_type")
#' @return Metadata column name
#' @export
#' @examples
#' missing_col <- get_metadata_column_name("cog_moca_total_score_numeric", "is_missing")
#' # Returns: "cog_moca_total_score_numeric_is_missing"
get_metadata_column_name <- function(base_var, metadata_type) {

  if (metadata_type == "is_missing") {
    return(paste0(base_var, "_is_missing"))
  } else if (metadata_type == "outlier_type") {
    return(paste0(base_var, "_outlier_type"))
  } else {
    stop(sprintf("Unknown metadata_type: '%s'", metadata_type))
  }
}


#' Check if Column is Numeric for Analysis
#'
#' Determines if a column can be used for numeric analysis (outlier detection, etc.)
#'
#' @param data_col Vector of data
#' @return Logical - TRUE if numeric, FALSE otherwise
#' @export
is_numeric_for_analysis <- function(data_col) {
  is.numeric(data_col) && !is.factor(data_col)
}


#' Safe Unname Vector
#'
#' Removes names from a vector to avoid jsonlite warnings.
#' Safe to call on already-unnamed vectors.
#'
#' @param vec Vector to unname
#' @return Unnamed vector
#' @export
safe_unname <- function(vec) {
  if (is.null(names(vec))) {
    return(vec)
  } else {
    return(unname(vec))
  }
}
