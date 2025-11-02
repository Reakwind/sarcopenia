# ============================================================================
# PATIENT SURVEILLANCE FUNCTIONS
# ============================================================================
#
# Simplified functions for patient-level surveillance
# - Patient data table (visit-level view)
# - Combined outlier detection (clinical + statistical)
# - Formatted patient dropdown labels
#
# Uses utilities from R/utils_data_pipeline.R for consistency
#
# SAFE TO MODIFY - These functions work on cleaned_data() output
# ============================================================================

#' Get Patient Dropdown Labels
#'
#' Creates formatted labels for patient dropdown showing Name (or ID) + summary
#'
#' @param data Cleaned visits data
#' @return Named vector: labels as names, patient IDs as values
#' @export
get_patient_dropdown_labels <- function(data) {

  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # Check if Client Name column exists
  name_col <- NULL
  if ("id_client_name" %in% names(data)) {
    name_col <- "id_client_name"
  } else if ("Client Name" %in% names(data)) {
    name_col <- "Client Name"
  }

  # Get all unique patients
  patient_ids <- unique(data[["id_client_id"]])
  patient_ids <- patient_ids[!is.na(patient_ids)]

  if (length(patient_ids) == 0) {
    return(NULL)
  }

  # Calculate summary for each patient
  labels <- purrr::map_chr(patient_ids, function(pid) {

    patient_data <- data %>%
      dplyr::filter(.data[["id_client_id"]] == pid)

    n_visits <- nrow(patient_data)

    # Count NA values only (not "")
    non_id_data <- patient_data %>%
      dplyr::select(-dplyr::starts_with("id_"))

    total_cells <- nrow(non_id_data) * ncol(non_id_data)
    n_missing <- sum(is.na(non_id_data))
    pct_missing <- round((n_missing / total_cells) * 100, 1)

    # Try to get patient name
    display_name <- pid  # Default to ID

    if (!is.null(name_col) && name_col %in% names(patient_data)) {
      patient_name <- unique(patient_data[[name_col]])[1]
      if (!is.na(patient_name) && nchar(as.character(patient_name)) > 0) {
        display_name <- as.character(patient_name)
      }
    }

    # Format label
    sprintf("%s (%d visits, %.1f%% missing)", display_name, n_visits, pct_missing)
  })

  # Create named vector (label = name, patient_id = value)
  names(labels) <- patient_ids

  return(labels)
}


#' Detect Combined Outliers
#'
#' Detects outliers using both clinical ranges and statistical methods
#' Returns outlier TYPE: "iqr", "clinical", "both", or NA
#'
#' @param data Cleaned visits data
#' @param patient_id Patient ID to analyze
#' @param dict Data dictionary
#' @return Dataframe with outlier type per variable per visit
#' @export
detect_combined_outliers <- function(data, patient_id, dict = NULL) {

  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # Filter to patient
  patient_data <- data %>%
    dplyr::filter(.data[["id_client_id"]] == patient_id)

  if (nrow(patient_data) == 0) {
    return(NULL)
  }

  # Get numeric variables (analysis columns)
  numeric_vars <- names(patient_data)[sapply(patient_data, is.numeric)]

  # Remove ID columns
  numeric_vars <- numeric_vars[!grepl("^id_", numeric_vars)]

  if (length(numeric_vars) == 0) {
    return(tibble::tibble(
      visit_number = character(),
      variable = character(),
      outlier_type = character()
    ))
  }

  # Get visit numbers
  visit_numbers <- dplyr::coalesce(
    patient_data[["demo_visit_number"]],
    patient_data[["id_visit_no"]],
    as.character(seq_len(nrow(patient_data)))
  )

  # Detect outliers for each variable
  outlier_results <- purrr::map_df(numeric_vars, function(var) {

    values <- patient_data[[var]]

    # Skip if all NA
    if (all(is.na(values))) {
      return(NULL)
    }

    # Detect IQR outliers
    iqr_outliers <- rep(FALSE, length(values))
    if (length(na.omit(values)) >= 3) {  # Need at least 3 values for IQR
      q1 <- quantile(values, 0.25, na.rm = TRUE)
      q3 <- quantile(values, 0.75, na.rm = TRUE)
      iqr <- q3 - q1
      lower_bound <- q1 - 1.5 * iqr
      upper_bound <- q3 + 1.5 * iqr
      iqr_outliers <- !is.na(values) & (values < lower_bound | values > upper_bound)
    }

    # Detect clinical range violations
    # Simple thresholds for common variables (can be extended)
    clinical_outliers <- rep(FALSE, length(values))

    # Apply simple clinical range rules
    if (grepl("moca", var, ignore.case = TRUE)) {
      # MoCA score range: 0-30
      clinical_outliers <- !is.na(values) & (values < 0 | values > 30)
    } else if (grepl("grip", var, ignore.case = TRUE)) {
      # Grip strength: 0-80 kg
      clinical_outliers <- !is.na(values) & (values < 0 | values > 80)
    } else if (grepl("phq", var, ignore.case = TRUE)) {
      # PHQ-9 depression: 0-27
      clinical_outliers <- !is.na(values) & (values < 0 | values > 27)
    } else if (grepl("sppb", var, ignore.case = TRUE)) {
      # SPPB total: 0-12
      clinical_outliers <- !is.na(values) & (values < 0 | values > 12)
    } else if (grepl("bmi", var, ignore.case = TRUE)) {
      # BMI: reasonable range 10-60
      clinical_outliers <- !is.na(values) & (values < 10 | values > 60)
    } else if (grepl("age", var, ignore.case = TRUE)) {
      # Age: reasonable range 18-120
      clinical_outliers <- !is.na(values) & (values < 18 | values > 120)
    }

    # Determine outlier type
    outlier_type <- dplyr::case_when(
      iqr_outliers & clinical_outliers ~ "both",
      clinical_outliers ~ "clinical",
      iqr_outliers ~ "iqr",
      TRUE ~ NA_character_
    )

    tibble::tibble(
      visit_number = visit_numbers,
      variable = var,
      outlier_type = outlier_type
    )
  })

  return(outlier_results)
}


#' Get Patient Data Table
#'
#' Gets visit-level data table for a patient with missing and outlier flags
#'
#' @param data Cleaned visits data
#' @param patient_id Patient ID to analyze
#' @param dict Data dictionary
#' @return Dataframe in wide format (one row per visit)
#' @export
get_patient_data_table <- function(data, patient_id, dict = NULL) {

  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # Filter to patient
  patient_data <- data %>%
    dplyr::filter(.data[["id_client_id"]] == patient_id)

  if (nrow(patient_data) == 0) {
    return(NULL)
  }

  # Get visit info
  visit_numbers <- dplyr::coalesce(
    patient_data[["demo_visit_number"]],
    patient_data[["id_visit_no"]],
    as.character(seq_len(nrow(patient_data)))
  )

  visit_dates <- patient_data[["id_visit_date"]]

  # Detect outliers
  outliers <- detect_combined_outliers(data, patient_id, dict)

  # Select relevant columns (exclude ID columns)
  data_cols <- patient_data %>%
    dplyr::select(-dplyr::starts_with("id_"))

  # Create base table
  result_table <- tibble::tibble(
    visit_number = visit_numbers,
    visit_date = visit_dates
  )

  # Add all data columns
  result_table <- dplyr::bind_cols(result_table, data_cols)

  # Add metadata columns for each variable
  for (col in names(data_cols)) {

    # Check if column has NA values (use safe_unname to avoid jsonlite warnings)
    missing_col_name <- get_metadata_column_name(col, "is_missing")
    result_table[[missing_col_name]] <- safe_unname(is.na(result_table[[col]]))

    # Check if column has outliers (now stores type: "iqr", "clinical", "both", or NA)
    if (!is.null(outliers) && nrow(outliers) > 0) {
      outlier_types <- outliers %>%
        dplyr::filter(.data[["variable"]] == col) %>%
        dplyr::pull("outlier_type")

      outlier_col_name <- get_metadata_column_name(col, "outlier_type")
      if (length(outlier_types) == nrow(result_table)) {
        result_table[[outlier_col_name]] <- safe_unname(outlier_types)
      } else {
        result_table[[outlier_col_name]] <- NA_character_
      }
    } else {
      outlier_col_name <- get_metadata_column_name(col, "outlier_type")
      result_table[[outlier_col_name]] <- NA_character_
    }
  }

  return(result_table)
}


# ============================================================================
# KEEP EXISTING COMPLEX FUNCTIONS BELOW FOR BACKWARD COMPATIBILITY
# (These are used by other modules)
# ============================================================================

#' Perform Group Comparison
#'
#' Compares outcome variables between groups (e.g., treatment vs control)
#'
#' @param data Cleaned visits data
#' @param outcome_var Outcome variable name
#' @param group_var Grouping variable name
#' @param test_type Type of test: "t-test", "anova", "chi-square"
#' @return List with test results
#' @export
compare_groups <- function(data, outcome_var, group_var, test_type = "t-test") {
  # TODO: Implement group comparisons

  message("Performing group comparison...")

  # Placeholder implementation
  return(NULL)
}


#' Calculate Correlations
#'
#' Calculates correlation matrix for selected variables
#'
#' @param data Cleaned visits data
#' @param variables Character vector of variable names
#' @param method Correlation method: "pearson", "spearman", "kendall"
#' @return Correlation matrix
#' @export
calculate_correlations <- function(data, variables, method = "pearson") {
  # TODO: Implement correlation analysis

  message("Calculating correlations...")

  # Placeholder implementation
  return(NULL)
}
