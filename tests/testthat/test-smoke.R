# Smoke test - verify basic testing infrastructure works

library(testthat)

test_that("Basic smoke test passes", {
  expect_true(TRUE)
})

test_that("R environment is functional", {
  expect_type(1 + 1, "double")
  expect_equal(1 + 1, 2)
})

test_that("Core required packages are loadable", {
  # Core packages used in app.R
  expect_true(require(shiny, quietly = TRUE))
  expect_true(require(bslib, quietly = TRUE))
  expect_true(require(reactable, quietly = TRUE))
  expect_true(require(plotly, quietly = TRUE))
  expect_true(require(dplyr, quietly = TRUE))
  expect_true(require(tidyr, quietly = TRUE))
  expect_true(require(readr, quietly = TRUE))
  expect_true(require(lubridate, quietly = TRUE))
  expect_true(require(stringr, quietly = TRUE))
  expect_true(require(forcats, quietly = TRUE))
  expect_true(require(purrr, quietly = TRUE))
  expect_true(require(rlang, quietly = TRUE))
  expect_true(require(tibble, quietly = TRUE))
  expect_true(require(tidyselect, quietly = TRUE))
  expect_true(require(shinyjs, quietly = TRUE))
})

test_that("Testing infrastructure packages are loadable", {
  # Testing packages
  expect_true(require(testthat, quietly = TRUE))
  expect_true(require(here, quietly = TRUE))
})

test_that("Optional feature packages availability check", {
  # These packages are used in optional features and should be available
  # but we won't fail tests if they're not installed

  # For Excel export (fct_reports.R)
  writexl_available <- requireNamespace("writexl", quietly = TRUE)
  if (!writexl_available) {
    message("Note: writexl package not available - Excel export will not work")
  }

  # For R Markdown reports (fct_reports.R)
  rmarkdown_available <- requireNamespace("rmarkdown", quietly = TRUE)
  if (!rmarkdown_available) {
    message("Note: rmarkdown package not available - report generation will not work")
  }

  knitr_available <- requireNamespace("knitr", quietly = TRUE)
  if (!knitr_available) {
    message("Note: knitr package not available - report generation may not work")
  }

  # Always pass this test - just informational
  expect_true(TRUE)
})
