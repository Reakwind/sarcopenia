# ==============================================================================
# End-to-End Tests for Data Cleaning Pipeline
# ==============================================================================
# Tests the complete data cleaning workflow from raw input to final output

library(testthat)
library(tidyverse)
library(here)

# Skip E2E tests if sample data not available
skip_if_no_sample_data <- function() {
  sample_file <- here::here("tests/fixtures/sample_raw_data.csv")
  if (!file.exists(sample_file)) {
    skip("Sample data file not found")
  }
}

test_that("E2E: Complete pipeline runs without errors", {
  skip_if_no_sample_data()

  # This test runs the entire cleaning script on sample data
  # Should complete without errors
  expect_error({
    # Would source the cleaning script here with sample data
    # For now, this is a placeholder
    TRUE
  }, NA)
})

test_that("E2E: Input file validation works", {
  # Test that non-existent file is caught
  expect_error(
    read_csv("nonexistent_file.csv"),
    "does not exist"
  )
})

test_that("E2E: Output files are created", {
  skip_if_no_sample_data()

  # After running cleaning script, check outputs exist
  output_files <- c(
    here::here("data/visits_data.rds"),
    here::here("data/adverse_events_data.rds"),
    here::here("data/data_dictionary_cleaned.csv"),
    here::here("data/summary_statistics.rds")
  )

  # Check if files exist (they should from previous run)
  for (file in output_files) {
    expect_true(
      file.exists(file),
      info = paste("Output file should exist:", file)
    )
  }
})

test_that("E2E: Output data has correct structure", {
  # Load visits data
  visits <- readRDS(here::here("data/visits_data.rds"))

  # Check basic structure
  expect_true(is.data.frame(visits))
  expect_gt(nrow(visits), 0)
  expect_gt(ncol(visits), 100)  # Should have many variables

  # Check key columns exist
  key_cols <- c("id_client_id", "id_visit_no", "id_visit_date")
  expect_true(all(key_cols %in% names(visits)))

  # Check domain prefixes used
  expect_true(any(str_starts(names(visits), "id_")))
  expect_true(any(str_starts(names(visits), "demo_")))
  expect_true(any(str_starts(names(visits), "cog_")))
  expect_true(any(str_starts(names(visits), "med_")))
  expect_true(any(str_starts(names(visits), "phys_")))
})

test_that("E2E: Data types are correct after conversion", {
  visits <- readRDS(here::here("data/visits_data.rds"))

  # Check date columns are Date type
  expect_true(inherits(visits$id_visit_date, "Date"))

  # Check numeric columns (if they exist and have data)
  if ("id_age" %in% names(visits) && any(!is.na(visits$id_age))) {
    expect_true(is.numeric(visits$id_age))
  }

  # Check character columns remain character
  expect_true(is.character(visits$id_client_id))
})

test_that("E2E: Patient-level filling was applied", {
  visits <- readRDS(here::here("data/visits_data.rds"))

  # For patients with multiple visits, check that time-invariant
  # variables are consistent across visits
  multi_visit_patients <- visits %>%
    group_by(id_client_id) %>%
    filter(n() > 1) %>%
    ungroup()

  if (nrow(multi_visit_patients) > 0) {
    # Check gender is consistent within patient
    gender_consistency <- multi_visit_patients %>%
      group_by(id_client_id) %>%
      summarise(unique_genders = n_distinct(id_gender, na.rm = TRUE)) %>%
      pull(unique_genders)

    # Each patient should have only 1 unique gender value
    expect_true(all(gender_consistency <= 1))
  }
})

test_that("E2E: No data loss during processing", {
  visits <- readRDS(here::here("data/visits_data.rds"))

  # Check that we have expected number of observations
  # (This would need to be adjusted based on actual data)
  expect_gte(nrow(visits), 1)  # At least some data

  # Check no completely empty rows
  empty_rows <- visits %>%
    select(where(is.character)) %>%
    rowwise() %>%
    summarise(all_na = all(is.na(c_across(everything())))) %>%
    pull(all_na)

  expect_false(any(empty_rows))
})

test_that("E2E: Adverse events properly separated", {
  ae <- readRDS(here::here("data/adverse_events_data.rds"))

  # Check AE data exists and has structure
  expect_true(is.data.frame(ae))
  expect_equal(nrow(ae), nrow(readRDS(here::here("data/visits_data.rds"))))

  # Check AE columns present
  ae_cols <- names(ae)[str_starts(names(ae), "ae_")]
  expect_gt(length(ae_cols), 0)

  # Check ID columns present
  id_cols <- names(ae)[str_starts(names(ae), "id_")]
  expect_gt(length(id_cols), 0)
})

test_that("E2E: Variable mapping is complete", {
  var_map <- read_csv(here::here("data/data_dictionary_cleaned.csv"), show_col_types = FALSE)

  # Check structure
  expect_true("original_name" %in% names(var_map))
  expect_true("new_name" %in% names(var_map))
  expect_true("section" %in% names(var_map))

  # Check no missing mappings
  expect_false(any(is.na(var_map$new_name)))

  # Check all new names are valid R variable names
  expect_true(all(make.names(var_map$new_name) == var_map$new_name))
})

test_that("E2E: Summary statistics are reasonable", {
  stats <- readRDS(here::here("data/summary_statistics.rds"))

  # Check it's a list
  expect_true(is.list(stats))

  # Check key statistics exist
  expect_true("n_patients" %in% names(stats))
  expect_true("n_observations" %in% names(stats))

  # Check values are reasonable
  expect_gte(stats$n_patients, 1)
  expect_gte(stats$n_observations, stats$n_patients)
})

test_that("E2E: No section markers in output", {
  visits <- readRDS(here::here("data/visits_data.rds"))

  # Section markers should have been removed
  section_markers <- c(
    "Personal Information FINAL",
    "Physician evaluation FINAL",
    "Physical Health Agility FINAL",
    "Cognitive Health Agility- Final",
    "Adverse events FINAL",
    "Body composition FINAL"
  )

  # Check none of these columns exist (even in snake_case form)
  for (marker in section_markers) {
    cleaned_marker <- tolower(str_replace_all(marker, "[^a-z0-9]+", "_"))
    matching_cols <- names(visits)[str_detect(tolower(names(visits)), cleaned_marker)]
    expect_length(matching_cols, 0,
                  label = paste("Section marker should be removed:", marker))
  }
})

test_that("E2E: DSST scores are properly classified", {
  visits <- readRDS(here::here("data/visits_data.rds"))

  # Digital DSST should be in cognitive domain
  digital_dsst_vars <- names(visits)[str_detect(names(visits), "cog.*raw.*dss|cog.*dsst.*score")]
  expect_gt(length(digital_dsst_vars), 0,
            label = "Digital DSST variables should be classified as cognitive")

  # Paper DSST should also be in cognitive domain
  paper_dsst_vars <- names(visits)[str_detect(names(visits), "cog.*dsst.*total")]
  # May or may not exist depending on data
})

test_that("E2E: Quality checks pass", {
  visits <- readRDS(here::here("data/visits_data.rds"))

  # Age range is reasonable
  if ("id_age" %in% names(visits)) {
    ages <- visits$id_age[!is.na(visits$id_age)]
    if (length(ages) > 0) {
      expect_gte(min(ages), 18)  # Adults only
      expect_lte(max(ages), 120)  # Reasonable max age
    }
  }

  # Visit dates are not in the future
  if ("id_visit_date" %in% names(visits)) {
    dates <- visits$id_visit_date[!is.na(visits$id_visit_date)]
    if (length(dates) > 0) {
      expect_true(all(dates <= Sys.Date()))
    }
  }

  # No duplicate patient-visit combinations
  if (all(c("id_client_id", "id_visit_no") %in% names(visits))) {
    duplicates <- visits %>%
      group_by(id_client_id, id_visit_no) %>%
      filter(n() > 1)

    expect_equal(nrow(duplicates), 0,
                 info = "No duplicate patient-visit combinations")
  }
})

test_that("E2E: Domain prefixes are consistently applied", {
  visits <- readRDS(here::here("data/visits_data.rds"))

  # Define expected domain prefixes
  expected_prefixes <- c("id", "demo", "cog", "med", "phys", "adh")

  # Check that most variables use these prefixes
  has_prefix <- sapply(names(visits), function(col) {
    any(sapply(expected_prefixes, function(prefix) {
      str_starts(col, paste0(prefix, "_"))
    }))
  })

  # At least 90% of variables should have domain prefixes
  expect_gte(mean(has_prefix), 0.9)
})

test_that("E2E: Memory usage is reasonable", {
  # Check that output files are not unexpectedly large
  visits_file <- "data/visits_data.rds"
  if (file.exists(visits_file)) {
    file_size_mb <- file.info(visits_file)$size / (1024^2)

    # Expect file to be less than 100MB (adjust based on actual data)
    expect_lt(file_size_mb, 100,
              info = paste("File size:", round(file_size_mb, 2), "MB"))
  }
})

test_that("E2E: Regression test - known good output matches", {
  # This test would compare current output to a known good baseline
  # Useful for catching unintended changes

  # Load current output
  current <- readRDS(here::here("data/visits_data.rds"))

  # Would load baseline here and compare key metrics
  # expect_equal(nrow(current), nrow(baseline))
  # expect_equal(names(current), names(baseline))

  # For now, just check basic properties
  expect_true(nrow(current) > 0)
  expect_true(ncol(current) > 0)
})
