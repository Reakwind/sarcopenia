# ============================================================================
# DIAGNOSTIC: Column Comparison Tool
# ============================================================================
#
# Use this script to compare raw data columns vs cleaned data columns
# This helps identify if any variables are being lost during cleaning
#
# HOW TO USE:
# 1. Make sure you have your "Audit report.csv" file
# 2. Run this script in R console
# 3. Check the output to see what columns exist in raw vs cleaned
# ============================================================================

library(readr)
library(dplyr)

# Source the cleaning function
source("R/fct_cleaning.R")

# ===========================================================================
# FUNCTION 1: Compare Raw vs Cleaned Columns
# ===========================================================================

compare_columns <- function(raw_csv_path) {

  cat("\n=== DIAGNOSTIC: Column Comparison ===\n\n")

  # Read raw data
  cat("Reading raw data...\n")
  raw_data <- read_csv(raw_csv_path,
                       show_col_types = FALSE,
                       col_types = cols(.default = "c"),
                       na = character())

  cat("Raw data has", ncol(raw_data), "columns\n\n")

  # Clean data
  cat("Cleaning data...\n")
  cleaned <- clean_csv(raw_data)
  visits_data <- cleaned$visits_data

  cat("Cleaned data has", ncol(visits_data), "columns\n\n")

  # Get column names
  raw_cols <- names(raw_data)
  cleaned_cols <- names(visits_data)

  # Find columns in raw but not in cleaned (renamed or dropped)
  missing_from_cleaned <- raw_cols[!raw_cols %in% cleaned_cols]

  # Find columns in cleaned but not in raw (new analysis columns)
  new_in_cleaned <- cleaned_cols[!cleaned_cols %in% raw_cols]

  # Create results
  results <- list(
    raw_count = ncol(raw_data),
    cleaned_count = ncol(visits_data),
    raw_columns = raw_cols,
    cleaned_columns = cleaned_cols,
    missing_from_cleaned = missing_from_cleaned,
    new_in_cleaned = new_in_cleaned
  )

  # Print summary
  cat("=== SUMMARY ===\n")
  cat("Columns in raw data:", results$raw_count, "\n")
  cat("Columns in cleaned data:", results$cleaned_count, "\n")
  cat("Columns 'missing' from cleaned (likely renamed):", length(missing_from_cleaned), "\n")
  cat("New columns in cleaned (analysis columns):", length(new_in_cleaned), "\n\n")

  return(results)
}


# ===========================================================================
# FUNCTION 2: Find DSST-Related Columns
# ===========================================================================

find_dsst_columns <- function(raw_csv_path) {

  cat("\n=== FINDING DSST COLUMNS ===\n\n")

  # Read raw data
  raw_data <- read_csv(raw_csv_path,
                       show_col_types = FALSE,
                       col_types = cols(.default = "c"),
                       na = character())

  # Clean data
  cleaned <- clean_csv(raw_data)
  visits_data <- cleaned$visits_data

  # Find DSST columns in raw data
  cat("DSST-related columns in RAW data:\n")
  raw_dsst <- grep("dsst|dss|digit.*symbol|standard.*score",
                   names(raw_data),
                   ignore.case = TRUE,
                   value = TRUE)

  if (length(raw_dsst) > 0) {
    for (col in raw_dsst) {
      cat("  -", col, "\n")
    }
  } else {
    cat("  (none found)\n")
  }

  cat("\n")

  # Find DSST columns in cleaned data
  cat("DSST-related columns in CLEANED data:\n")
  cleaned_dsst <- grep("dsst|dss|digit.*symbol|standard.*score",
                       names(visits_data),
                       ignore.case = TRUE,
                       value = TRUE)

  if (length(cleaned_dsst) > 0) {
    for (col in cleaned_dsst) {
      cat("  -", col, "\n")
    }
  } else {
    cat("  (none found)\n")
  }

  cat("\n")

  # Check for standardized score specifically
  cat("Looking for 'Standardized Score' or 'Standard Score' columns:\n")
  standard_raw <- grep("standard", names(raw_data), ignore.case = TRUE, value = TRUE)
  standard_cleaned <- grep("standard", names(visits_data), ignore.case = TRUE, value = TRUE)

  cat("In RAW data:\n")
  if (length(standard_raw) > 0) {
    for (col in standard_raw) {
      cat("  -", col, "\n")
    }
  } else {
    cat("  (none found)\n")
  }

  cat("\nIn CLEANED data:\n")
  if (length(standard_cleaned) > 0) {
    for (col in standard_cleaned) {
      cat("  -", col, "\n")
    }
  } else {
    cat("  (none found)\n")
  }

  return(list(
    raw_dsst = raw_dsst,
    cleaned_dsst = cleaned_dsst,
    raw_standard = standard_raw,
    cleaned_standard = standard_cleaned
  ))
}


# ===========================================================================
# FUNCTION 3: Search for Any Column by Pattern
# ===========================================================================

search_columns <- function(raw_csv_path, pattern) {

  cat("\n=== SEARCHING FOR:", pattern, "===\n\n")

  # Read raw data
  raw_data <- read_csv(raw_csv_path,
                       show_col_types = FALSE,
                       col_types = cols(.default = "c"),
                       na = character())

  # Clean data
  cleaned <- clean_csv(raw_data)
  visits_data <- cleaned$visits_data

  # Search in raw
  raw_matches <- grep(pattern, names(raw_data), ignore.case = TRUE, value = TRUE)

  # Search in cleaned
  cleaned_matches <- grep(pattern, names(visits_data), ignore.case = TRUE, value = TRUE)

  cat("Matches in RAW data (", length(raw_matches), "):\n")
  if (length(raw_matches) > 0) {
    for (col in raw_matches) {
      cat("  -", col, "\n")
    }
  } else {
    cat("  (none found)\n")
  }

  cat("\nMatches in CLEANED data (", length(cleaned_matches), "):\n")
  if (length(cleaned_matches) > 0) {
    for (col in cleaned_matches) {
      cat("  -", col, "\n")
    }
  } else {
    cat("  (none found)\n")
  }

  return(list(
    raw_matches = raw_matches,
    cleaned_matches = cleaned_matches
  ))
}


# ===========================================================================
# USAGE EXAMPLES
# ===========================================================================

cat("\n=== HOW TO USE THIS DIAGNOSTIC TOOL ===\n\n")
cat("1. Set the path to your raw CSV file:\n")
cat("   raw_csv <- 'path/to/your/Audit report.csv'\n\n")
cat("2. Run full column comparison:\n")
cat("   results <- compare_columns(raw_csv)\n\n")
cat("3. Find DSST columns specifically:\n")
cat("   dsst_results <- find_dsst_columns(raw_csv)\n\n")
cat("4. Search for any pattern:\n")
cat("   search_columns(raw_csv, 'moca')\n")
cat("   search_columns(raw_csv, 'percentile')\n")
cat("   search_columns(raw_csv, 'z.score')\n\n")
cat("5. To save column lists to file:\n")
cat("   results <- compare_columns(raw_csv)\n")
cat("   writeLines(results$raw_columns, 'raw_columns.txt')\n")
cat("   writeLines(results$cleaned_columns, 'cleaned_columns.txt')\n\n")
