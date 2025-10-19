# Testing Guide
## Sarcopenia Study - Data Cleaning Pipeline

**Version:** 1.0
**Last Updated:** October 19, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Running Tests](#running-tests)
4. [Test Categories](#test-categories)
5. [Writing New Tests](#writing-new-tests)
6. [Continuous Integration](#continuous-integration)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Overview

This project uses the `testthat` framework for testing R code. Our testing strategy includes:

- **Unit Tests:** Test individual functions in isolation
- **Integration Tests:** Test multiple components working together
- **End-to-End Tests:** Test the complete data cleaning pipeline
- **Security Tests:** Validate security measures
- **Regression Tests:** Ensure bugs don't reappear

### Testing Philosophy

✅ **Test early, test often**
✅ **Test behavior, not implementation**
✅ **Keep tests simple and focused**
✅ **Make tests independent and repeatable**
✅ **Aim for 80%+ code coverage**

---

## Quick Start

### Installation

```r
# Install required testing packages
install.packages(c("testthat", "covr", "here"))
```

### Run All Tests

```r
# From R console in project root
library(testthat)
test_dir("tests/testthat")
```

Or from terminal:

```bash
cd /path/to/sarcopenia
Rscript -e "testthat::test_dir('tests/testthat')"
```

### Expected Output

```
✔ | F W S  OK | Context
✔ |        42 | unit-functions
✔ |        12 | patient-filling
✔ |        18 | e2e

══ Results ═════════════════════════════════════
Duration: 2.3 s

✔ 72 tests: all passed
```

---

## Running Tests

### Run All Tests

```r
# Method 1: Using testthat
library(testthat)
test_dir("tests/testthat")

# Method 2: Using devtools
devtools::test()

# Method 3: Run specific test file
test_file("tests/testthat/test-unit-functions.R")
```

### Run Tests with Coverage

```r
library(covr)

# Generate coverage report
cov <- package_coverage()

# View in browser
report(cov)

# Print summary
cov
```

### Run Specific Tests

```r
# Run only tests matching a pattern
test_dir("tests/testthat", filter = "patient")

# Run a single test
test_file("tests/testthat/test-unit-functions.R")
```

### Run Tests in Parallel

```r
# For faster execution
library(furrr)
plan(multisession)

# Run tests in parallel (if supported)
test_dir("tests/testthat", parallel = TRUE)
```

---

## Test Categories

### 1. Unit Tests (`test-unit-functions.R`)

**Purpose:** Test individual helper functions

**Functions Tested:**
- `clean_var_name()` - Variable name cleaning
- `safe_numeric()` - Safe numeric conversion
- `safe_date()` - Safe date conversion

**Run:**
```r
test_file("tests/testthat/test-unit-functions.R")
```

**Coverage:** 42 tests covering:
- Normal cases
- Edge cases (NULL, NA, empty strings)
- Invalid inputs
- Vector operations
- Idempotency

---

### 2. Patient-Level Filling Tests (`test-patient-filling.R`)

**Purpose:** Test the critical patient-level missingness handling

**Scenarios Tested:**
- Forward filling (visit 1 → visits 2,3)
- Backward filling (visit 2 → visit 1)
- Bidirectional filling
- True patient-level missingness preserved
- Multiple patients independently filled
- Inconsistent data detection

**Run:**
```r
test_file("tests/testthat/test-patient-filling.R")
```

**Why Critical:** Patient-level filling is a key feature that ensures time-invariant variables are consistent across visits. These tests verify this works correctly.

---

### 3. End-to-End Tests (`test-e2e.R`)

**Purpose:** Test the complete data cleaning pipeline

**What's Tested:**
- ✅ Pipeline runs without errors
- ✅ Output files are created
- ✅ Data structure is correct
- ✅ Data types are converted properly
- ✅ Patient-level filling was applied
- ✅ No data loss
- ✅ Adverse events separated correctly
- ✅ Variable mapping is complete
- ✅ Quality checks pass

**Run:**
```r
test_file("tests/testthat/test-e2e.R")
```

**Note:** E2E tests may take longer to run as they process actual data.

---

## Writing New Tests

### Test File Structure

```r
# ==============================================================================
# Tests for [Feature Name]
# ==============================================================================
# Brief description of what this file tests

library(testthat)
library(tidyverse)

# Source dependencies if needed
source("scripts/01_data_cleaning.R", local = TRUE)

test_that("[Feature] does [expected behavior]", {
  # Arrange: Set up test data
  input <- "test data"

  # Act: Execute the function
  result <- my_function(input)

  # Assert: Verify the outcome
  expect_equal(result, expected_output)
})
```

### Test Naming Conventions

**Good Names:**
- ✅ `test_that("clean_var_name removes trailing reference numbers", {...})`
- ✅ `test_that("safe_numeric converts simple numeric strings", {...})`
- ✅ `test_that("Patient-level filling works bidirectionally", {...})`

**Bad Names:**
- ❌ `test_that("test 1", {...})`
- ❌ `test_that("it works", {...})`
- ❌ `test_that("function test", {...})`

### Common Expectations

```r
# Equality
expect_equal(result, expected)
expect_identical(result, expected)  # Stricter

# Type checks
expect_true(is.numeric(x))
expect_false(is.na(x))
expect_type(x, "character")

# Length/dimension
expect_length(vec, 10)
expect_equal(nrow(df), 100)

# Errors and warnings
expect_error(bad_function(), "error message")
expect_warning(risky_function())
expect_message(verbose_function())

# No error
expect_error(good_function(), NA)

# Logical
expect_true(condition)
expect_false(condition)

# Pattern matching
expect_match(string, "regex pattern")

# Greater/less than
expect_gt(x, 0)
expect_gte(x, 0)
expect_lt(x, 100)
expect_lte(x, 100)
```

### Testing Best Practices

1. **Arrange-Act-Assert Pattern:**
   ```r
   test_that("function does something", {
     # Arrange
     input_data <- setup_test_data()

     # Act
     result <- function_to_test(input_data)

     # Assert
     expect_equal(result, expected_output)
   })
   ```

2. **One Assertion Per Test (Usually):**
   ```r
   # Good - focused
   test_that("returns numeric", {
     result <- my_function("123")
     expect_true(is.numeric(result))
   })

   test_that("converts correctly", {
     result <- my_function("123")
     expect_equal(result, 123)
   })

   # Acceptable - related assertions
   test_that("handles vector input", {
     result <- my_function(c("1", "2", "3"))
     expect_length(result, 3)
     expect_equal(result, c(1, 2, 3))
   })
   ```

3. **Test Independence:**
   ```r
   # Bad - tests depend on each other
   test_that("setup", {
     global_var <<- setup()
   })
   test_that("uses global", {
     expect_true(is_valid(global_var))  # Depends on previous test
   })

   # Good - each test is independent
   test_that("test 1", {
     data <- setup()
     expect_true(is_valid(data))
   })
   test_that("test 2", {
     data <- setup()  # Set up again
     expect_equal(process(data), expected)
   })
   ```

4. **Use Fixtures for Complex Data:**
   ```r
   # Create test data file
   # tests/fixtures/sample_data.csv

   # Load in tests
   test_that("processes sample data", {
     data <- read_csv("tests/fixtures/sample_data.csv")
     result <- process(data)
     expect_equal(nrow(result), 5)
   })
   ```

---

## Continuous Integration

### Pre-Commit Hook

Tests run automatically before each commit:

```bash
# Install pre-commit hook
./scripts/install_hooks.sh
```

The hook will:
1. Run all tests
2. Check code style with lintr
3. Prevent commit if tests fail

### GitHub Actions

Tests run automatically on:
- Every push to main
- Every pull request
- Nightly (for longer tests)

See `.github/workflows/test.yml` for configuration.

---

## Troubleshooting

### Tests Fail Locally

**Problem:** Tests pass in CI but fail locally

**Solutions:**
1. Ensure you're in project root directory
2. Clear R session: `rm(list = ls())`
3. Restart R: `.rs.restartR()` (RStudio)
4. Check R version matches CI
5. Update packages: `update.packages()`

### Tests Are Slow

**Problem:** Tests take too long to run

**Solutions:**
1. Skip E2E tests during development:
   ```r
   test_dir("tests/testthat", filter = "unit|patient")
   ```
2. Use `skip()` for slow tests:
   ```r
   test_that("slow test", {
     skip_on_cran()
     skip_if(Sys.getenv("QUICK_TESTS") == "true")
     # ... slow test code
   })
   ```
3. Run tests in parallel (if available)

### Coverage Is Low

**Problem:** Code coverage < 80%

**Solutions:**
1. Identify untested code:
   ```r
   cov <- package_coverage()
   report(cov)  # Opens browser with coverage report
   ```
2. Add tests for uncovered lines
3. Focus on critical paths first
4. It's okay to skip trivial getters/setters

### Test Data Issues

**Problem:** Tests fail because fixture data is wrong

**Solutions:**
1. Regenerate fixtures:
   ```r
   source("tests/fixtures/generate_fixtures.R")
   ```
2. Validate fixture structure
3. Keep fixtures small and focused

---

## Best Practices

### DO ✅

- **Write tests before fixing bugs** (regression tests)
- **Test edge cases:** NULL, NA, empty, negative, zero
- **Use descriptive test names**
- **Keep tests fast** (< 0.1s per test ideally)
- **Test one thing per test**
- **Use fixtures for complex data**
- **Document why tests exist** (not just what they do)
- **Run tests before committing**

### DON'T ❌

- **Don't test library code** (testthat, dplyr, etc.)
- **Don't test trivial code** (simple getters)
- **Don't make tests depend on each other**
- **Don't use real patient data** in tests
- **Don't skip tests without reason**
- **Don't test implementation details** (test behavior)
- **Don't write tests that sometimes fail**

---

## Test Coverage Goals

| Component | Target Coverage | Current |
|-----------|----------------|---------|
| Helper Functions | 100% | TBD |
| Data Transformations | 90% | TBD |
| Patient-Level Filling | 100% | TBD |
| Type Conversion | 85% | TBD |
| Overall | 80% | TBD |

Run `covr::package_coverage()` to check current coverage.

---

## Command Reference

```r
# Run all tests
testthat::test_dir("tests/testthat")

# Run specific file
testthat::test_file("tests/testthat/test-unit-functions.R")

# Run with filter
testthat::test_dir("tests/testthat", filter = "patient")

# Generate coverage
covr::package_coverage()

# Coverage report
covr::report(covr::package_coverage())

# Check code style
lintr::lint("scripts/01_data_cleaning.R")

# Run security audit
oysteR::audit_installed_r_pkgs()
```

---

## Getting Help

- **testthat Documentation:** https://testthat.r-lib.org/
- **Coverage Documentation:** https://covr.r-lib.org/
- **R Testing Best Practices:** https://r-pkgs.org/testing-basics.html

---

## Contributing

When adding new features:

1. ✅ Write tests first (TDD)
2. ✅ Ensure all existing tests pass
3. ✅ Add tests for new functionality
4. ✅ Maintain 80%+ coverage
5. ✅ Update this guide if needed

---

**Document Version:** 1.0
**Maintainer:** [To be filled]
**Last Updated:** October 19, 2025
