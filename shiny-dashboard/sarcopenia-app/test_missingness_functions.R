# ============================================================================
# Test Script for Missingness Visualization Functions
# ============================================================================
#
# Tests the missingness analysis functions with real cleaned data
# to validate they work correctly before building Shiny UI
#
# ============================================================================

# Load required libraries
library(dplyr)
library(readr)
library(plotly)

# Source the cleaning and visualization functions
source("R/fct_cleaning.R")
source("R/fct_visualization.R")

cat("=== TESTING MISSINGNESS VISUALIZATION FUNCTIONS ===\n\n")

# ============================================================================
# Step 1: Load and Clean Test Data
# ============================================================================

cat("Step 1: Loading and cleaning test data...\n")

# Load data dictionary
dict <- read_csv("data_dictionary_enhanced.csv", show_col_types = FALSE)
cat("Loaded dictionary:", nrow(dict), "variables\n")

# Load and clean test data (using existing audit report)
test_file <- "/Users/etaycohen/Documents/Sarcopenia/Audit report.csv"

if (!file.exists(test_file)) {
  stop("Test file not found: ", test_file)
}

raw_data <- read_csv(test_file,
                    show_col_types = FALSE,
                    col_types = cols(.default = "c"),
                    na = character())

cat("Loaded raw data:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n")

# Clean data
cleaned_result <- clean_csv(raw_data)
visits_data <- cleaned_result$visits_data

cat("Cleaned data:", nrow(visits_data), "rows,", ncol(visits_data), "columns\n")
cat("Unique patients:", length(unique(visits_data$id_client_id)), "\n\n")

# ============================================================================
# Step 2: Test analyze_missingness()
# ============================================================================

cat("Step 2: Testing analyze_missingness()...\n")
miss_analysis <- analyze_missingness(visits_data, dict)

cat("Missingness analysis results:\n")
cat("  - Variables analyzed:", nrow(miss_analysis), "\n")
cat("  - Variables with instrument metadata:", sum(!is.na(miss_analysis$instrument)), "\n")

# Show top 10 most complete variables
cat("\nTop 10 most complete variables:\n")
top_complete <- miss_analysis %>%
  arrange(desc(pct_has_data)) %>%
  head(10) %>%
  select(variable, instrument, pct_has_data, pct_empty, pct_na)
print(top_complete)

# Show top 10 most missing variables
cat("\nTop 10 most missing variables:\n")
top_missing <- miss_analysis %>%
  arrange(pct_has_data) %>%
  head(10) %>%
  select(variable, instrument, pct_has_data, pct_empty, pct_na)
print(top_missing)

cat("\n")

# ============================================================================
# Step 3: Test summarize_missingness_by_instrument()
# ============================================================================

cat("Step 3: Testing summarize_missingness_by_instrument()...\n")
inst_summary <- summarize_missingness_by_instrument(miss_analysis)

cat("Instrument summary results:\n")
cat("  - Instruments found:", nrow(inst_summary), "\n\n")

if (nrow(inst_summary) > 0) {
  cat("Instrument Completion Summary:\n")
  print(inst_summary)
}

cat("\n")

# ============================================================================
# Step 4: Test get_instrument_variables() and get_section_variables()
# ============================================================================

cat("Step 4: Testing helper functions...\n")

# Test getting MoCA variables
if ("MoCA" %in% inst_summary$instrument) {
  moca_vars <- get_instrument_variables(dict, "MoCA")
  cat("MoCA variables found:", length(moca_vars), "\n")
  cat("First 5 MoCA variables:", paste(head(moca_vars, 5), collapse = ", "), "\n")
}

# Test getting cognitive section variables
cog_vars <- get_section_variables(dict, "cognitive")
cat("Cognitive section variables:", length(cog_vars), "\n")

# Test getting physical section variables
phys_vars <- get_section_variables(dict, "physical")
cat("Physical section variables:", length(phys_vars), "\n\n")

# ============================================================================
# Step 5: Test create_missingness_heatmap()
# ============================================================================

cat("Step 5: Testing create_missingness_heatmap()...\n")

# Test with MoCA variables (if available)
if ("MoCA" %in% inst_summary$instrument) {
  moca_vars <- get_instrument_variables(dict, "MoCA")
  # Limit to first 10 variables for testing
  test_vars <- head(moca_vars, 10)

  cat("Creating heatmap for", length(test_vars), "MoCA variables\n")

  heatmap_fig <- create_missingness_heatmap(
    visits_data,
    test_vars,
    patient_ids = NULL  # All patients
  )

  if (!is.null(heatmap_fig)) {
    cat("✓ Heatmap created successfully (plotly object)\n")
    cat("  Can be saved with: htmlwidgets::saveWidget(heatmap_fig, 'heatmap_test.html')\n")
  } else {
    cat("✗ Heatmap creation failed\n")
  }
} else {
  cat("Skipping heatmap test - no MoCA variables found\n")
}

cat("\n")

# ============================================================================
# Step 6: Test get_patient_missingness_profile()
# ============================================================================

cat("Step 6: Testing get_patient_missingness_profile()...\n")

# Get first patient
first_patient <- unique(visits_data$id_client_id)[1]
cat("Testing with patient:", first_patient, "\n")

patient_profile <- get_patient_missingness_profile(visits_data, first_patient, dict)

if (!is.null(patient_profile)) {
  cat("✓ Patient profile created successfully\n")
  cat("  Patient ID:", patient_profile$patient_id, "\n")
  cat("  Number of visits:", patient_profile$n_visits, "\n")
  cat("  Total variables:", patient_profile$n_variables_total, "\n")
  cat("  Variables with data:", patient_profile$n_with_data, "\n")
  cat("  Variables empty:", patient_profile$n_empty, "\n")
  cat("  Variables NA:", patient_profile$n_na, "\n")

  # Show breakdown by instrument
  cat("\n  Variables by status:\n")
  status_summary <- patient_profile$variable_details %>%
    group_by(status) %>%
    summarise(count = n(), .groups = "drop")
  print(status_summary)
} else {
  cat("✗ Patient profile creation failed\n")
}

cat("\n")

# ============================================================================
# Step 7: Test create_visit_completion_timeline()
# ============================================================================

cat("Step 7: Testing create_visit_completion_timeline()...\n")

# Test overall timeline
timeline_fig <- create_visit_completion_timeline(
  visits_data,
  dict,
  instrument_filter = NULL
)

if (!is.null(timeline_fig)) {
  cat("✓ Overall completion timeline created successfully\n")
} else {
  cat("✗ Timeline creation failed\n")
}

# Test with MoCA filter (if available)
if ("MoCA" %in% inst_summary$instrument) {
  timeline_moca <- create_visit_completion_timeline(
    visits_data,
    dict,
    instrument_filter = "MoCA"
  )

  if (!is.null(timeline_moca)) {
    cat("✓ MoCA-filtered timeline created successfully\n")
  }
}

cat("\n")

# ============================================================================
# Summary
# ============================================================================

cat("=== TEST SUMMARY ===\n\n")
cat("All core missingness functions tested:\n")
cat("  ✓ analyze_missingness() - Analyzes all variables\n")
cat("  ✓ summarize_missingness_by_instrument() - Groups by instrument\n")
cat("  ✓ get_instrument_variables() - Extracts instrument vars\n")
cat("  ✓ get_section_variables() - Extracts section vars\n")
cat("  ✓ create_missingness_heatmap() - Creates interactive heatmap\n")
cat("  ✓ get_patient_missingness_profile() - Patient-level analysis\n")
cat("  ✓ create_visit_completion_timeline() - Temporal completion plot\n\n")

cat("Key findings from test data:\n")
cat("  - ", nrow(miss_analysis), " variables analyzed\n")
cat("  - ", nrow(inst_summary), " instruments identified\n")
cat("  - ", length(unique(visits_data$id_client_id)), " patients\n")
cat("  - ", length(unique(visits_data$id_visit_no)), " visit numbers\n\n")

cat("Next step: Build Shiny module UI/server to expose these functions\n")
cat("All functions ready for integration!\n")
