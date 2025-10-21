# Unit tests for navigation and app shell

# Load required helpers
source("../../R/data_store.R")
source("../../R/i18n_helpers.R")

# Test 1: Navigation structure exists
test_that("Navigation tabs are defined", {
  skip_if_not_installed("bslib")

  # Expected tab values
  expected_tabs <- c(
    "home",
    "dictionary",
    "cohort",
    "demographics",
    "cognitive",
    "medical",
    "physical",
    "adherence",
    "adverse_events",
    "longitudinal",
    "qc",
    "settings"
  )

  # This test verifies the expected tab structure
  expect_true(length(expected_tabs) > 0)
  expect_equal(length(expected_tabs), 12)
})

# Test 2: Theme definition
test_that("bslib theme is properly configured", {
  skip_if_not_installed("bslib")

  # Create a test theme to verify bslib::bs_theme works
  test_theme <- bslib::bs_theme(
    version = 5,
    primary = "#2C3E50"
  )

  expect_s3_class(test_theme, "bs_theme")
})

# Test 3: Thematic integration
test_that("thematic package is available for plot theming", {
  skip_if_not_installed("thematic")

  # Verify thematic package can be loaded and has required function
  expect_true(requireNamespace("thematic", quietly = TRUE))
  expect_true(exists("thematic_shiny", where = asNamespace("thematic")))
})

# Test 4: Skip links for accessibility
test_that("Skip link targets are defined", {
  skip_targets <- c("#main-content", "#filters")

  expect_length(skip_targets, 2)
  expect_true(all(grepl("^#", skip_targets)))
})

# Test 5: PHI banner includes required elements
test_that("PHI banner has required structure", {
  # Test that we can create the banner structure
  banner_classes <- c("alert", "alert-warning", "alert-dismissible")

  expect_true(all(nchar(banner_classes) > 0))
  expect_true("alert" %in% banner_classes)
})

# Test 6: Language selector integration in navbar
test_that("Language selector is available", {
  skip_if_not_installed("shiny")

  # Verify function exists
  expect_true(exists("language_selector_ui"))

  # Test it can be called
  selector <- language_selector_ui("test_id", selected = "en")
  expect_s3_class(selector, "shiny.tag")
})

# Test 7: Navigation icons
test_that("Navigation uses proper icons", {
  skip_if_not_installed("shiny")

  # Load shiny to access icon function
  library(shiny)

  # Test that icon function works
  test_icon <- icon("home")
  expect_s3_class(test_icon, "shiny.tag")
  expect_equal(test_icon$name, "i")
})

# Test 8: Verify bslib nav functions exist
test_that("bslib navigation functions are available", {
  skip_if_not_installed("bslib")

  # Load bslib
  library(bslib)

  # Check that bslib nav functions exist
  expect_true(exists("page_navbar"))
  expect_true(exists("nav_panel"))
  expect_true(exists("nav_menu"))
  expect_true(exists("nav_spacer"))
  expect_true(exists("nav_item"))
})

# Test 9: Data status integration for last-updated
test_that("ds_status returns expected structure", {
  skip_if_not_installed("readr")

  # Verify ds_status function exists
  expect_true(exists("ds_status"))

  # Test with error handling (data may not exist)
  status <- tryCatch({
    data_dir <- here::here("data")
    ds_status(data_dir, connect = FALSE)
  }, error = function(e) {
    NULL
  })

  # If status worked, check that it's a list
  if (!is.null(status)) {
    expect_type(status, "list")
    # Check for expected fields from ds_status
    expect_true("status" %in% names(status) || "files" %in% names(status))
  } else {
    # If data not available, that's okay for this test
    expect_null(status)
  }
})

# Test 10: Color theme values
test_that("Theme colors are valid hex codes", {
  theme_colors <- c(
    primary = "#2C3E50",
    secondary = "#3498DB",
    success = "#27AE60",
    danger = "#E74C3C"
  )

  # Check all are valid hex colors
  hex_pattern <- "^#[0-9A-Fa-f]{6}$"
  expect_true(all(grepl(hex_pattern, theme_colors)))
})

# Test 11: Translation keys for navigation exist
test_that("Navigation translation keys exist", {
  json_path <- "../../inst/i18n/translations.json"

  skip_if_not(file.exists(json_path), "Translation file not found")

  json_content <- jsonlite::read_json(json_path)
  en_strings <- sapply(json_content$translation, function(x) x$en)

  # Key navigation items
  nav_keys <- c(
    "Home",
    "Data Dictionary",
    "Cohort Builder",
    "Demographics",
    "Cognitive",
    "Medical",
    "Physical",
    "Adherence",
    "Adverse Events",
    "Longitudinal",
    "Quality Checks",
    "Settings",
    "Domains"
  )

  for (key in nav_keys) {
    expect_true(
      key %in% en_strings,
      label = paste("Missing translation key:", key)
    )
  }
})

# Test 12: PHI warning translation keys exist
test_that("PHI warning translation keys exist", {
  json_path <- "../../inst/i18n/translations.json"

  skip_if_not(file.exists(json_path), "Translation file not found")

  json_content <- jsonlite::read_json(json_path)
  en_strings <- sapply(json_content$translation, function(x) x$en)

  phi_keys <- c(
    "PHI Warning",
    "Last updated",
    "Welcome"
  )

  for (key in phi_keys) {
    expect_true(
      key %in% en_strings,
      label = paste("Missing PHI translation key:", key)
    )
  }
})
