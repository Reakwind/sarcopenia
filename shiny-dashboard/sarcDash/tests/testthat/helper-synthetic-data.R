# Helper: Synthetic Data Generation for Dashboard Testing
#
# Generates synthetic Sarcopenia study data for testing dashboard performance
# with varying patient counts (up to 200) and visit distributions (0-3 visits)

#' Generate synthetic visits data for dashboard testing
#'
#' @param n_patients Number of patients to generate (default 200)
#' @param visit_dist Distribution of visits per patient as named vector
#' @param seed Random seed for reproducibility
#'
#' @return Tibble with synthetic visits data
#' @export
generate_synthetic_visits <- function(n_patients = 200,
                                       visit_dist = c("0" = 0.05, "1" = 0.15, "2" = 0.40, "3" = 0.40),
                                       seed = 42) {
  set.seed(seed)

  patient_ids <- sprintf("P%03d", seq_len(n_patients))
  n_visits_per_patient <- sample(
    x = as.numeric(names(visit_dist)),
    size = n_patients,
    replace = TRUE,
    prob = visit_dist
  )

  visit_records <- lapply(seq_len(n_patients), function(i) {
    n_visits <- n_visits_per_patient[i]
    if (n_visits == 0) return(NULL)

    data.frame(
      id_client_id = rep(patient_ids[i], n_visits),
      id_visit_no = seq(0, n_visits - 1),
      id_age = round(rnorm(n_visits, mean = 72, sd = 8)),
      id_gender = sample(c("Male", "Female"), n_visits, replace = TRUE),
      id_visit_date = seq(Sys.Date() - 365, by = 90, length.out = n_visits),
      demo_number_of_education_years = round(rnorm(n_visits, mean = 14, sd = 3)),
      demo_dominant_hand = sample(c("Right", "Left"), n_visits, replace = TRUE),
      demo_marital_status = sample(c("Married", "Single", "Divorced", "Widowed"), n_visits, replace = TRUE),
      cog_moca_total = round(rnorm(n_visits, mean = 24, sd = 4)),
      cog_dsst_score = round(rnorm(n_visits, mean = 50, sd = 15)),
      cog_digit_span_forward = round(rnorm(n_visits, mean = 7, sd = 2)),
      cog_digit_span_backward = round(rnorm(n_visits, mean = 5, sd = 2)),
      med_bmi = round(rnorm(n_visits, mean = 26, sd = 4), 1),
      med_systolic_bp = round(rnorm(n_visits, mean = 130, sd = 15)),
      med_diastolic_bp = round(rnorm(n_visits, mean = 80, sd = 10)),
      med_heart_rate = round(rnorm(n_visits, mean = 72, sd = 10)),
      phys_grip_strength_kg = round(rnorm(n_visits, mean = 28, sd = 8), 1),
      phys_gait_speed_ms = round(rnorm(n_visits, mean = 1.1, sd = 0.3), 2),
      phys_chair_stand_time_s = round(rnorm(n_visits, mean = 12, sd = 3), 1),
      phys_sppb_total = round(rnorm(n_visits, mean = 9, sd = 2)),
      adh_exercise_sessions_per_week = round(rnorm(n_visits, mean = 3, sd = 1)),
      adh_protein_intake_g_per_kg = round(rnorm(n_visits, mean = 1.2, sd = 0.3), 2),
      adh_attendance_pct = round(runif(n_visits, min = 70, max = 100), 1),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, Filter(function(x) !is.null(x), visit_records))
}

#' Generate synthetic adverse events data
#'
#' @param visits_data Visits data
#' @param ae_rate Average adverse events per patient
#' @param seed Random seed
#'
#' @return Tibble with synthetic adverse events
#' @export
generate_synthetic_ae <- function(visits_data, ae_rate = 0.3, seed = 43) {
  set.seed(seed)

  patients <- unique(visits_data$id_client_id)
  n_patients <- length(patients)
  n_ae_per_patient <- rpois(n_patients, lambda = ae_rate)

  ae_records <- lapply(seq_len(n_patients), function(i) {
    n_ae <- n_ae_per_patient[i]
    if (n_ae == 0) return(NULL)

    patient_visits <- visits_data[visits_data$id_client_id == patients[i], ]
    if (nrow(patient_visits) == 0) return(NULL)

    date_range <- range(patient_visits$id_visit_date)

    data.frame(
      id_client_id = rep(patients[i], n_ae),
      ae_event_id = seq_len(n_ae),
      ae_date = sample(seq(date_range[1], date_range[2], by = "day"), n_ae, replace = TRUE),
      ae_type = sample(c("Fall", "Infection", "Muscle Pain", "Fatigue", "Dizziness"), n_ae, replace = TRUE),
      ae_severity = sample(c("Mild", "Moderate", "Severe"), n_ae, replace = TRUE, prob = c(0.6, 0.3, 0.1)),
      ae_resolved = sample(c(TRUE, FALSE), n_ae, replace = TRUE, prob = c(0.85, 0.15)),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, Filter(function(x) !is.null(x), ae_records))
}

#' Create mock data store object
#'
#' @param n_patients Number of patients
#' @param visit_dist Visit distribution
#'
#' @return List mimicking ds_connect() return structure
#' @export
mock_ds_connect <- function(n_patients = 200,
                             visit_dist = c("0" = 0.05, "1" = 0.15, "2" = 0.40, "3" = 0.40)) {
  visits <- generate_synthetic_visits(n_patients, visit_dist)
  ae <- generate_synthetic_ae(visits)

  list(
    visits = visits,
    ae = ae,
    dict = data.frame(
      new_name = names(visits),
      original_name = paste0("orig_", names(visits)),
      domain = sapply(strsplit(names(visits), "_"), `[`, 1),
      description = paste("Description of", names(visits)),
      stringsAsFactors = FALSE
    ),
    summary = list(
      n_patients = length(unique(visits$id_client_id)),
      n_visits = nrow(visits),
      n_ae = nrow(ae)
    )
  )
}
