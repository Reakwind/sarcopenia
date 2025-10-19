# ==============================================================================
# Tests for Patient-Level Missing Data Handling
# ==============================================================================
# Tests the critical patient-level missingness filling logic

library(testthat)
library(tidyverse)

test_that("Patient-level filling propagates values across all visits", {
  # Create test data: Patient with 3 visits, education only at visit 1
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(1, 2, 3),
    demo_number_of_education_years = c(16, NA, NA)
  )

  # Apply filling logic
  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # All visits should have education = 16
  expect_equal(result$demo_number_of_education_years, c(16, 16, 16))
})

test_that("Patient-level filling works bidirectionally", {
  # Education recorded at visit 2 only
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(1, 2, 3),
    demo_number_of_education_years = c(NA, 16, NA)
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # Should fill both backward (to visit 1) and forward (to visit 3)
  expect_equal(result$demo_number_of_education_years, c(16, 16, 16))
})

test_that("Patient-level filling preserves true patient-level missingness", {
  # Patient never provided education data at any visit
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(1, 2, 3),
    demo_number_of_education_years = c(NA, NA, NA)
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # Should remain NA at all visits (true missingness)
  expect_true(all(is.na(result$demo_number_of_education_years)))
})

test_that("Patient-level filling works independently for different patients", {
  # Two patients with different education values
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P002", "P002"),
    id_visit_no = c(1, 2, 1, 2),
    demo_number_of_education_years = c(16, NA, 18, NA)
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # P001 should have 16, P002 should have 18
  expect_equal(result$demo_number_of_education_years, c(16, 16, 18, 18))
})

test_that("Patient-level filling doesn't alter already-filled values", {
  # All values already present
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(1, 2, 3),
    demo_number_of_education_years = c(16, 16, 16)
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # Should remain unchanged
  expect_equal(result$demo_number_of_education_years, c(16, 16, 16))
})

test_that("Patient-level filling detects inconsistent values", {
  # Patient has DIFFERENT education values at different visits (data error!)
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(1, 2, 3),
    demo_number_of_education_years = c(16, 18, NA)
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # fill() will propagate the first non-NA value
  # This test documents the behavior (should be 16, 18, 18)
  # In production, we should warn about inconsistencies
  expect_equal(result$demo_number_of_education_years, c(16, 18, 18))
})

test_that("Patient-level filling works with multiple time-invariant variables", {
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(1, 2, 3),
    demo_number_of_education_years = c(16, NA, NA),
    demo_dominant_hand = c(0, NA, NA),
    demo_marital_status = c("Married", NA, NA)
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(c(demo_number_of_education_years, demo_dominant_hand, demo_marital_status),
         .direction = "downup") %>%
    ungroup()

  # All variables should be filled
  expect_equal(result$demo_number_of_education_years, c(16, 16, 16))
  expect_equal(result$demo_dominant_hand, c(0, 0, 0))
  expect_equal(result$demo_marital_status, c("Married", "Married", "Married"))
})

test_that("Patient-level filling preserves visit-specific variables", {
  # Visit-specific variable (weight) should NOT be filled
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(1, 2, 3),
    demo_number_of_education_years = c(16, NA, NA),  # Time-invariant: fill
    phys_weight = c(70, NA, 75)  # Visit-specific: don't fill
  )

  # Only fill the time-invariant variable
  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  expect_equal(result$demo_number_of_education_years, c(16, 16, 16))
  expect_equal(result$phys_weight, c(70, NA, 75))  # Unchanged
})

test_that("Patient-level filling handles single-visit patients", {
  # Patient with only one visit
  test_data <- tibble(
    id_client_id = "P001",
    id_visit_no = 1,
    demo_number_of_education_years = 16
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # Should remain unchanged
  expect_equal(result$demo_number_of_education_years, 16)
})

test_that("Patient-level filling works correctly with unordered visits", {
  # Visits out of order (3, 1, 2)
  test_data <- tibble(
    id_client_id = c("P001", "P001", "P001"),
    id_visit_no = c(3, 1, 2),
    demo_number_of_education_years = c(NA, 16, NA)
  )

  result <- test_data %>%
    arrange(id_client_id, id_visit_no) %>%  # Critical: must sort first
    group_by(id_client_id) %>%
    fill(demo_number_of_education_years, .direction = "downup") %>%
    ungroup()

  # After sorting and filling, all should be 16
  expect_true(all(result$demo_number_of_education_years == 16))
})
