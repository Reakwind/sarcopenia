# Comprehensive Functionality Test for sarcDash
# Tests all major features, tabs, and data flows

# Load package from source
if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
} else {
  library(sarcDash)
}

cat("=== SARCDASH FUNCTIONALITY TEST ===\n\n")

# Test 1: Data Loading
cat("1. Testing data loading...\n")

# Set development mode for proper path resolution
options("golem.app.prod" = FALSE)

test_data <- tryCatch({
  # Try development path first
  data_dir <- here::here("data")
  if (!dir.exists(data_dir)) {
    # Try inst/extdata
    data_dir <- system.file("extdata", package = "sarcDash")
  }
  ds_connect(data_dir)
}, error = function(e) {
  list(error = e$message)
})

if (!is.null(test_data$error)) {
  cat("  ✗ FAIL: Data loading error:", test_data$error, "\n")
} else {
  cat("  ✓ PASS: Data loaded successfully\n")
  cat("    - Visits data:", nrow(test_data$visits), "rows,", ncol(test_data$visits), "columns\n")
  cat("    - AE data:", if(!is.null(test_data$ae)) nrow(test_data$ae) else 0, "rows\n")
  cat("    - Dictionary:", if(!is.null(test_data$dict)) nrow(test_data$dict) else 0, "entries\n")
}

# Test 2: Data Status
cat("\n2. Testing data status check...\n")
status <- ds_status()
if (!is.null(status)) {
  cat("  ✓ PASS: Status check works\n")
  cat("    - Health:", status$health, "\n")
  cat("    - Message:", status$message, "\n")
} else {
  cat("  ✗ FAIL: Status check failed\n")
}

# Test 3: Column Prefixes for Domains
cat("\n3. Testing domain column detection...\n")
if (!is.null(test_data$visits)) {
  domains <- list(
    demographics = list(data = test_data$visits, prefix = "demo_"),
    cognitive = list(data = test_data$visits, prefix = "cog_"),
    medical = list(data = test_data$visits, prefix = "med_"),
    physical = list(data = test_data$visits, prefix = "phys_"),
    adherence = list(data = test_data$visits, prefix = "adh_"),
    adverse_events = list(data = test_data$ae, prefix = "ae_")
  )

  for (domain_name in names(domains)) {
    data_source <- domains[[domain_name]]$data
    prefix <- domains[[domain_name]]$prefix

    if (is.null(data_source)) {
      cat("  ✗", domain_name, ": Data source not loaded\n")
      next
    }

    cols <- grep(paste0("^", prefix), names(data_source), value = TRUE)
    if (length(cols) > 0) {
      cat("  ✓", domain_name, ":", length(cols), "columns found\n")
    } else {
      cat("  ✗", domain_name, ": No columns found (expected", prefix, "prefix)\n")
    }
  }
}

# Test 4: Required Columns
cat("\n4. Testing required columns for cohort filtering...\n")
required_cols <- c("id_client_id", "id_visit_no", "id_age", "id_gender",
                   "cog_moca_total_score", "cog_dsst_score")
if (!is.null(test_data$visits)) {
  for (col in required_cols) {
    if (col %in% names(test_data$visits)) {
      cat("  ✓", col, "exists\n")
    } else {
      cat("  ✗", col, "MISSING\n")
    }
  }
}

# Test 5: Data Ranges for Filters
cat("\n5. Testing data ranges for filter defaults...\n")
if (!is.null(test_data$visits)) {
  cat("  Age range:", min(test_data$visits$id_age, na.rm = TRUE),
      "to", max(test_data$visits$id_age, na.rm = TRUE), "\n")

  if ("cog_moca_total_score" %in% names(test_data$visits)) {
    moca_vals <- test_data$visits$cog_moca_total_score[!is.na(test_data$visits$cog_moca_total_score)]
    cat("  MoCA range:", min(moca_vals), "to", max(moca_vals), "\n")
  }

  if ("cog_dsst_score" %in% names(test_data$visits)) {
    dsst_vals <- test_data$visits$cog_dsst_score[!is.na(test_data$visits$cog_dsst_score)]
    cat("  DSST range:", min(dsst_vals), "to", max(dsst_vals), "\n")
  }

  cat("  Genders:", paste(unique(test_data$visits$id_gender), collapse = ", "), "\n")
  cat("  Visit numbers:", paste(sort(unique(test_data$visits$id_visit_no)), collapse = ", "), "\n")
}

# Test 6: Retention Calculation
cat("\n6. Testing retention metric calculation...\n")
if (!is.null(test_data$visits)) {
  retention <- compute_retention(test_data$visits)
  cat("  ✓ Retention calculation works\n")
  cat("    - Total patients:", retention$total, "\n")
  cat("    - Retained (2+ visits):", retention$retained, "\n")
  cat("    - Retention rate:", round(retention$rate * 100, 1), "%\n")
}

# Test 7: i18n (Translation) System
cat("\n7. Testing translation system...\n")
i18n <- init_i18n()
if (!is.null(i18n)) {
  cat("  ✓ i18n initialized\n")

  # Test English
  i18n$set_translation_language("en")
  en_text <- i18n$t("Home")
  cat("    - English: 'Home' ->", en_text, "\n")

  # Test Hebrew
  i18n$set_translation_language("he")
  he_text <- i18n$t("Home")
  cat("    - Hebrew: 'Home' ->", he_text, "\n")

  # Test RTL detection
  cat("    - RTL for Hebrew:", is_rtl("he"), "\n")
  cat("    - RTL for English:", is_rtl("en"), "\n")
}

# Test 8: CSV Upload Validation
cat("\n8. Testing CSV upload validation...\n")
if (!is.null(test_data$visits)) {
  # Create a temporary CSV with valid data
  temp_csv <- tempfile(fileext = ".csv")
  sample_data <- head(test_data$visits, 10)
  readr::write_csv(sample_data, temp_csv)

  loaded <- tryCatch({
    ds_load_csv(temp_csv)
  }, error = function(e) {
    list(error = e$message)
  })

  if (!is.null(loaded$error)) {
    cat("  ✗ FAIL: CSV loading error:", loaded$error, "\n")
  } else {
    cat("  ✓ PASS: CSV loading works\n")
    cat("    - Loaded rows:", nrow(loaded), "\n")
  }

  unlink(temp_csv)
}

# Test 9: Cohort Filtering Logic
cat("\n9. Testing cohort filtering logic...\n")
if (!is.null(test_data$visits)) {
  visits <- test_data$visits

  # Test age filter
  filtered <- dplyr::filter(visits, id_age >= 60, id_age <= 80)
  cat("  Age filter (60-80):", nrow(filtered), "of", nrow(visits), "rows\n")

  # Test gender filter
  filtered <- dplyr::filter(visits, tolower(id_gender) %in% c("male"))
  cat("  Gender filter (male):", nrow(filtered), "of", nrow(visits), "rows\n")

  # Test visit filter
  filtered <- dplyr::filter(visits, id_visit_no %in% c(0, 1))
  cat("  Visit filter (0,1):", nrow(filtered), "of", nrow(visits), "rows\n")

  # Test retention filter
  visit_counts <- dplyr::count(visits, id_client_id)
  retained_patients <- dplyr::filter(visit_counts, n >= 2)
  retained_patients <- dplyr::pull(retained_patients, id_client_id)
  filtered <- dplyr::filter(visits, id_client_id %in% retained_patients)
  cat("  Retention filter (2+ visits):", nrow(filtered), "of", nrow(visits), "rows\n")
}

# Test 10: Module UI Generation (using internal functions)
cat("\n10. Testing module UI generation...\n")
ui_tests <- list(
  home = tryCatch({ sarcDash:::mod_home_ui("test", i18n); TRUE }, error = function(e) e$message),
  cohort = tryCatch({ sarcDash:::mod_cohort_ui("test", i18n); TRUE }, error = function(e) e$message),
  dictionary = tryCatch({ sarcDash:::mod_dictionary_ui("test", i18n); TRUE }, error = function(e) e$message),
  domain = tryCatch({ sarcDash:::mod_domain_ui("test", "demographics", i18n); TRUE }, error = function(e) e$message)
)

for (module_name in names(ui_tests)) {
  result <- ui_tests[[module_name]]
  if (isTRUE(result)) {
    cat("  ✓", module_name, "UI renders\n")
  } else {
    cat("  ✗", module_name, "UI error:", result, "\n")
  }
}

# Summary
cat("\n=== TEST SUMMARY ===\n")
cat("All core functionality components tested.\n")
cat("Review output above for any FAIL markers.\n")
cat("\nTo test interactively, run: sarcDash::run_app()\n")
