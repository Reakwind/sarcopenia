# ==============================================================================
# Test Runner for Sarcopenia Data Cleaning Tests
# ==============================================================================
# This file runs all tests in the testthat/ directory

library(testthat)
library(tidyverse)

# Set working directory to project root
setwd(here::here())

# Run all tests
test_check("sarcopenia")
