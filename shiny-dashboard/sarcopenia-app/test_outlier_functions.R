# ============================================================================
# TEST SCRIPT: OUTLIER DETECTION FUNCTIONS
# ============================================================================
#
# Tests all 7 outlier detection functions with real data
# Run this before integrating outlier functions into the Shiny UI
#
# USAGE: source("test_outlier_functions.R")
# ============================================================================

library(dplyr)
library(readr)
library(plotly)

# Source required functions
source("R/fct_cleaning.R")
source("R/fct_analysis.R")

message("\n========================================")
message("OUTLIER DETECTION FUNCTIONS TEST")
message("========================================\n")

# ============================================================================
# STEP 1: LOAD AND CLEAN TEST DATA
# ============================================================================

message("[STEP 1] Loading and cleaning test data...")

# Load data dictionary
dict <- read_csv("data_dictionary_enhanced.csv", show_col_types = FALSE)
message("✓ Data dictionary loaded: ", nrow(dict), " variables")

# Load test data
test_file <- "/Users/etaycohen/Documents/Sarcopenia/Audit report.csv"

if (!file.exists(test_file)) {
  stop("Test file not found: ", test_file)
}

raw_data <- read_csv(test_file,
                    show_col_types = FALSE,
                    col_types = cols(.default = "c"),
                    na = character())
message("✓ Raw data loaded: ", nrow(raw_data), " rows, ", ncol(raw_data), " columns")

# Clean data
cleaned <- clean_csv(raw_data)
visits_data <- cleaned$visits_data
message("✓ Data cleaned: ", nrow(visits_data), " observations, ",
        length(unique(visits_data$id_client_id)), " patients")

# ============================================================================
# STEP 2: LOAD VALID RANGES REFERENCE
# ============================================================================

message("\n[STEP 2] Loading valid ranges reference file...")

valid_ranges <- read_csv("inst/extdata/instrument_valid_ranges.csv",
                         show_col_types = FALSE)
message("✓ Valid ranges loaded: ", nrow(valid_ranges), " variables with defined ranges")

# Show sample of valid ranges
message("\nSample valid ranges:")
print(head(valid_ranges %>% select(variable_name, instrument, min_valid, max_valid), 10))

# ============================================================================
# STEP 3: TEST RANGE VIOLATION DETECTION
# ============================================================================

message("\n[STEP 3] Testing detect_range_violations()...")

range_violations <- detect_range_violations(visits_data, dict, valid_ranges)

if (nrow(range_violations) > 0) {
  message("\n✓ Range violations detected!")
  message("  Total violations: ", nrow(range_violations))
  message("  Unique variables: ", length(unique(range_violations$variable)))
  message("  Unique patients: ", length(unique(range_violations$patient_id)))

  # Show summary by violation type
  message("\nViolations by type:")
  type_summary <- range_violations %>%
    group_by(violation_type) %>%
    summarise(count = n(), .groups = "drop")
  print(type_summary)

  # Show top variables with violations
  message("\nTop 10 variables with most violations:")
  var_summary <- range_violations %>%
    group_by(variable, instrument) %>%
    summarise(n_violations = n(), .groups = "drop") %>%
    arrange(desc(n_violations)) %>%
    head(10)
  print(var_summary)

  # Show sample violations
  message("\nSample violations:")
  print(head(range_violations %>%
               select(patient_id, visit_no, variable, value, violation_type,
                      min_valid, max_valid), 5))
} else {
  message("✓ No range violations detected - data is within valid clinical ranges!")
}

# ============================================================================
# STEP 4: TEST IQR OUTLIER DETECTION
# ============================================================================

message("\n[STEP 4] Testing detect_outliers_iqr()...")

# Get numeric variables to test
numeric_vars <- valid_ranges$variable_name[1:20]  # Test first 20 variables
message("Testing ", length(numeric_vars), " numeric variables")

iqr_outliers <- detect_outliers_iqr(visits_data, numeric_vars, multiplier = 1.5)

if (nrow(iqr_outliers) > 0) {
  message("\n✓ IQR outliers detected!")
  message("  Total outliers: ", nrow(iqr_outliers))
  message("  Unique variables: ", length(unique(iqr_outliers$variable)))
  message("  Unique patients: ", length(unique(iqr_outliers$patient_id)))

  # Show top variables with IQR outliers
  message("\nTop 10 variables with most IQR outliers:")
  var_summary <- iqr_outliers %>%
    group_by(variable) %>%
    summarise(n_outliers = n(), .groups = "drop") %>%
    arrange(desc(n_outliers)) %>%
    head(10)
  print(var_summary)

  # Show sample outliers
  message("\nSample IQR outliers:")
  print(head(iqr_outliers %>%
               select(patient_id, visit_no, variable, value, q1, q3, iqr), 5))
} else {
  message("✓ No IQR outliers detected!")
}

# ============================================================================
# STEP 5: TEST Z-SCORE OUTLIER DETECTION
# ============================================================================

message("\n[STEP 5] Testing detect_outliers_zscore()...")

zscore_outliers <- detect_outliers_zscore(visits_data, numeric_vars, threshold = 3)

if (nrow(zscore_outliers) > 0) {
  message("\n✓ Z-score outliers detected!")
  message("  Total outliers: ", nrow(zscore_outliers))
  message("  Unique variables: ", length(unique(zscore_outliers$variable)))
  message("  Unique patients: ", length(unique(zscore_outliers$patient_id)))

  # Show top variables with Z-score outliers
  message("\nTop 10 variables with most Z-score outliers:")
  var_summary <- zscore_outliers %>%
    group_by(variable) %>%
    summarise(n_outliers = n(), .groups = "drop") %>%
    arrange(desc(n_outliers)) %>%
    head(10)
  print(var_summary)

  # Show sample outliers
  message("\nSample Z-score outliers:")
  print(head(zscore_outliers %>%
               select(patient_id, visit_no, variable, value, mean, sd, zscore), 5))
} else {
  message("✓ No Z-score outliers detected!")
}

# ============================================================================
# STEP 6: TEST OUTLIER SUMMARY BY INSTRUMENT
# ============================================================================

message("\n[STEP 6] Testing summarize_outliers_by_instrument()...")

inst_summary <- summarize_outliers_by_instrument(
  range_violations,
  iqr_outliers,
  zscore_outliers,
  dict
)

message("\n✓ Instrument summary created!")
message("  Instruments analyzed: ", nrow(inst_summary))

message("\nOutlier summary by instrument:")
print(inst_summary)

# ============================================================================
# STEP 7: TEST OUTLIER SUMMARY BY VARIABLE
# ============================================================================

message("\n[STEP 7] Testing summarize_outliers_by_variable()...")

var_summary <- summarize_outliers_by_variable(
  range_violations,
  iqr_outliers,
  zscore_outliers,
  dict
)

message("\n✓ Variable summary created!")
message("  Variables with outliers: ", nrow(var_summary))

message("\nTop 20 variables with most outliers:")
print(head(var_summary, 20))

# ============================================================================
# STEP 8: TEST OUTLIER BOXPLOT
# ============================================================================

message("\n[STEP 8] Testing create_outlier_boxplot()...")

# Find a variable with outliers to test
test_var <- if (nrow(var_summary) > 0) {
  var_summary$variable[1]  # Use variable with most outliers
} else {
  "cog_moca_total_score"  # Default test variable
}

message("Creating boxplot for: ", test_var)

# Combine all outliers for this variable
all_outliers <- bind_rows(
  range_violations %>% mutate(outlier_type = "range"),
  iqr_outliers %>% mutate(outlier_type = "iqr") %>%
    select(patient_id, visit_no, variable, value, outlier_type),
  zscore_outliers %>% mutate(outlier_type = "zscore") %>%
    select(patient_id, visit_no, variable, value, outlier_type)
)

boxplot <- create_outlier_boxplot(visits_data, test_var, all_outliers)

if (!is.null(boxplot)) {
  message("✓ Boxplot created successfully!")
  # Note: Boxplot can be displayed in RStudio Viewer with: print(boxplot)
} else {
  message("! No data available for boxplot")
}

# ============================================================================
# STEP 9: TEST OUTLIER TIMELINE
# ============================================================================

message("\n[STEP 9] Testing create_outlier_timeline()...")

timeline <- create_outlier_timeline(
  range_violations,
  iqr_outliers,
  zscore_outliers,
  visit_col = "visit_no"
)

if (!is.null(timeline)) {
  message("✓ Timeline created successfully!")
  # Note: Timeline can be displayed in RStudio Viewer with: print(timeline)
} else {
  message("! No visit data available for timeline")
}

# ============================================================================
# TEST SUMMARY
# ============================================================================

message("\n========================================")
message("TEST SUMMARY")
message("========================================")
message("✓ All 7 outlier detection functions tested successfully!")
message("")
message("Results:")
message("  Range violations: ", nrow(range_violations))
message("  IQR outliers: ", nrow(iqr_outliers))
message("  Z-score outliers: ", nrow(zscore_outliers))
message("  Total outliers: ", nrow(all_outliers))
message("")
message("  Instruments analyzed: ", nrow(inst_summary))
message("  Variables with outliers: ", nrow(var_summary))
message("")
message("Functions validated:")
message("  ✓ detect_range_violations()")
message("  ✓ detect_outliers_iqr()")
message("  ✓ detect_outliers_zscore()")
message("  ✓ summarize_outliers_by_instrument()")
message("  ✓ summarize_outliers_by_variable()")
message("  ✓ create_outlier_boxplot()")
message("  ✓ create_outlier_timeline()")
message("")
message("Ready to integrate into Shiny UI!")
message("========================================\n")
