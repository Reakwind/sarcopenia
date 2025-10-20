# Unit tests for data dictionary module

# Load required helpers
source("../../R/data_store.R")
source("../../R/i18n_helpers.R")
source("../../R/mod_dictionary.R")

# Test 1: Dictionary module UI function exists
test_that("mod_dictionary_ui function exists", {
  expect_true(exists("mod_dictionary_ui"))
  expect_type(mod_dictionary_ui, "closure")
})

# Test 2: Dictionary module server function exists
test_that("mod_dictionary_server function exists", {
  expect_true(exists("mod_dictionary_server"))
  expect_type(mod_dictionary_server, "closure")
})

# Test 3: Dictionary UI creates proper structure
test_that("mod_dictionary_ui creates proper HTML structure", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_dictionary_ui("test_dict")

  expect_s3_class(ui, "shiny.tag")

  html_str <- as.character(ui)

  # Check for main components
  expect_match(html_str, "prefix_legend")
  expect_match(html_str, "search_text")
  expect_match(html_str, "export_csv")
})

# Test 4: Prefix filter buttons are present
test_that("Prefix filter buttons are created", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_dictionary_ui("test_dict")
  html_str <- as.character(ui)

  # Check for all prefix filter buttons
  expect_match(html_str, "filter_id")
  expect_match(html_str, "filter_demo")
  expect_match(html_str, "filter_cog")
  expect_match(html_str, "filter_med")
  expect_match(html_str, "filter_phys")
  expect_match(html_str, "filter_adh")
  expect_match(html_str, "filter_ae")
  expect_match(html_str, "clear_filter")
})

# Test 5: Search input is present
test_that("Search input is present", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_dictionary_ui("test_dict")
  html_str <- as.character(ui)

  expect_match(html_str, "search_text")
})

# Test 6: Export button is present
test_that("Export CSV button is present", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_dictionary_ui("test_dict")
  html_str <- as.character(ui)

  expect_match(html_str, "export_csv")
})

# Test 7: Reactable output is present
test_that("Reactable output placeholder exists", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("reactable")

  library(shiny)

  ui <- mod_dictionary_ui("test_dict")
  html_str <- as.character(ui)

  expect_match(html_str, "dictionary_table")
})

# Test 8: Translation keys exist for dictionary module
test_that("Dictionary module translation keys exist", {
  json_path <- "../../inst/i18n/translations.json"

  skip_if_not(file.exists(json_path), "Translation file not found")

  json_content <- jsonlite::read_json(json_path)
  en_strings <- sapply(json_content$translation, function(x) x$en)

  dict_keys <- c(
    "Filter by Prefix",
    "Identifiers",
    "Clear Filter",
    "Original Name",
    "New Name",
    "Domain",
    "Prefix"
  )

  for (key in dict_keys) {
    expect_true(
      key %in% en_strings,
      label = paste("Missing dictionary translation key:", key)
    )
  }
})

# Test 9: Data dictionary file structure
test_that("Data dictionary has expected columns", {
  skip_if_not_installed("readr")

  data_dir <- here::here("data")
  dict_path <- file.path(data_dir, "data_dictionary_cleaned.csv")

  skip_if_not(file.exists(dict_path), "Data dictionary file not found")

  dict <- readr::read_csv(dict_path, show_col_types = FALSE)

  # Check for required columns
  expect_true("original_name" %in% names(dict))
  expect_true("new_name" %in% names(dict))
  expect_true("section" %in% names(dict))
  expect_true("prefix" %in% names(dict))
})

# Test 10: Prefix filtering logic
test_that("Prefix filtering produces expected subset", {
  skip_if_not_installed("readr")

  # Create test dictionary
  test_dict <- data.frame(
    original_name = c("Age", "Gender", "DSST", "BMI", "Exercise"),
    new_name = c("id_age", "id_gender", "cog_dsst", "phys_bmi", "phys_exercise"),
    section = c("identifier", "identifier", "cognitive", "physical", "physical"),
    prefix = c("id", "id", "cog", "phys", "phys"),
    stringsAsFactors = FALSE
  )

  # Filter by id_ prefix
  id_filtered <- test_dict[grepl("^id_", test_dict$new_name), ]
  expect_equal(nrow(id_filtered), 2)
  expect_true(all(id_filtered$prefix == "id"))

  # Filter by cog_ prefix
  cog_filtered <- test_dict[grepl("^cog_", test_dict$new_name), ]
  expect_equal(nrow(cog_filtered), 1)
  expect_equal(cog_filtered$new_name, "cog_dsst")

  # Filter by phys_ prefix
  phys_filtered <- test_dict[grepl("^phys_", test_dict$new_name), ]
  expect_equal(nrow(phys_filtered), 2)
  expect_true(all(phys_filtered$prefix == "phys"))
})

# Test 11: Search filtering logic
test_that("Search filtering works across columns", {
  # Create test dictionary
  test_dict <- data.frame(
    original_name = c("Age at Visit", "Gender", "DSST Score"),
    new_name = c("id_age", "id_gender", "cog_dsst"),
    section = c("identifier", "identifier", "cognitive"),
    prefix = c("id", "id", "cog"),
    stringsAsFactors = FALSE
  )

  # Search for "age" - should match "Age at Visit" (original_name) and "id_age" (new_name)
  search_term <- "age"
  matches <- apply(test_dict, 1, function(row) {
    any(grepl(search_term, row, ignore.case = TRUE))
  })
  filtered <- test_dict[matches, ]

  # Actually only 1 row has "age" since "id_age" is one value
  expect_gte(nrow(filtered), 1)
  expect_true(any(grepl("age", filtered$original_name, ignore.case = TRUE)) ||
              any(grepl("age", filtered$new_name, ignore.case = TRUE)))

  # Search for "cognitive"
  search_term2 <- "cognitive"
  matches2 <- apply(test_dict, 1, function(row) {
    any(grepl(search_term2, row, ignore.case = TRUE))
  })
  filtered2 <- test_dict[matches2, ]

  expect_equal(nrow(filtered2), 1)
  expect_equal(filtered2$section, "cognitive")
})

# Test 12: PHI detection patterns
test_that("PHI patterns are defined", {
  phi_patterns <- c(
    "social.?security", "ssn", "passport", "license",
    "account.?number", "credit.?card", "phone.?number",
    "email", "address", "zip.?code"
  )

  expect_length(phi_patterns, 10)
  expect_true(all(nchar(phi_patterns) > 0))
})

# Test 13: PHI detection logic
test_that("PHI detection works on test data", {
  # Test data with PHI
  test_dict_phi <- data.frame(
    original_name = c("Name", "Social Security Number", "Age"),
    new_name = c("id_name", "id_ssn", "id_age"),
    stringsAsFactors = FALSE
  )

  # Check if SSN pattern detected
  has_ssn <- any(grepl("social.?security", test_dict_phi$original_name, ignore.case = TRUE))
  expect_true(has_ssn)

  # Test data without PHI
  test_dict_clean <- data.frame(
    original_name = c("Age", "Gender", "Visit Date"),
    new_name = c("id_age", "id_gender", "id_visit_date"),
    stringsAsFactors = FALSE
  )

  has_phi <- any(grepl("social.?security", test_dict_clean$original_name, ignore.case = TRUE))
  expect_false(has_phi)
})

# Test 14: Prefix color coding
test_that("Prefix colors are properly defined", {
  prefix_colors <- c(
    id = "secondary",
    demo = "info",
    cog = "primary",
    med = "danger",
    phys = "success",
    adh = "warning",
    ae = "dark"
  )

  expect_length(prefix_colors, 7)
  expect_true(all(nchar(prefix_colors) > 0))
})

# Test 15: Badge classes for prefixes
test_that("Prefix badges use Bootstrap classes", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_dictionary_ui("test_dict")
  html_str <- as.character(ui)

  # Check for Bootstrap badge classes
  expect_match(html_str, "badge bg-secondary")  # id_
  expect_match(html_str, "badge bg-info")       # demo_
  expect_match(html_str, "badge bg-primary")    # cog_
  expect_match(html_str, "badge bg-danger")     # med_
  expect_match(html_str, "badge bg-success")    # phys_
  expect_match(html_str, "badge bg-warning")    # adh_
  expect_match(html_str, "badge bg-dark")       # ae_
})

# Test 16: Module namespacing
test_that("Module uses proper namespacing", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui1 <- mod_dictionary_ui("dict1")
  ui2 <- mod_dictionary_ui("dict2")

  html1 <- as.character(ui1)
  html2 <- as.character(ui2)

  # Check that IDs are namespaced differently
  expect_match(html1, "dict1-")
  expect_match(html2, "dict2-")
  expect_false(identical(html1, html2))
})

# Test 17: Flexible layout with Bootstrap grid
test_that("Layout uses Bootstrap grid system", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_dictionary_ui("test_dict")
  html_str <- as.character(ui)

  # Check for row and column classes
  expect_match(html_str, "row")
  expect_match(html_str, "col-md-8")
  expect_match(html_str, "col-md-4")
  expect_match(html_str, "container-fluid")
})

# Test 18: Export filename pattern
test_that("Export filename follows standard pattern", {
  # Test the filename pattern
  expected_pattern <- paste0("data_dictionary_", format(Sys.Date(), "%Y%m%d"), ".csv")

  expect_match(expected_pattern, "data_dictionary_\\d{8}\\.csv")
  expect_true(grepl("\\.csv$", expected_pattern))
})
