#!/usr/bin/env Rscript
# ============================================================================
# Test Script for New Cleaning Functions
# ============================================================================
# Tests convert_patient_level_na(), fill_time_invariant(), create_analysis_columns()

library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(stringr)

# ============================================================================
# NEW FUNCTION 1: convert_patient_level_na()
# ============================================================================

#' Convert Patient-Level Missing Data
#'
#' Convert empty strings to NA ONLY when empty across all patient visits
#' This is the CRITICAL first step - must happen before any filling
#'
#' @param data Dataframe with id_client_id column
#' @param dict Enhanced data dictionary with variable_category column
#' @return Dataframe with patient-level "" → NA conversion
convert_patient_level_na <- function(data, dict) {
  message("[CONVERT_NA] Starting patient-level NA conversion...")
  message("[CONVERT_NA] Input: ", nrow(data), " rows, ", ncol(data), " columns")

  # Validate inputs
  if (!"id_client_id" %in% names(data)) {
    stop("id_client_id column not found in data")
  }

  if (!"variable_category" %in% names(dict)) {
    stop("variable_category column not found in dictionary. Use enhanced dictionary.")
  }

  # Get non-adverse-event columns that exist in data
  target_cols <- dict %>%
    filter(variable_category != "adverse_event") %>%
    pull(new_name) %>%
    intersect(names(data))

  message("[CONVERT_NA] Processing ", length(target_cols), " non-adverse-event columns")

  # Get unique patients
  patient_ids <- unique(data$id_client_id)
  message("[CONVERT_NA] Found ", length(patient_ids), " unique patients")

  # Track conversions
  conversion_count <- 0

  # For each target column
  for (col in target_cols) {
    # For each patient
    for (pid in patient_ids) {
      # Get patient's rows
      patient_mask <- data$id_client_id == pid
      patient_values <- data[[col]][patient_mask]

      # Check if ALL values are empty string or already NA
      all_empty <- all(is.na(patient_values) | patient_values == "")

      # Check if at least one is empty (not NA)
      has_empty <- any(!is.na(patient_values) & patient_values == "")

      if (all_empty && has_empty) {
        # Convert all empty strings to NA for this patient-column combination
        data[[col]][patient_mask] <- NA
        conversion_count <- conversion_count + sum(patient_values == "", na.rm = TRUE)
      }
    }
  }

  message("[CONVERT_NA] Converted ", conversion_count, " patient-level empty strings to NA")
  message("[CONVERT_NA] Complete!")

  return(data)
}


# ============================================================================
# NEW FUNCTION 2: fill_time_invariant()
# ============================================================================

#' Fill Time-Invariant Variables Within Patient
#'
#' Fill time-invariant variables (demographics, baseline medical, units)
#' within each patient using first non-missing value
#' MUST be called AFTER convert_patient_level_na()
#'
#' @param data Dataframe with patient-level NAs converted
#' @param dict Enhanced data dictionary with variable_category column
#' @return Dataframe with time-invariant variables filled
fill_time_invariant <- function(data, dict) {
  message("[FILL] Starting time-invariant variable filling...")
  message("[FILL] Input: ", nrow(data), " rows")

  # Validate
  if (!"id_client_id" %in% names(data)) {
    stop("id_client_id column not found in data")
  }

  # Get time-invariant columns that exist in data
  time_inv_cols <- dict %>%
    filter(variable_category == "time_invariant") %>%
    pull(new_name) %>%
    intersect(names(data))

  message("[FILL] Found ", length(time_inv_cols), " time-invariant columns")

  if (length(time_inv_cols) == 0) {
    message("[FILL] No time-invariant columns to fill")
    return(data)
  }

  patient_ids <- unique(data$id_client_id)
  total_filled <- 0

  # For each time-invariant column
  for (col in time_inv_cols) {
    filled_this_col <- 0

    # For each patient
    for (pid in patient_ids) {
      patient_mask <- data$id_client_id == pid
      patient_indices <- which(patient_mask)
      patient_values <- data[[col]][patient_indices]

      # Get first non-NA, non-empty value
      non_missing <- patient_values[!is.na(patient_values) & patient_values != ""]

      if (length(non_missing) > 0) {
        fill_value <- non_missing[1]

        # Fill all NAs and empty strings
        for (idx in patient_indices) {
          if (is.na(data[[col]][idx]) || data[[col]][idx] == "") {
            data[[col]][idx] <- fill_value
            filled_this_col <- filled_this_col + 1
          }
        }
      }
    }

    if (filled_this_col > 0) {
      message("[FILL] Filled ", filled_this_col, " values in: ", col)
      total_filled <- total_filled + filled_this_col
    }
  }

  message("[FILL] Total filled: ", total_filled, " values across ", length(time_inv_cols), " columns")
  message("[FILL] Complete!")

  return(data)
}


# ============================================================================
# NEW FUNCTION 3: create_analysis_columns()
# ============================================================================

#' Create Analysis Columns for Time-Varying Variables
#'
#' Creates dual columns for time-varying variables:
#' - Original: Character (preserves "" vs NA distinction)
#' - Analysis: _numeric/_factor/_date (both "" and NA → NA for stats)
#'
#' @param data Dataframe with filled time-invariant vars
#' @param dict Enhanced data dictionary
#' @return Dataframe with additional analysis columns
create_analysis_columns <- function(data, dict) {
  message("[DUAL_COL] Creating analysis columns for time-varying variables...")

  # Get time-varying variables by data type (that exist in data)
  time_var_numeric <- dict %>%
    filter(variable_category == "time_varying", data_type == "numeric") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_binary <- dict %>%
    filter(variable_category == "time_varying", data_type == "binary") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_categorical <- dict %>%
    filter(variable_category == "time_varying", data_type == "categorical") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_date <- dict %>%
    filter(variable_category == "time_varying", data_type == "date") %>%
    pull(new_name) %>%
    intersect(names(data))

  message("[DUAL_COL] Time-varying numeric: ", length(time_var_numeric))
  message("[DUAL_COL] Time-varying binary: ", length(time_var_binary))
  message("[DUAL_COL] Time-varying categorical: ", length(time_var_categorical))
  message("[DUAL_COL] Time-varying date: ", length(time_var_date))

  # Create numeric analysis columns
  for (col in time_var_numeric) {
    new_col_name <- paste0(col, "_numeric")
    data[[new_col_name]] <- suppressWarnings(as.numeric(data[[col]]))
    message("[DUAL_COL] Created: ", new_col_name)
  }

  # Create binary/categorical factor columns
  for (col in c(time_var_binary, time_var_categorical)) {
    new_col_name <- paste0(col, "_factor")
    # Only factorize non-empty, non-NA values
    data[[new_col_name]] <- ifelse(
      is.na(data[[col]]) | data[[col]] == "",
      NA,
      data[[col]]
    )
    # Convert to factor only if has values
    if (any(!is.na(data[[new_col_name]]))) {
      data[[new_col_name]] <- as.factor(data[[new_col_name]])
    }
    message("[DUAL_COL] Created: ", new_col_name)
  }

  # Create date columns
  for (col in time_var_date) {
    new_col_name <- paste0(col, "_date")
    data[[new_col_name]] <- tryCatch({
      parsed <- parse_date_time(
        data[[col]],
        orders = c("ymd", "dmy", "mdy"),
        quiet = TRUE
      )
      as.Date(parsed)
    }, error = function(e) {
      rep(NA, nrow(data))
    })
    message("[DUAL_COL] Created: ", new_col_name)
  }

  total_created <- length(time_var_numeric) + length(time_var_binary) +
                   length(time_var_categorical) + length(time_var_date)

  message("[DUAL_COL] Created ", total_created, " analysis columns")
  message("[DUAL_COL] Complete!")

  return(data)
}


# ============================================================================
# TEST WITH REAL DATA
# ============================================================================

message("\n=== TESTING NEW FUNCTIONS WITH AUDIT REPORT DATA ===\n")

# Load data dictionary
dict <- read_csv("data_dictionary_enhanced.csv", show_col_types = FALSE)
message("Loaded enhanced dictionary: ", nrow(dict), " variables")

# Load raw audit report
raw_file <- "/Users/etaycohen/Documents/Sarcopenia/Audit report.csv"
if (!file.exists(raw_file)) {
  stop("Audit report.csv not found at: ", raw_file)
}

raw_data <- read_csv(raw_file, show_col_types = FALSE, col_types = cols(.default = "c"))
message("Loaded raw data: ", nrow(raw_data), " rows, ", ncol(raw_data), " columns")

# Apply basic cleaning (from current app.R)
# Remove section markers
section_markers <- c(
  "Personal Information FINAL",
  "Physician evaluation FINAL",
  "Physical Health Agility FINAL",
  "Cognitive Health Agility- Final",
  "Adverse events FINAL",
  "Body composition FINAL"
)
raw_data <- raw_data[, !(names(raw_data) %in% section_markers), drop = FALSE]
message("Removed section markers: ", ncol(raw_data), " columns remaining")

# Apply variable name mapping
message("\nApplying variable name mapping...")
mapping <- setNames(dict$new_name, dict$original_name)
for (old_name in names(raw_data)) {
  if (old_name %in% names(mapping)) {
    new_name <- mapping[[old_name]]
    names(raw_data)[names(raw_data) == old_name] <- new_name
  }
}
message("Applied mapping: ", ncol(raw_data), " columns")

# Remove duplicate identifier fields
dup_pattern <- "^demo_participants_study_number_v[2-9]|^demo_date_of_birth_.*v[2-9]"
dup_cols <- grep(dup_pattern, names(raw_data), value = TRUE)
if (length(dup_cols) > 0) {
  raw_data <- raw_data[, !(names(raw_data) %in% dup_cols), drop = FALSE]
  message("Removed ", length(dup_cols), " duplicate identifier columns")
}

# Split visits and adverse events (simplified - just test with all data for now)
test_data <- raw_data

message("\n=== TEST 1: convert_patient_level_na() ===\n")
test_after_na <- convert_patient_level_na(test_data, dict)

# Check specific test case: Patient 004-00232 education
message("\n--- Test Case: Patient 004-00232 Education ---")
patient_232 <- test_after_na %>% filter(id_client_id == "004-00232")
if (nrow(patient_232) > 0) {
  edu_col <- "demo_number_of_education_years"
  if (edu_col %in% names(patient_232)) {
    message("Education values after NA conversion:")
    print(patient_232 %>% select(id_client_id, id_visit_no, all_of(edu_col)))
  }
}

message("\n=== TEST 2: fill_time_invariant() ===\n")
test_after_fill <- fill_time_invariant(test_after_na, dict)

# Check filling worked
message("\n--- Test Case: Patient 004-00232 Education (After Filling) ---")
patient_232_filled <- test_after_fill %>% filter(id_client_id == "004-00232")
if (nrow(patient_232_filled) > 0) {
  edu_col <- "demo_number_of_education_years"
  if (edu_col %in% names(patient_232_filled)) {
    message("Education values after filling:")
    print(patient_232_filled %>% select(id_client_id, id_visit_no, all_of(edu_col)))
  }
}

message("\n=== TEST 3: create_analysis_columns() ===\n")
test_after_dual <- create_analysis_columns(test_after_fill, dict)

# Check dual columns created
message("\n--- Test Case: MoCA Score Dual Columns ---")
moca_col <- "cog_moca_total_score"
moca_num_col <- "cog_moca_total_score_numeric"

if (moca_col %in% names(test_after_dual)) {
  patient_232_dual <- test_after_dual %>% filter(id_client_id == "004-00232")

  if (moca_num_col %in% names(patient_232_dual)) {
    message("MoCA original vs numeric:")
    print(patient_232_dual %>%
      select(id_client_id, id_visit_no, all_of(moca_col), all_of(moca_num_col)))
  }
}

message("\n=== TESTS COMPLETE ===")
message("Final dataset: ", nrow(test_after_dual), " rows, ", ncol(test_after_dual), " columns")

# Save test output for inspection
write_csv(test_after_dual, "test_output.csv")
message("\nTest output saved to: test_output.csv")
message("You can inspect this file to verify the cleaning worked correctly")
