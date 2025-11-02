# ============================================================================
# INSTRUMENT ANALYSIS FUNCTIONS
# ============================================================================
#
# Functions for cross-patient instrument analysis
# - Shows first visit data for all patients
# - Rows = patients, Columns = instrument variables
#
# SAFE TO MODIFY - These functions work on cleaned_data() output
# ============================================================================

#' Get Instrument Variables
#'
#' Gets variable names for a specific instrument from data dictionary
#'
#' @param dict Data dictionary (tibble)
#' @param instrument_name Name of instrument (e.g., "MoCA", "SPPB")
#' @return Character vector of variable names
#' @export
get_instrument_variables <- function(dict, instrument_name) {

  if (is.null(dict) || nrow(dict) == 0) {
    return(character())
  }

  # Filter to instrument and extract variable names
  # Pattern: Uses .data[[]] for NSE inside dplyr
  vars <- dict %>%
    dplyr::filter(.data[["instrument"]] == instrument_name,
                  !is.na(.data[["instrument"]])) %>%
    dplyr::pull("new_name")

  # Remove any NA values
  vars <- vars[!is.na(vars) & vars != ""]

  return(vars)
}


#' Get First Visit Data
#'
#' Filters visits data to only first visit per patient
#'
#' @param data Cleaned visits data (tibble)
#' @return Tibble with one row per patient (first visit only)
#' @export
get_first_visit_data <- function(data) {

  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # Filter to first visit per patient (using visit date as most reliable)
  # Pattern: Uses .data[[]] for NSE inside dplyr verbs
  first_visits <- data %>%
    dplyr::group_by(.data[["id_client_id"]]) %>%
    dplyr::arrange(.data[["id_visit_date"]]) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup()

  return(first_visits)
}


# NOTE: Column resolution utilities have been moved to R/utils_data_pipeline.R
# This file uses resolve_column_name(), get_analysis_columns(), and other utilities
# from the centralized data pipeline utilities module.


#' Get Instrument Table
#'
#' Creates patient × variables table for selected instrument
#'
#' @param data Cleaned visits data (tibble)
#' @param instrument_name Name of instrument
#' @param dict Data dictionary (tibble)
#' @return Tibble with patients as rows, instrument variables as columns
#' @export
get_instrument_table <- function(data, instrument_name, dict) {

  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # Get first visit data
  first_visits <- get_first_visit_data(data)

  if (is.null(first_visits) || nrow(first_visits) == 0) {
    return(NULL)
  }

  # Get instrument variables (dictionary names)
  instrument_vars_dict <- get_instrument_variables(dict, instrument_name)

  if (length(instrument_vars_dict) == 0) {
    return(NULL)
  }

  # Resolve dictionary names to actual column names in data
  # Returns named vector: dict_name = actual_name
  instrument_vars_resolved <- sapply(instrument_vars_dict, function(dict_var) {
    resolve_column_name(dict_var, dict, first_visits)
  })

  # Filter to only successfully resolved columns (not NA)
  instrument_vars_resolved <- instrument_vars_resolved[!is.na(instrument_vars_resolved)]

  if (length(instrument_vars_resolved) == 0) {
    # No variables found - return empty table
    return(NULL)
  }

  # Get actual column names (values) and dict names (names)
  actual_col_names <- unname(instrument_vars_resolved)
  dict_col_names <- names(instrument_vars_resolved)

  # Define ID columns to keep
  id_cols <- c("id_client_id", "id_client_name", "id_visit_date")

  # Combine ID columns + actual instrument column names
  cols_to_keep <- c(id_cols, actual_col_names)

  # Keep only columns that exist in data
  cols_to_keep <- intersect(cols_to_keep, names(first_visits))

  # Create result table with selected columns
  # Pattern: dplyr::select returns tibble automatically
  result_table <- first_visits %>%
    dplyr::select(tidyselect::all_of(cols_to_keep))

  # Get instrument variables that exist in result (using actual names)
  existing_instrument_vars <- actual_col_names[actual_col_names %in% names(result_table)]

  # Detect outliers across patients (BEFORE converting factors)
  outliers <- detect_instrument_outliers(result_table, existing_instrument_vars)

  # Prepare columns for display: convert factors to character AFTER outlier detection
  for (col_name in actual_col_names) {
    if (col_name %in% names(result_table)) {
      if (is.factor(result_table[[col_name]])) {
        result_table[[col_name]] <- as.character(result_table[[col_name]])
      }
    }
  }

  # Add metadata columns for each instrument variable
  for (var in existing_instrument_vars) {

    # Add missing data flag (unname to avoid jsonlite warning)
    result_table[[paste0(var, "_is_missing")]] <- unname(is.na(result_table[[var]]))

    # Add outlier type
    if (!is.null(outliers) && nrow(outliers) > 0) {
      outlier_types <- outliers %>%
        dplyr::filter(.data[["variable"]] == var) %>%
        dplyr::pull("outlier_type")

      if (length(outlier_types) == nrow(result_table)) {
        # Unname to avoid jsonlite warning about named vectors
        result_table[[paste0(var, "_outlier_type")]] <- unname(outlier_types)
      } else {
        result_table[[paste0(var, "_outlier_type")]] <- NA_character_
      }
    } else {
      result_table[[paste0(var, "_outlier_type")]] <- NA_character_
    }
  }

  return(result_table)
}


#' Get Instrument List
#'
#' Returns grouped list of available instruments for dropdown
#'
#' @param dict Data dictionary (tibble)
#' @return Named list for grouped selectInput
#' @export
get_instrument_list <- function(dict) {

  if (is.null(dict) || nrow(dict) == 0) {
    return(list())
  }

  # Define instrument groups
  cognitive_instruments <- c("MoCA", "PHQ-9", "DSST", "WHO-5", "Verbal Fluency")
  physical_instruments <- c("SPPB", "Grip Strength", "Gait Speed", "Frailty Scale", "SARC-F")

  # Get available instruments from dictionary
  # Pattern: Uses .data[[]] for NSE inside dplyr
  available_instruments <- dict %>%
    dplyr::filter(!is.na(.data[["instrument"]]),
                  .data[["instrument"]] != "",
                  .data[["instrument"]] != "NA") %>%
    dplyr::pull("instrument") %>%
    unique()

  # Filter to only available instruments
  cognitive_available <- cognitive_instruments[cognitive_instruments %in% available_instruments]
  physical_available <- physical_instruments[physical_instruments %in% available_instruments]

  # Create grouped list for selectInput
  instrument_list <- list(
    "Cognitive Assessments" = setNames(cognitive_available, cognitive_available),
    "Physical Performance" = setNames(physical_available, physical_available)
  )

  return(instrument_list)
}


#' Detect Instrument Outliers
#'
#' Detects outliers for instrument variables using IQR and clinical ranges
#' Analyzes across patients (not within-patient like Patient Surveillance)
#'
#' @param data First visit data (tibble, one row per patient)
#' @param variables Character vector of variable names to analyze
#' @return Tibble with patient_id, variable, outlier_type
#' @export
detect_instrument_outliers <- function(data, variables) {

  if (is.null(data) || nrow(data) == 0 || length(variables) == 0) {
    return(tibble::tibble(
      patient_id = character(),
      variable = character(),
      outlier_type = character()
    ))
  }

  # Get patient IDs
  # Pattern: Use [[]] for direct column access
  patient_ids <- data[["id_client_id"]]

  # Detect outliers for each variable
  outlier_results <- purrr::map_df(variables, function(var) {

    # Skip if variable doesn't exist
    if (!var %in% names(data)) {
      return(NULL)
    }

    values <- data[[var]]

    # Skip if all NA
    if (all(is.na(values))) {
      return(NULL)
    }

    # Skip if not numeric (can't detect outliers on factors/characters)
    if (!is.numeric(values)) {
      return(NULL)
    }

    # Detect IQR outliers (across patients)
    iqr_outliers <- rep(FALSE, length(values))
    if (length(na.omit(values)) >= 3) {
      q1 <- quantile(values, 0.25, na.rm = TRUE)
      q3 <- quantile(values, 0.75, na.rm = TRUE)
      iqr <- q3 - q1
      lower_bound <- q1 - 1.5 * iqr
      upper_bound <- q3 + 1.5 * iqr
      iqr_outliers <- !is.na(values) & (values < lower_bound | values > upper_bound)
    }

    # Detect clinical range violations
    clinical_outliers <- rep(FALSE, length(values))

    # Apply clinical range rules
    if (grepl("moca", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 30)
    } else if (grepl("grip", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 80)
    } else if (grepl("phq", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 27)
    } else if (grepl("sppb", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 12)
    } else if (grepl("bmi", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 10 | values > 60)
    } else if (grepl("age", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 18 | values > 120)
    } else if (grepl("dsst", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 135)
    } else if (grepl("who.*5|who_5", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 25)
    } else if (grepl("sarc", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 10)
    } else if (grepl("frailty", var, ignore.case = TRUE)) {
      clinical_outliers <- !is.na(values) & (values < 0 | values > 5)
    }

    # Determine outlier type
    outlier_type <- dplyr::case_when(
      iqr_outliers & clinical_outliers ~ "both",
      clinical_outliers ~ "clinical",
      iqr_outliers ~ "iqr",
      TRUE ~ NA_character_
    )

    tibble::tibble(
      patient_id = patient_ids,
      variable = var,
      outlier_type = outlier_type
    )
  })

  # Ensure we return a proper tibble
  if (is.null(outlier_results) || !is.data.frame(outlier_results) || nrow(outlier_results) == 0) {
    return(tibble::tibble(
      patient_id = character(),
      variable = character(),
      outlier_type = character()
    ))
  }

  return(outlier_results)
}
