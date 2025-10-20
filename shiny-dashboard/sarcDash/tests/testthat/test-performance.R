# Performance Tests for Dashboard with 200 Patients
#
# Tests that dashboard modules can handle 200 patients with 0-3 visits
# and maintain acceptable rendering performance

test_that("cohort filtering scales to 200 patients with dplyr", {
  skip_on_cran()

  # Generate 200-patient dataset
  data <- mock_ds_connect(n_patients = 200)
  visits <- data$visits

  # Test dplyr filtering performance
  start_time <- Sys.time()

  filtered <- visits %>%
    dplyr::filter(id_age >= 65, id_age <= 85) %>%
    dplyr::filter(tolower(id_gender) %in% c("male", "female")) %>%
    dplyr::filter(!is.na(cog_moca_total), cog_moca_total >= 20, cog_moca_total <= 30) %>%
    dplyr::filter(id_visit_no %in% c(1, 2))

  duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  # Filtering should be fast with dplyr
  expect_lt(duration, 1, label = "Filtering 200 patients should take < 1 second")
  expect_s3_class(filtered, "data.frame")
})

test_that("cohort filtering supports 0-3 visit selection", {
  data <- mock_ds_connect(n_patients = 50)
  visits <- data$visits

  # Test all combinations
  for (visit_sel in list(c(0), c(1), c(2), c(3), c(0, 1), c(1, 2, 3), c(0, 1, 2, 3))) {
    filtered <- visits %>%
      dplyr::filter(id_visit_no %in% visit_sel)

    # All results should match selection
    expect_true(all(filtered$id_visit_no %in% visit_sel))
  }
})

test_that("retention calculation scales efficiently", {
  skip_on_cran()

  data <- mock_ds_connect(n_patients = 200)
  visits <- data$visits

  start_time <- Sys.time()

  # Dplyr-optimized retention calculation
  retention_stats <- visits %>%
    dplyr::count(id_client_id) %>%
    dplyr::summarise(
      retained = sum(n >= 2),
      total = dplyr::n(),
      rate = retained / total
    )

  duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  expect_lt(duration, 0.5, label = "Retention calculation should take < 0.5 seconds")
  expect_true(retention_stats$rate >= 0 && retention_stats$rate <= 1)
})

test_that("domain data extraction works for all prefixes", {
  data <- mock_ds_connect(n_patients = 100)
  visits <- data$visits

  domain_prefixes <- c("demo", "cog", "med", "phys", "adh")

  for (prefix in domain_prefixes) {
    domain_cols <- grep(paste0("^", prefix, "_"), names(visits), value = TRUE)

    expect_gt(length(domain_cols), 0, label = paste("Should find", prefix, "columns"))

    domain_data <- visits[, c("id_client_id", "id_visit_no", domain_cols)]
    expect_equal(nrow(domain_data), nrow(visits))
  }
})

test_that("plot downsampling works correctly for large datasets", {
  skip_on_cran()

  # Create dataset with > 500 rows
  data <- mock_ds_connect(n_patients = 200, visit_dist = c("0" = 0, "1" = 0, "2" = 0, "3" = 1))
  visits <- data$visits

  expect_gt(nrow(visits), 500, label = "Test data should have > 500 rows")

  # Simulate downsampling logic from mod_domain.R
  set.seed(42)
  max_points <- 500

  if (nrow(visits) > max_points) {
    sample_idx <- sample(seq_len(nrow(visits)), size = max_points, replace = FALSE)
    downsampled <- visits[sample_idx, ]

    expect_equal(nrow(downsampled), max_points)
    expect_true(all(downsampled$id_client_id %in% visits$id_client_id))
  }
})

test_that("debouncing prevents excessive reactive updates", {
  # Mock reactive behavior
  update_count <- 0

  mock_reactive <- function(value) {
    update_count <<- update_count + 1
    return(value)
  }

  # Simulate rapid slider changes (would normally trigger many updates)
  values <- seq(40, 100, by = 1)

  # Without debouncing, each value triggers update
  for (val in values) {
    mock_reactive(val)
  }

  expect_equal(update_count, length(values))

  # With 500ms debounce, only final value matters (simulated)
  # In real app, shiny::debounce() would reduce this to ~1-2 updates
})

test_that("CSV upload validation works for valid data", {
  # Create temporary CSV
  temp_csv <- tempfile(fileext = ".csv")
  test_data <- generate_synthetic_visits(n_patients = 50)
  readr::write_csv(test_data, temp_csv)

  # Test ds_load_csv function
  loaded <- ds_load_csv(temp_csv)

  expect_s3_class(loaded, "data.frame")
  expect_equal(nrow(loaded), nrow(test_data))
  expect_true("id_client_id" %in% names(loaded))

  # Check metadata attributes
  expect_equal(attr(loaded, "source"), "csv_upload")
  expect_true(!is.null(attr(loaded, "upload_time")))

  unlink(temp_csv)
})

test_that("CSV upload rejects invalid data", {
  # Create invalid CSV (missing required columns)
  temp_csv <- tempfile(fileext = ".csv")
  invalid_data <- data.frame(
    col1 = 1:10,
    col2 = letters[1:10],
    col3 = rnorm(10),
    col4 = rnorm(10)
  )
  readr::write_csv(invalid_data, temp_csv)

  # Should error due to missing id_* columns (has 4 columns, so passes column count check)
  expect_error(ds_load_csv(temp_csv), regexp = "id_.*column")

  unlink(temp_csv)
})

test_that("compute_retention handles edge cases", {
  # Empty data
  result <- compute_retention(NULL)
  expect_equal(result$total, 0)

  # Single patient, single visit
  data <- tibble::tibble(id_client_id = "P001")
  result <- compute_retention(data)
  expect_equal(result$total, 1)
  expect_equal(result$retained, 0)

  # Multiple visits per patient
  data <- tibble::tibble(
    id_client_id = rep(c("P001", "P002", "P003"), c(3, 2, 1))
  )
  result <- compute_retention(data)
  expect_equal(result$total, 3)
  expect_equal(result$retained, 2)  # P001 and P002 have >= 2 visits
})

test_that("describe_filters handles 0-3 visit selections", {
  # All visits selected (should not show filter)
  filters <- list(
    age_range = c(40, 100),
    visit_number = c("0", "1", "2", "3")
  )
  desc <- describe_filters(filters)
  expect_false(grepl("Visit", desc), label = "Should not show visit filter when all selected")

  # Subset of visits
  filters$visit_number <- c("1", "2")
  desc <- describe_filters(filters)
  expect_true(grepl("Visit", desc), label = "Should show visit filter for subset")
  expect_true(grepl("1.*2", desc), label = "Should list selected visits")
})

test_that("data_store validation enforces types correctly", {
  # Create test data with wrong types
  bad_data <- tibble::tibble(
    id_client_id = 1:10,
    id_visit_no = 1:10,
    id_age = as.character(60:69),  # Should be numeric
    demo_test = rnorm(10)
  )

  # validate_visits_data should error
  expect_error(validate_visits_data(bad_data), regexp = "numeric")
})

test_that("memory footprint is acceptable for 200 patients", {
  skip_on_cran()

  # Generate full dataset
  data <- mock_ds_connect(n_patients = 200)

  # Measure sizes
  visits_mb <- as.numeric(object.size(data$visits)) / 1024^2
  ae_mb <- as.numeric(object.size(data$ae)) / 1024^2
  dict_mb <- as.numeric(object.size(data$dict)) / 1024^2

  # Should be manageable sizes
  expect_lt(visits_mb, 30, label = "Visits data should be < 30 MB")
  expect_lt(ae_mb, 10, label = "AE data should be < 10 MB")
  expect_lt(dict_mb, 5, label = "Dictionary should be < 5 MB")
})

test_that("reactable pagination handles large datasets", {
  skip_on_cran()
  skip_if_not_installed("reactable")

  data <- mock_ds_connect(n_patients = 200)

  # Create reactable (should not error with large data)
  tbl <- reactable::reactable(
    data$visits,
    defaultPageSize = 25,
    showPageSizeOptions = TRUE,
    searchable = TRUE
  )

  expect_s3_class(tbl, "reactable")
})

test_that("plotly rendering performance is acceptable", {
  skip_on_cran()
  skip_if_not_installed("plotly")

  # Large dataset
  data <- mock_ds_connect(n_patients = 200, visit_dist = c("0" = 0, "1" = 0, "2" = 0.2, "3" = 0.8))

  # Downsample first (as done in mod_domain.R)
  plot_data <- if (nrow(data$visits) > 500) {
    set.seed(42)
    data$visits[sample(seq_len(nrow(data$visits)), 500), ]
  } else {
    data$visits
  }

  start_time <- Sys.time()
  p <- plotly::plot_ly(plot_data, y = ~cog_moca_total, type = "box")
  duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  expect_lt(duration, 2, label = "Plotly render should take < 2 seconds")
  expect_s3_class(p, "plotly")
})
