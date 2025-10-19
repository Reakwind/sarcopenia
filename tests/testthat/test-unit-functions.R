# ==============================================================================
# Unit Tests for Helper Functions
# ==============================================================================
# Tests for clean_var_name(), safe_numeric(), and safe_date()

library(testthat)
library(tidyverse)

# Source the functions from the cleaning script
# (In production, these should be in separate R files)
source("scripts/01_data_cleaning.R", local = TRUE)

# ==============================================================================
# Tests for clean_var_name()
# ==============================================================================

test_that("clean_var_name removes trailing reference numbers", {
  expect_equal(
    clean_var_name("15. Number of education years - 230"),
    "number_of_education_years"
  )
  expect_equal(
    clean_var_name("Medical history - 251"),
    "medical_history"
  )
})

test_that("clean_var_name removes leading question numbers", {
  expect_equal(
    clean_var_name("1. Patient name"),
    "patient_name"
  )
  expect_equal(
    clean_var_name("123. Some variable"),
    "some_variable"
  )
})

test_that("clean_var_name handles newlines", {
  expect_equal(
    clean_var_name("Variable\nwith\nnewlines"),
    "variable_with_newlines"
  )
})

test_that("clean_var_name removes sub-field numbers", {
  expect_equal(
    clean_var_name("BMI - 0. Height"),
    "bmi_height"
  )
  expect_equal(
    clean_var_name("Test - 1. Value - 100"),
    "test_value"
  )
})

test_that("clean_var_name converts to lowercase and snake_case", {
  expect_equal(
    clean_var_name("PatientName"),
    "patientname"
  )
  expect_equal(
    clean_var_name("Patient Name"),
    "patient_name"
  )
  expect_equal(
    clean_var_name("PATIENT-NAME"),
    "patient_name"
  )
})

test_that("clean_var_name removes leading/trailing underscores", {
  expect_equal(
    clean_var_name("_variable_"),
    "variable"
  )
  expect_equal(
    clean_var_name("___test___"),
    "test"
  )
})

test_that("clean_var_name collapses multiple underscores", {
  expect_equal(
    clean_var_name("test___multiple___underscores"),
    "test_multiple_underscores"
  )
})

test_that("clean_var_name handles special characters", {
  expect_equal(
    clean_var_name("Variable (with) [brackets] & symbols!"),
    "variable_with_brackets_symbols"
  )
})

test_that("clean_var_name handles empty or whitespace-only strings", {
  expect_equal(
    clean_var_name("   "),
    ""
  )
})

test_that("clean_var_name is idempotent for already clean names", {
  clean_name <- "already_clean_variable_name"
  expect_equal(
    clean_var_name(clean_name),
    clean_name
  )
})

# ==============================================================================
# Tests for safe_numeric()
# ==============================================================================

test_that("safe_numeric converts simple numeric strings", {
  expect_equal(safe_numeric("123"), 123)
  expect_equal(safe_numeric("45.67"), 45.67)
  expect_equal(safe_numeric("0"), 0)
})

test_that("safe_numeric extracts first number from complex strings", {
  # Important for DSST raw scores like "36/41"
  expect_equal(safe_numeric("36/41"), 36)
  expect_equal(safe_numeric("100 units"), 100)
  expect_equal(safe_numeric("Score: 75"), NA_real_)  # Doesn't start with number
})

test_that("safe_numeric handles negative numbers", {
  expect_equal(safe_numeric("-123"), NA_real_)  # Regex doesn't capture negative
})

test_that("safe_numeric returns NA for non-numeric strings", {
  expect_true(is.na(safe_numeric("abc")))
  expect_true(is.na(safe_numeric("N/A")))
  expect_true(is.na(safe_numeric("")))
})

test_that("safe_numeric returns NA for NA input", {
  expect_true(is.na(safe_numeric(NA_character_)))
})

test_that("safe_numeric handles decimal numbers", {
  expect_equal(safe_numeric("3.14159"), 3.14159)
  expect_equal(safe_numeric("0.5"), 0.5)
})

test_that("safe_numeric handles leading zeros", {
  expect_equal(safe_numeric("007"), 7)
  expect_equal(safe_numeric("0.5"), 0.5)
})

test_that("safe_numeric is vectorized", {
  input <- c("10", "20", "30/40", "NA", "50")
  expected <- c(10, 20, 30, NA_real_, 50)
  expect_equal(safe_numeric(input), expected)
})

# ==============================================================================
# Tests for safe_date()
# ==============================================================================

test_that("safe_date converts YYYY-MM-DD format", {
  expect_equal(
    safe_date("2025-04-20"),
    as.Date("2025-04-20")
  )
})

test_that("safe_date converts DD/MM/YYYY format", {
  expect_equal(
    safe_date("20/04/2025"),
    as.Date("2025-04-20")
  )
})

test_that("safe_date converts MM/DD/YYYY format", {
  expect_equal(
    safe_date("04/20/2025"),
    as.Date("2025-04-20")
  )
})

test_that("safe_date returns NA for invalid dates", {
  expect_true(is.na(safe_date("not a date")))
  expect_true(is.na(safe_date("99/99/9999")))
  expect_true(is.na(safe_date("")))
})

test_that("safe_date returns NA for NA input", {
  expect_true(is.na(safe_date(NA_character_)))
})

test_that("safe_date handles edge case dates", {
  expect_equal(
    safe_date("2000-01-01"),
    as.Date("2000-01-01")
  )
  expect_equal(
    safe_date("2025-12-31"),
    as.Date("2025-12-31")
  )
})

test_that("safe_date is vectorized", {
  input <- c("2025-04-20", "20/04/2025", "invalid", NA_character_)
  result <- safe_date(input)

  expect_equal(result[1], as.Date("2025-04-20"))
  expect_equal(result[2], as.Date("2025-04-20"))
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
})

# ==============================================================================
# Integration Tests for Function Combinations
# ==============================================================================

test_that("Functions handle NULL input gracefully", {
  expect_error(clean_var_name(NULL))
  expect_error(safe_numeric(NULL))
  expect_error(safe_date(NULL))
})

test_that("Functions handle empty vectors", {
  expect_equal(clean_var_name(character(0)), character(0))
  expect_equal(safe_numeric(character(0)), numeric(0))
  expect_equal(safe_date(character(0)), as.Date(character(0)))
})

test_that("Functions preserve vector length", {
  input_names <- c("Var1", "Var2", "Var3")
  expect_length(clean_var_name(input_names), 3)

  input_nums <- c("1", "2", "3")
  expect_length(safe_numeric(input_nums), 3)

  input_dates <- c("2025-01-01", "2025-01-02", "2025-01-03")
  expect_length(safe_date(input_dates), 3)
})
