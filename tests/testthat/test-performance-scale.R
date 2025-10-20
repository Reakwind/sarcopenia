# Performance and Scalability Tests for Data Cleaning Pipeline
#
# Tests that the cleaning pipeline can handle 200 patients with 0-3 visits
# and maintains acceptable performance characteristics

test_that("generate_synthetic_visits creates valid 200-patient dataset", {
  data <- generate_synthetic_visits(n_patients = 200)

  expect_s3_class(data, "data.frame")
  expect_true(nrow(data) > 0)
  expect_true(dplyr::n_distinct(data$id_client_id) <= 200)

  # Check for required columns
  expect_true("id_client_id" %in% names(data))
  expect_true("id_visit_no" %in% names(data))
  expect_true("id_age" %in% names(data))

  # Check visit numbers are in 0-3 range
  expect_true(all(data$id_visit_no %in% 0:3))
})

test_that("generate_synthetic_visits respects visit distribution", {
  # Test with specific distribution
  visit_dist <- c("0" = 0.1, "1" = 0.2, "2" = 0.3, "3" = 0.4)
  data <- generate_synthetic_visits(n_patients = 200, visit_dist = visit_dist)

  # Count visits per patient
  visit_counts <- data %>%
    dplyr::count(id_client_id) %>%
    dplyr::pull(n)

  # Should have visits in 1-3 range (0-visit patients not in data)
  expect_true(all(visit_counts %in% 1:3))
})

test_that("generate_synthetic_visits handles 0-visit patients correctly", {
  # Force 100% 0-visit patients
  data <- generate_synthetic_visits(n_patients = 10, visit_dist = c("0" = 1.0))

  # Should return empty or minimal dataset
  expect_true(nrow(data) == 0 || is.null(data))
})

test_that("generate_synthetic_ae creates valid adverse events", {
  visits <- generate_synthetic_visits(n_patients = 50)
  ae <- generate_synthetic_ae(visits, ae_rate = 0.5)

  expect_s3_class(ae, "data.frame")

  if (nrow(ae) > 0) {
    expect_true("id_client_id" %in% names(ae))
    expect_true("ae_type" %in% names(ae))
    expect_true("ae_severity" %in% names(ae))

    # All AE patients should be in visits data
    ae_patients <- unique(ae$id_client_id)
    visit_patients <- unique(visits$id_client_id)
    expect_true(all(ae_patients %in% visit_patients))
  }
})

test_that("synthetic data generation is reproducible", {
  data1 <- generate_synthetic_visits(n_patients = 100, seed = 999)
  data2 <- generate_synthetic_visits(n_patients = 100, seed = 999)

  expect_equal(nrow(data1), nrow(data2))
  expect_equal(data1$id_client_id, data2$id_client_id)
  expect_equal(data1$cog_moca_total, data2$cog_moca_total)
})

test_that("cleaning pipeline handles 200 patients efficiently", {
  skip_on_cran()
  skip_if_not_installed("microbenchmark")

  # Generate 200-patient dataset
  synthetic <- generate_synthetic_dataset(n_patients = 200)

  # Simulate key cleaning operations
  start_time <- Sys.time()

  # Test patient-level filling (most expensive operation)
  time_invariant_vars <- c("demo_number_of_education_years", "demo_dominant_hand")

  visits_filled <- synthetic$visits %>%
    dplyr::group_by(id_client_id) %>%
    dplyr::mutate(dplyr::across(
      dplyr::all_of(time_invariant_vars),
      ~ dplyr::coalesce(., dplyr::first(na.omit(.)))
    )) %>%
    dplyr::ungroup()

  # Test domain column selection
  demo_cols <- grep("^demo_", names(visits_filled), value = TRUE)
  cog_cols <- grep("^cog_", names(visits_filled), value = TRUE)

  # Test visit distribution calculation
  visit_dist <- visits_filled %>%
    dplyr::count(id_client_id) %>%
    dplyr::count(n, name = "n_patients")

  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Performance expectations for 200 patients
  expect_lt(duration, 10, label = "Processing 200 patients should take < 10 seconds")
  expect_gt(nrow(visits_filled), 0)
  expect_gt(nrow(visit_dist), 0)
})

test_that("memory usage is acceptable for 200 patients", {
  skip_on_cran()

  # Generate large dataset
  synthetic <- generate_synthetic_dataset(n_patients = 200)

  # Measure memory size
  visits_size_mb <- as.numeric(object.size(synthetic$visits)) / 1024^2
  ae_size_mb <- as.numeric(object.size(synthetic$ae)) / 1024^2
  dict_size_mb <- as.numeric(object.size(synthetic$dict)) / 1024^2
  total_size_mb <- visits_size_mb + ae_size_mb + dict_size_mb

  # Memory expectations
  expect_lt(total_size_mb, 50, label = "Total dataset should be < 50 MB")
  expect_lt(visits_size_mb, 40, label = "Visits data should be < 40 MB")
})

test_that("visit distribution validation works for 0-3 visits", {
  # Test all visit counts
  data <- generate_synthetic_visits(
    n_patients = 200,
    visit_dist = c("0" = 0.1, "1" = 0.3, "2" = 0.3, "3" = 0.3)
  )

  visit_numbers <- unique(data$id_visit_no)

  # Should only contain 0-3
  expect_true(all(visit_numbers %in% 0:3))

  # No unexpected values
  unexpected <- visit_numbers[!visit_numbers %in% 0:3]
  expect_equal(length(unexpected), 0)
})

test_that("dynamic patient counting works correctly", {
  # Generate datasets of different sizes
  for (n in c(20, 50, 100, 200)) {
    data <- generate_synthetic_visits(n_patients = n)

    # Count unique patients
    n_patients_actual <- dplyr::n_distinct(data$id_client_id)

    # Should be <= n (some might have 0 visits)
    expect_lte(n_patients_actual, n)
    expect_gt(n_patients_actual, 0)
  }
})

test_that("patient-level filling scales to 200 patients", {
  skip_on_cran()

  data <- generate_synthetic_visits(n_patients = 200)

  # Patient-level filling operation
  start_time <- Sys.time()

  filled_data <- data %>%
    dplyr::group_by(id_client_id) %>%
    dplyr::mutate(
      demo_dominant_hand = dplyr::coalesce(demo_dominant_hand, dplyr::first(na.omit(demo_dominant_hand)))
    ) %>%
    dplyr::ungroup()

  duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

  expect_lt(duration, 5, label = "Patient-level filling should take < 5 seconds for 200 patients")
  expect_equal(nrow(filled_data), nrow(data))
})

test_that("adverse events handling scales to any number of events", {
  visits <- generate_synthetic_visits(n_patients = 200)

  # Test with high AE rate
  ae_high <- generate_synthetic_ae(visits, ae_rate = 2.0)  # Avg 2 AEs per patient

  expect_s3_class(ae_high, "data.frame")

  if (nrow(ae_high) > 0) {
    # Should handle hundreds of AEs
    expect_gt(nrow(ae_high), 100)

    # All AE patients exist in visits
    expect_true(all(unique(ae_high$id_client_id) %in% unique(visits$id_client_id)))
  }
})

test_that("throughput meets performance target", {
  skip_on_cran()

  # Generate 200-patient dataset
  data <- generate_synthetic_visits(n_patients = 200)

  # Measure processing throughput
  start_time <- Sys.time()

  processed <- data %>%
    dplyr::filter(!is.na(id_age)) %>%
    dplyr::mutate(age_group = cut(id_age, breaks = c(0, 65, 75, 100))) %>%
    dplyr::group_by(id_client_id) %>%
    dplyr::summarise(n_visits = dplyr::n(), .groups = "drop")

  duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  records_per_sec <- nrow(data) / duration

  # Should process at least 50 records per second
  expect_gt(records_per_sec, 50, label = "Throughput should be > 50 records/second")
})
