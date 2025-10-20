# Unit tests for data_store.R

# Load the data_store functions
source("../../R/data_store.R")

# Helper to create minimal valid datasets
create_test_datasets <- function(data_dir) {
  # Visits data
  visits <- data.frame(
    id_client_id = c("P001", "P001", "P002"),
    id_visit_no = c(1, 2, 1),
    id_age = c(70, 70, 75),
    id_visit_date = as.Date(c("2025-01-01", "2025-02-01", "2025-01-05")),
    id_gender = c("Female", "Female", "Male"),
    demo_education_years = c(16, 16, 18),
    cog_dsst_score = c(85, 88, 90),
    cog_moca_score = c(28, 27, 29),
    med_hba1c = c(6.5, 6.4, 7.1),
    phys_bmi = c(24.5, 24.3, 26.2),
    ae_any = c(FALSE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )

  # Adverse events data
  ae <- data.frame(
    id_client_id = c("P001", "P002", "P002"),
    ae_date = as.Date(c("2025-01-15", "2025-01-10", "2025-02-05")),
    ae_type = c("GI", "Musculoskeletal", "GI"),
    ae_severity = c("Mild", "Moderate", "Mild"),
    stringsAsFactors = FALSE
  )

  # Data dictionary
  dict <- data.frame(
    original_name = c("Client ID", "Visit Date", "Age", "DSST Score"),
    new_name = c("id_client_id", "id_visit_date", "id_age", "cog_dsst_score"),
    domain = c("id", "id", "id", "cog"),
    type = c("character", "Date", "numeric", "numeric"),
    stringsAsFactors = FALSE
  )

  # Summary statistics
  summary <- list(
    total_patients = 2,
    total_visits = 3,
    date_range = c(as.Date("2025-01-01"), as.Date("2025-02-01")),
    domains = c("id", "demo", "cog", "med", "phys", "ae")
  )

  # Save files
  saveRDS(visits, file.path(data_dir, "visits_data.rds"))
  saveRDS(ae, file.path(data_dir, "adverse_events_data.rds"))
  readr::write_csv(dict, file.path(data_dir, "data_dictionary_cleaned.csv"))
  saveRDS(summary, file.path(data_dir, "summary_statistics.rds"))

  invisible(NULL)
}

# Test 1: Missing file errors
test_that("ds_connect fails with clear error when file missing", {
  temp_dir <- file.path(tempdir(), "missing_test")
  dir.create(temp_dir, showWarnings = FALSE)

  expect_error(
    ds_connect(temp_dir),
    regexp = "Input file not found.*visits_data.rds",
    info = "Should fail when visits file missing"
  )

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_connect fails when dictionary file missing", {
  temp_dir <- file.path(tempdir(), "partial_test")
  dir.create(temp_dir, showWarnings = FALSE)

  # Create only some files
  visits <- data.frame(id_client_id = "P001", id_visit_date = as.Date("2025-01-01"))
  saveRDS(visits, file.path(temp_dir, "visits_data.rds"))

  expect_error(
    ds_connect(temp_dir),
    regexp = "Input file not found.*adverse_events",
    info = "Should fail when AE file missing"
  )

  unlink(temp_dir, recursive = TRUE)
})

# Test 2: Type validation
test_that("ds_connect validates visits data structure", {
  temp_dir <- file.path(tempdir(), "type_test")
  dir.create(temp_dir, showWarnings = FALSE)

  # Create invalid visits data (no id columns)
  visits <- data.frame(
    some_col = c(1, 2, 3),
    another_col = c("a", "b", "c")
  )
  ae <- data.frame(id_client_id = "P001")
  dict <- data.frame(new_name = "test")
  summary <- list()

  saveRDS(visits, file.path(temp_dir, "visits_data.rds"))
  saveRDS(ae, file.path(temp_dir, "adverse_events_data.rds"))
  readr::write_csv(dict, file.path(temp_dir, "data_dictionary_cleaned.csv"))
  saveRDS(summary, file.path(temp_dir, "summary_statistics.rds"))

  expect_error(
    ds_connect(temp_dir),
    regexp = "must have at least one id_.*column",
    info = "Should validate presence of id columns"
  )

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_connect validates dictionary has required columns", {
  temp_dir <- file.path(tempdir(), "dict_test")
  dir.create(temp_dir, showWarnings = FALSE)

  visits <- data.frame(
    id_client_id = "P001",
    id_visit_date = as.Date("2025-01-01"),
    id_age = 70,
    cog_dsst = 85,
    demo_education = 16,
    med_hba1c = 6.5,
    phys_bmi = 24,
    ae_any = FALSE,
    adh_score = 80,
    other1 = 1,
    other2 = 2
  )
  ae <- data.frame(id_client_id = "P001")
  dict <- data.frame(wrong_col = "test")  # Missing new_name
  summary <- list()

  saveRDS(visits, file.path(temp_dir, "visits_data.rds"))
  saveRDS(ae, file.path(temp_dir, "adverse_events_data.rds"))
  readr::write_csv(dict, file.path(temp_dir, "data_dictionary_cleaned.csv"))
  saveRDS(summary, file.path(temp_dir, "summary_statistics.rds"))

  expect_error(
    ds_connect(temp_dir),
    regexp = "Dictionary missing required columns.*new_name",
    info = "Should validate dictionary structure"
  )

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_connect validates visits has enough columns", {
  temp_dir <- file.path(tempdir(), "cols_test")
  dir.create(temp_dir, showWarnings = FALSE)

  # Only 2 columns (too few)
  visits <- data.frame(
    id_client_id = "P001",
    id_age = 70
  )
  ae <- data.frame(id_client_id = "P001")
  dict <- data.frame(new_name = "test")
  summary <- list()

  saveRDS(visits, file.path(temp_dir, "visits_data.rds"))
  saveRDS(ae, file.path(temp_dir, "adverse_events_data.rds"))
  readr::write_csv(dict, file.path(temp_dir, "data_dictionary_cleaned.csv"))
  saveRDS(summary, file.path(temp_dir, "summary_statistics.rds"))

  expect_error(
    ds_connect(temp_dir),
    regexp = "too few columns.*expected >10",
    info = "Should validate minimum column count"
  )

  unlink(temp_dir, recursive = TRUE)
})

# Test 3: Successful loading with valid data
test_that("ds_connect successfully loads valid datasets", {
  temp_dir <- file.path(tempdir(), "valid_test")
  dir.create(temp_dir, showWarnings = FALSE)

  create_test_datasets(temp_dir)

  result <- ds_connect(temp_dir)

  expect_type(result, "list")
  expect_named(result, c("visits", "ae", "dict", "summary"))

  expect_s3_class(result$visits, "data.frame")
  expect_s3_class(result$ae, "data.frame")
  expect_s3_class(result$dict, "data.frame")
  expect_type(result$summary, "list")

  expect_equal(nrow(result$visits), 3)
  expect_equal(nrow(result$ae), 3)

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_connect enforces Date type for date columns", {
  temp_dir <- file.path(tempdir(), "date_test")
  dir.create(temp_dir, showWarnings = FALSE)

  create_test_datasets(temp_dir)
  result <- ds_connect(temp_dir)

  # Check visits date columns
  date_cols <- grep("date", names(result$visits), ignore.case = TRUE, value = TRUE)
  for (col in date_cols) {
    expect_s3_class(result$visits[[col]], "Date")
  }

  # Check AE date columns
  ae_date_cols <- grep("date", names(result$ae), ignore.case = TRUE, value = TRUE)
  for (col in ae_date_cols) {
    expect_s3_class(result$ae[[col]], "Date")
  }

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_connect validates id_age is numeric", {
  temp_dir <- file.path(tempdir(), "age_test")
  dir.create(temp_dir, showWarnings = FALSE)

  create_test_datasets(temp_dir)
  result <- ds_connect(temp_dir)

  expect_true(is.numeric(result$visits$id_age))
  expect_type(result$visits$id_age, "double")

  unlink(temp_dir, recursive = TRUE)
})

# Test 4: ds_status function
test_that("ds_status returns error for missing files", {
  temp_dir <- file.path(tempdir(), "status_missing")
  dir.create(temp_dir, showWarnings = FALSE)

  status <- ds_status(temp_dir, connect = FALSE)

  expect_equal(status$health, "error")
  expect_match(status$message, "Missing files")

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_status returns detailed metrics when connect=TRUE", {
  temp_dir <- file.path(tempdir(), "status_valid")
  dir.create(temp_dir, showWarnings = FALSE)

  create_test_datasets(temp_dir)
  status <- ds_status(temp_dir, connect = TRUE)

  expect_equal(status$health, "healthy")
  expect_equal(status$visits_rows, 3)
  expect_equal(status$ae_rows, 3)
  expect_equal(status$dict_rows, 4)
  expect_true(status$visits_cols >= 10)

  expect_true(!is.null(status$last_modified))
  expect_true(!is.null(status$files))

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_status returns file-level info when connect=FALSE", {
  temp_dir <- file.path(tempdir(), "status_noconnect")
  dir.create(temp_dir, showWarnings = FALSE)

  create_test_datasets(temp_dir)
  status <- ds_status(temp_dir, connect = FALSE)

  expect_equal(status$health, "healthy")
  expect_match(status$message, "All files present")
  expect_true(!is.null(status$last_modified))
  expect_true(!is.null(status$files))

  # Should NOT have detailed row counts
  expect_null(status$visits_rows)

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_status handles load errors gracefully", {
  temp_dir <- file.path(tempdir(), "status_error")
  dir.create(temp_dir, showWarnings = FALSE)

  # Create files but with invalid content
  visits <- data.frame(wrong = "structure")
  saveRDS(visits, file.path(temp_dir, "visits_data.rds"))
  saveRDS(data.frame(x = 1), file.path(temp_dir, "adverse_events_data.rds"))
  readr::write_csv(data.frame(y = 2), file.path(temp_dir, "data_dictionary_cleaned.csv"))
  saveRDS(list(), file.path(temp_dir, "summary_statistics.rds"))

  status <- ds_status(temp_dir, connect = TRUE)

  expect_equal(status$health, "warning")
  expect_match(status$message, "error loading")

  unlink(temp_dir, recursive = TRUE)
})

# Test 5: No console printing (all messages returned as values)
test_that("ds_connect does not print to console", {
  temp_dir <- file.path(tempdir(), "noprint_test")
  dir.create(temp_dir, showWarnings = FALSE)

  create_test_datasets(temp_dir)

  # Capture output
  output <- capture.output({
    result <- ds_connect(temp_dir)
  })

  # Should have no output (except possibly messages from readr which we suppress)
  expect_length(output, 0)

  unlink(temp_dir, recursive = TRUE)
})

test_that("ds_status does not print to console", {
  temp_dir <- file.path(tempdir(), "noprint_status")
  dir.create(temp_dir, showWarnings = FALSE)

  create_test_datasets(temp_dir)

  output <- capture.output({
    status <- ds_status(temp_dir, connect = TRUE)
  })

  expect_length(output, 0)

  unlink(temp_dir, recursive = TRUE)
})

# Test 6: Error messages are clear and actionable
test_that("Error messages are descriptive", {
  temp_dir <- file.path(tempdir(), "error_msg_test")
  dir.create(temp_dir, showWarnings = FALSE)

  expect_error(
    ds_connect(temp_dir),
    class = "error"
  )

  # Error should mention specific file
  err <- tryCatch(
    ds_connect(temp_dir),
    error = function(e) e$message
  )

  expect_match(err, "visits_data.rds")

  unlink(temp_dir, recursive = TRUE)
})

# Test 7: Zero-row data handling
test_that("ds_connect rejects zero-row datasets", {
  temp_dir <- file.path(tempdir(), "zerorow_test")
  dir.create(temp_dir, showWarnings = FALSE)

  # Create empty datasets
  visits <- data.frame(
    id_client_id = character(),
    id_visit_date = as.Date(character()),
    id_age = numeric(),
    cog_dsst = numeric(),
    demo_edu = numeric(),
    med_hba1c = numeric(),
    phys_bmi = numeric(),
    ae_any = logical(),
    adh_score = numeric(),
    other1 = numeric(),
    other2 = numeric()
  )

  ae <- data.frame(id_client_id = "P001")
  dict <- data.frame(new_name = "test")
  summary <- list()

  saveRDS(visits, file.path(temp_dir, "visits_data.rds"))
  saveRDS(ae, file.path(temp_dir, "adverse_events_data.rds"))
  readr::write_csv(dict, file.path(temp_dir, "data_dictionary_cleaned.csv"))
  saveRDS(summary, file.path(temp_dir, "summary_statistics.rds"))

  expect_error(
    ds_connect(temp_dir),
    regexp = "zero rows",
    info = "Should reject empty visits data"
  )

  unlink(temp_dir, recursive = TRUE)
})
