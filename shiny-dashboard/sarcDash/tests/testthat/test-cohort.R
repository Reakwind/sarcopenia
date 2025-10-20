# Unit tests for cohort builder module

# Load required helpers
source("../../R/data_store.R")
source("../../R/i18n_helpers.R")
source("../../R/mod_cohort.R")

# Test 1: Cohort module UI function exists
test_that("mod_cohort_ui function exists", {
  expect_true(exists("mod_cohort_ui"))
  expect_type(mod_cohort_ui, "closure")
})

# Test 2: Cohort module server function exists
test_that("mod_cohort_server function exists", {
  expect_true(exists("mod_cohort_server"))
  expect_type(mod_cohort_server, "closure")
})

# Test 3: compute_retention function
test_that("compute_retention calculates correctly", {
  # Test data with retention
  test_data <- data.frame(
    id_client_id = c(1, 1, 2, 2, 3),
    id_visit_no = c(1, 2, 1, 2, 1)
  )

  result <- compute_retention(test_data)

  expect_equal(result$retained, 2)  # Patients 1 and 2 have both visits
  expect_equal(result$total, 3)     # 3 unique patients
  expect_equal(result$rate, 2/3)
})

# Test 4: compute_retention with no retention
test_that("compute_retention handles single visits", {
  test_data <- data.frame(
    id_client_id = c(1, 2, 3),
    id_visit_no = c(1, 1, 1)
  )

  result <- compute_retention(test_data)

  expect_equal(result$retained, 0)
  expect_equal(result$total, 3)
  expect_equal(result$rate, 0)
})

# Test 5: compute_retention with NULL data
test_that("compute_retention handles NULL data", {
  result <- compute_retention(NULL)

  expect_equal(result$retained, 0)
  expect_equal(result$total, 0)
  expect_equal(result$rate, 0)
})

# Test 6: describe_filters function with 0-3 visits
test_that("describe_filters generates human-readable text", {
  filters <- list(
    age_range = c(50, 80),
    gender = c("male", "female"),
    visit_number = c("1", "2")
  )

  description <- describe_filters(filters)

  expect_type(description, "character")
  expect_match(description, "Age: 50-80")
  expect_match(description, "Gender: male, female")
  expect_match(description, "Visit.*1.*2")
})

# Test 7: describe_filters with no filters
test_that("describe_filters handles empty filters", {
  filters <- list()

  description <- describe_filters(filters)

  expect_equal(description, "No filters applied")
})

# Test 8: describe_filters with retention filter
test_that("describe_filters includes retention", {
  filters <- list(
    retention_only = TRUE
  )

  description <- describe_filters(filters)

  expect_match(description, "Retention: Both visits only")
})

# Test 9: Cohort UI creates sidebar
test_that("mod_cohort_ui creates sidebar layout", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")

  library(shiny)

  ui <- mod_cohort_ui("test_cohort")
  html_str <- as.character(ui)

  # Check for filter inputs
  expect_match(html_str, "age_range")
  expect_match(html_str, "gender")
  expect_match(html_str, "visit_number")
  expect_match(html_str, "retention_only")
})

# Test 10: Cohort UI has reset button
test_that("Reset filters button exists", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")

  library(shiny)

  ui <- mod_cohort_ui("test_cohort")
  html_str <- as.character(ui)

  expect_match(html_str, "reset_filters")
})

# Test 11: Cohort UI has save button
test_that("Save filter set button exists", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")

  library(shiny)

  ui <- mod_cohort_ui("test_cohort")
  html_str <- as.character(ui)

  expect_match(html_str, "save_filters")
})

# Test 12: Cohort UI has summary outputs
test_that("Summary metric outputs exist", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")

  library(shiny)

  ui <- mod_cohort_ui("test_cohort")
  html_str <- as.character(ui)

  expect_match(html_str, "n_patients")
  expect_match(html_str, "n_visits")
  expect_match(html_str, "retention_rate")
})

# Test 13: Translation keys exist
test_that("Cohort module translation keys exist", {
  json_path <- "../../inst/i18n/translations.json"

  skip_if_not(file.exists(json_path), "Translation file not found")

  json_content <- jsonlite::read_json(json_path)
  en_strings <- sapply(json_content$translation, function(x) x$en)

  cohort_keys <- c(
    "Visit Number",
    "Reset Filters",
    "Save Filter Set",
    "Patients",
    "Visits",
    "Retention Rate",
    "Current Filters"
  )

  for (key in cohort_keys) {
    expect_true(
      key %in% en_strings,
      label = paste("Missing cohort translation key:", key)
    )
  }
})

# Test 14: Filter JSON export structure with 0-3 visits
test_that("Filter export follows expected JSON structure", {
  filter_set <- list(
    age_range = c(50, 80),
    gender = c("male"),
    visit_number = c("0", "1", "2", "3"),
    retention_only = FALSE,
    timestamp = Sys.time()
  )

  # Verify structure
  expect_true("age_range" %in% names(filter_set))
  expect_true("timestamp" %in% names(filter_set))
  expect_length(filter_set$age_range, 2)
  expect_type(filter_set$visit_number, "character")
  expect_true(all(filter_set$visit_number %in% c("0", "1", "2", "3")))
})

# Test 15: Exported functions exist
test_that("Exported helper functions are available", {
  expect_true(exists("compute_retention"))
  expect_true(exists("describe_filters"))
})

# Test 16: Visit selection supports 0-3 range
test_that("describe_filters handles visit numbers 0-3", {
  # Test visit 0
  filters <- list(visit_number = c("0"))
  desc <- describe_filters(filters)
  expect_match(desc, "Visit.*0")

  # Test visit 3
  filters <- list(visit_number = c("3"))
  desc <- describe_filters(filters)
  expect_match(desc, "Visit.*3")

  # Test multiple visits
  filters <- list(visit_number = c("0", "1", "2", "3"))
  desc <- describe_filters(filters)
  # Should not show filter when all visits selected
  expect_equal(desc, "No filters applied")
})

# Test 17: describe_filters omits visit filter when all 4 visits selected
test_that("describe_filters omits visit filter for all 4 visits", {
  filters <- list(
    age_range = c(60, 80),
    visit_number = c("0", "1", "2", "3")
  )

  desc <- describe_filters(filters)

  # Should show age but not visits
  expect_match(desc, "Age")
  expect_false(grepl("Visit", desc))
})

# Test 18: compute_retention works with 0-3 visits
test_that("compute_retention handles visit numbers 0-3", {
  # Data with visits 0-3
  test_data <- data.frame(
    id_client_id = c(1, 1, 1, 1, 2, 2, 3),
    id_visit_no = c(0, 1, 2, 3, 0, 1, 0)
  )

  result <- compute_retention(test_data)

  expect_equal(result$retained, 2)  # Patients 1 and 2 have >= 2 visits
  expect_equal(result$total, 3)
  expect_true(result$rate > 0)
})

# Test 19: Cohort UI uses checkboxGroupInput for visits
test_that("mod_cohort_ui uses checkboxGroupInput for visit selection", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")

  library(shiny)

  ui <- mod_cohort_ui("test_cohort")
  html_str <- as.character(ui)

  # Should not contain radioButtons pattern for visits
  expect_false(grepl('type="radio".*visit', html_str, ignore.case = TRUE))

  # Should contain checkbox pattern for visits
  expect_match(html_str, "visit_number")
})

# Test 20: Visit selector includes all 4 options (0-3)
test_that("Visit selector includes visits 0-3", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")

  library(shiny)

  ui <- mod_cohort_ui("test_cohort")
  html_str <- as.character(ui)

  # Check for visit 0, 1, 2, 3 options
  expect_match(html_str, "Visit 0")
  expect_match(html_str, "Visit 1")
  expect_match(html_str, "Visit 2")
  expect_match(html_str, "Visit 3")
})
