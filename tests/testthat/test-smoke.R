# Smoke test - verify basic testing infrastructure works

library(testthat)

test_that("Basic smoke test passes", {
  expect_true(TRUE)
})

test_that("R environment is functional", {
  expect_type(1 + 1, "double")
  expect_equal(1 + 1, 2)
})

test_that("Required packages are loadable", {
  expect_true(require(tidyverse, quietly = TRUE))
  expect_true(require(here, quietly = TRUE))
  expect_true(require(readr, quietly = TRUE))
})
