# Smoke tests - verify basic package functionality

test_that("Basic arithmetic works (sanity check)", {
  expect_equal(1 + 1, 2)
  expect_true(TRUE)
})

test_that("Required packages are available", {
  required_pkgs <- c("shiny", "golem", "config")
  for (pkg in required_pkgs) {
    expect_true(
      requireNamespace(pkg, quietly = TRUE),
      info = paste("Package", pkg, "should be available")
    )
  }
})

test_that("Testing framework is operational", {
  expect_equal(class(TRUE), "logical")
  expect_equal(2 * 3, 6)
  expect_type(list(), "list")
})
