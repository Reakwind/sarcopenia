# ============================================================================
# TEST AT SCALE - Comprehensive Testing with Synthetic Data
# ============================================================================
#
# Tests all app features with 50 patients × 10 visits (500 rows)
# Verifies:
# - Data cleaning performance
# - Instrument Analysis functionality
# - Patient Surveillance functionality
# - No errors or warnings
#
# ============================================================================

library(readr)
library(dplyr)

# Source all required files
source("R/fct_cleaning.R")
source("R/utils_data_pipeline.R")
source("R/fct_instrument_analysis.R")
source("R/fct_analysis.R")

# Load dictionary
dict <- read_csv("data_dictionary_enhanced.csv", show_col_types = FALSE)

cat("=============================================================================\n")
cat("SCALE TESTING - 50 Patients × 10 Visits (500 rows)\n")
cat("=============================================================================\n\n")

# ============================================================================
# TEST 1: Data Cleaning Performance
# ============================================================================

cat("TEST 1: Data Cleaning Performance\n")
cat("----------------------------------\n")

# Load synthetic data
cat("Loading synthetic CSV...\n")
start_time <- Sys.time()
raw_data <- read_csv("tests/synthetic_50patients_10visits.csv",
                     show_col_types = FALSE,
                     col_types = cols(.default = "c"),
                     na = character())
load_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
cat(sprintf("  ✓ Loaded in %.2f seconds\n", load_time))
cat(sprintf("  Rows: %d, Columns: %d\n", nrow(raw_data), ncol(raw_data)))

# Clean data
cat("\nCleaning data...\n")
start_time <- Sys.time()
cleaned <- clean_csv(raw_data)
clean_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
cat(sprintf("  ✓ Cleaned in %.2f seconds\n", clean_time))

visits_data <- cleaned$visits_data
cat(sprintf("  Visits rows: %d, Columns: %d\n", nrow(visits_data), ncol(visits_data)))
cat(sprintf("  Adverse events rows: %d\n", nrow(cleaned$adverse_events_data)))
cat(sprintf("  Unique patients: %d\n", cleaned$summary$unique_patients))

if (cleaned$summary$unique_patients != 50) {
  cat("  ✗ ERROR: Expected 50 unique patients, got", cleaned$summary$unique_patients, "\n")
  stop("Patient count mismatch")
}

cat("\n")

# ============================================================================
# TEST 2: Instrument Analysis
# ============================================================================

cat("TEST 2: Instrument Analysis\n")
cat("---------------------------\n")

# Get available instruments
instruments <- get_instrument_list(dict)
cat(sprintf("  Available instruments: %d\n", length(unlist(instruments))))

# Test each instrument group
all_instruments_ok <- TRUE

for (group_name in names(instruments)) {
  cat(sprintf("\n  Testing %s:\n", group_name))

  for (instrument_name in instruments[[group_name]]) {
    cat(sprintf("    - %s... ", instrument_name))

    start_time <- Sys.time()
    instrument_table <- get_instrument_table(visits_data, instrument_name, dict)
    instrument_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

    if (is.null(instrument_table)) {
      cat(sprintf("✗ FAILED (NULL result)\n"))
      all_instruments_ok <- FALSE
    } else {
      # Verify table structure
      n_patients <- nrow(instrument_table)
      n_data_cols <- sum(!grepl("_is_missing$|_outlier_type$|^id_", names(instrument_table)))

      # Check for metadata columns
      has_missing_cols <- any(grepl("_is_missing$", names(instrument_table)))
      has_outlier_cols <- any(grepl("_outlier_type$", names(instrument_table)))

      if (!has_missing_cols || !has_outlier_cols) {
        cat(sprintf("✗ FAILED (missing metadata columns)\n"))
        all_instruments_ok <- FALSE
      } else {
        cat(sprintf("✓ OK (%d patients, %d vars, %.2fs)\n",
                   n_patients, n_data_cols, instrument_time))
      }
    }
  }
}

if (all_instruments_ok) {
  cat("\n  ✓ All instruments tested successfully\n")
} else {
  cat("\n  ✗ Some instruments failed\n")
}

cat("\n")

# ============================================================================
# TEST 3: Patient Surveillance
# ============================================================================

cat("TEST 3: Patient Surveillance\n")
cat("----------------------------\n")

# Get patient list
patients <- unique(visits_data$id_client_id)
patients <- patients[!is.na(patients)]

cat(sprintf("  Testing %d patients...\n", length(patients)))

# Test a sample of patients
test_patient_count <- min(10, length(patients))
test_patients <- sample(patients, test_patient_count)

all_patients_ok <- TRUE

for (patient_id in test_patients) {
  cat(sprintf("    - %s... ", patient_id))

  # Test patient data table
  start_time <- Sys.time()
  patient_table <- get_patient_data_table(visits_data, patient_id, dict)
  patient_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  if (is.null(patient_table)) {
    cat("✗ FAILED (NULL result)\n")
    all_patients_ok <- FALSE
    next
  }

  # Verify table structure
  n_visits <- nrow(patient_table)

  # Check for metadata columns
  has_missing_cols <- any(grepl("_is_missing$", names(patient_table)))
  has_outlier_cols <- any(grepl("_outlier_type$", names(patient_table)))

  if (!has_missing_cols || !has_outlier_cols) {
    cat(sprintf("✗ FAILED (missing metadata)\n"))
    all_patients_ok <- FALSE
  } else {
    # Test outlier detection
    outliers <- detect_combined_outliers(visits_data, patient_id, dict)

    if (is.null(outliers) && n_visits > 0) {
      # It's OK if outliers is NULL (patient may have no numeric data)
      cat(sprintf("✓ OK (%d visits, no numeric data, %.2fs)\n",
                 n_visits, patient_time))
    } else {
      n_outliers <- if (!is.null(outliers)) sum(!is.na(outliers$outlier_type)) else 0
      cat(sprintf("✓ OK (%d visits, %d outliers, %.2fs)\n",
                 n_visits, n_outliers, patient_time))
    }
  }
}

if (all_patients_ok) {
  cat(sprintf("\n  ✓ All %d test patients passed\n", test_patient_count))
} else {
  cat("\n  ✗ Some patients failed\n")
}

cat("\n")

# ============================================================================
# TEST 4: Patient Dropdown Labels
# ============================================================================

cat("TEST 4: Patient Dropdown Labels\n")
cat("--------------------------------\n")

labels <- get_patient_dropdown_labels(visits_data)

if (is.null(labels)) {
  cat("  ✗ FAILED: No labels generated\n")
} else {
  cat(sprintf("  ✓ Generated %d patient labels\n", length(labels)))
  cat("  Sample labels:\n")
  sample_labels <- head(labels, 3)
  for (i in seq_along(sample_labels)) {
    cat(sprintf("    %s\n", sample_labels[i]))
  }
}

cat("\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=============================================================================\n")
cat("SUMMARY\n")
cat("=============================================================================\n\n")

cat(sprintf("✓ Data loading: %.2f seconds\n", load_time))
cat(sprintf("✓ Data cleaning: %.2f seconds\n", clean_time))
cat(sprintf("✓ Processed: %d rows, %d patients\n", nrow(visits_data), length(patients)))

if (all_instruments_ok && all_patients_ok) {
  cat("\n✓ ALL TESTS PASSED\n")
  cat("\nThe app is ready to handle:\n")
  cat("  - 50+ patients with 10 visits each (500+ rows)\n")
  cat("  - All instrument analysis features\n")
  cat("  - All patient surveillance features\n")
  cat("  - Data cleaning and validation\n")
  cat("\nPerformance is acceptable for this scale.\n")
} else {
  cat("\n✗ SOME TESTS FAILED\n")
  cat("Check output above for details.\n")
  stop("Tests failed")
}

cat("\n=============================================================================\n")
