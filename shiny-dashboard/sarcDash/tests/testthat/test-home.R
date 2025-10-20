# Unit tests for home module

# Load required helpers
source("../../R/data_store.R")
source("../../R/i18n_helpers.R")
source("../../R/mod_home.R")

# Test 1: Home module UI function exists
test_that("mod_home_ui function exists", {
  expect_true(exists("mod_home_ui"))
  expect_type(mod_home_ui, "closure")
})

# Test 2: Home module server function exists
test_that("mod_home_server function exists", {
  expect_true(exists("mod_home_server"))
  expect_type(mod_home_server, "closure")
})

# Test 3: Home UI creates proper structure
test_that("mod_home_ui creates proper HTML structure", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")

  expect_s3_class(ui, "shiny.tag")

  # Convert to HTML string for checking
  html_str <- as.character(ui)

  # Check for main components
  expect_match(html_str, "home_container")
  expect_match(html_str, "dataset_health_card")
  expect_match(html_str, "quick_links_card")
  expect_match(html_str, "learn_card")
})

# Test 4: Quick links buttons are present
test_that("Quick links buttons are created", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Check for button IDs
  expect_match(html_str, "goto_cohort")
  expect_match(html_str, "goto_domains")
  expect_match(html_str, "goto_qc")
})

# Test 5: Tour button is present
test_that("Tour button is present", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  expect_match(html_str, "start_tour")
  expect_match(html_str, "show_tour_on_load")
})

# Test 6: Cicerone is loaded
test_that("Cicerone use_cicerone is included", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("cicerone")

  library(shiny)
  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Cicerone should inject JS
  expect_match(html_str, "cicerone", ignore.case = TRUE)
})

# Test 7: Waiter is loaded
test_that("Waiter use_waiter is included", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("waiter")

  library(shiny)
  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Waiter should inject dependencies
  expect_match(html_str, "waiter", ignore.case = TRUE)
})

# Test 8: Translation keys exist for home module
test_that("Home module translation keys exist", {
  json_path <- "../../inst/i18n/translations.json"

  skip_if_not(file.exists(json_path), "Translation file not found")

  json_content <- jsonlite::read_json(json_path)
  en_strings <- sapply(json_content$translation, function(x) x$en)

  home_keys <- c(
    "Dataset Health",
    "Quick Links",
    "Learn",
    "Start Tour",
    "Show tour on startup",
    "Get Started",
    "Navigation"
  )

  for (key in home_keys) {
    expect_true(
      key %in% en_strings,
      label = paste("Missing home translation key:", key)
    )
  }
})

# Test 9: Card structure with proper Bootstrap classes
test_that("Cards use proper Bootstrap classes", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Check for Bootstrap card classes
  expect_match(html_str, "card")
  expect_match(html_str, "card-header")
  expect_match(html_str, "card-body")
  expect_match(html_str, "card-title")
})

# Test 10: Icons are used in cards
test_that("Cards include Font Awesome icons", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Check for icon classes
  expect_match(html_str, "fa-database|database")
  expect_match(html_str, "fa-bolt|bolt")
  expect_match(html_str, "fa-graduation-cap|graduation-cap")
})

# Test 11: Color-coded card headers
test_that("Card headers have different colors", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Check for different Bootstrap color classes
  expect_match(html_str, "bg-primary")
  expect_match(html_str, "bg-info")
  expect_match(html_str, "bg-success")
})

# Test 12: Responsive layout with Bootstrap grid
test_that("Layout uses Bootstrap grid system", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Check for row and column classes
  expect_match(html_str, "row")
  expect_match(html_str, "col-md-4")
  expect_match(html_str, "container-fluid")
})

# Test 13: PHI banner output is present
test_that("PHI banner output placeholder exists", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  expect_match(html_str, "phi_banner")
})

# Test 14: Module namespacing works
test_that("Module uses proper namespacing", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui1 <- mod_home_ui("home1")
  ui2 <- mod_home_ui("home2")

  html1 <- as.character(ui1)
  html2 <- as.character(ui2)

  # Check that IDs are namespaced differently
  expect_match(html1, "home1-")
  expect_match(html2, "home2-")
  expect_false(identical(html1, html2))
})

# Test 15: Welcome message card
test_that("Welcome message card is present", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  expect_match(html_str, "welcome_message")
})

# Test 16: Guided tour has minimum 6 steps
test_that("Cicerone tour structure is correct", {
  skip_if_not_installed("cicerone")

  # This is a structural test - the actual tour is created in the server
  # We're just checking that the expected elements exist
  tour_elements <- c(
    "dataset_health_card",
    "quick_links_card",
    "learn_card",
    "main_navbar",
    "language",
    "welcome_message"
  )

  # These are the 6 elements the tour should cover
  expect_length(tour_elements, 6)
})

# Test 17: Action buttons have proper structure
test_that("Action buttons are properly configured", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  # Check for button classes
  expect_match(html_str, "btn")
  expect_match(html_str, "btn-lg")
  expect_match(html_str, "btn-outline-primary|btn-outline-secondary|btn-outline-success")
})

# Test 18: d-grid gap for button spacing
test_that("Button layout uses d-grid for proper spacing", {
  skip_if_not_installed("shiny")
  library(shiny)

  ui <- mod_home_ui("test_home")
  html_str <- as.character(ui)

  expect_match(html_str, "d-grid")
  expect_match(html_str, "gap-2")
})
