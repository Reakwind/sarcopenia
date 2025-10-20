# Helper: Synthetic Data Generation for Scalability Testing
#
# Generates synthetic Sarcopenia study data for testing pipeline performance
# with varying patient counts (up to 200) and visit distributions (0-3 visits)

#' Generate synthetic visits data
#'
#' @param n_patients Number of patients to generate (default 200)
#' @param visit_dist Distribution of visits per patient as named vector
#'   e.g., c("0" = 0.05, "1" = 0.15, "2" = 0.40, "3" = 0.40)
#' @param seed Random seed for reproducibility
#'
#' @return Tibble with synthetic visits data matching real data structure
#' @export
generate_synthetic_visits <- function(n_patients = 200,
                                       visit_dist = c("0" = 0.05, "1" = 0.15, "2" = 0.40, "3" = 0.40),
                                       seed = 42) {
  set.seed(seed)

  # Generate patient IDs
  patient_ids <- sprintf("P%03d", seq_len(n_patients))

  # Assign number of visits per patient based on distribution
  n_visits_per_patient <- sample(
    x = as.numeric(names(visit_dist)),
    size = n_patients,
    replace = TRUE,
    prob = visit_dist
  )

  # Create visit records
  visit_records <- lapply(seq_len(n_patients), function(i) {
    n_visits <- n_visits_per_patient[i]
    if (n_visits == 0) return(NULL)

    tibble::tibble(
      id_client_id = rep(patient_ids[i], n_visits),
      id_visit_no = seq(0, n_visits - 1),
      id_age = round(rnorm(n_visits, mean = 72, sd = 8)),
      id_gender = sample(c("Male", "Female"), n_visits, replace = TRUE),
      id_visit_date = seq(Sys.Date() - 365, by = 90, length.out = n_visits),

      # Demographics
      demo_number_of_education_years = round(rnorm(n_visits, mean = 14, sd = 3)),
      demo_dominant_hand = sample(c("Right", "Left"), n_visits, replace = TRUE),
      demo_marital_status = sample(c("Married", "Single", "Divorced", "Widowed"), n_visits, replace = TRUE),

      # Cognitive
      cog_moca_total = round(rnorm(n_visits, mean = 24, sd = 4)),
      cog_dsst_score = round(rnorm(n_visits, mean = 50, sd = 15)),
      cog_digit_span_forward = round(rnorm(n_visits, mean = 7, sd = 2)),
      cog_digit_span_backward = round(rnorm(n_visits, mean = 5, sd = 2)),

      # Medical
      med_bmi = round(rnorm(n_visits, mean = 26, sd = 4), 1),
      med_systolic_bp = round(rnorm(n_visits, mean = 130, sd = 15)),
      med_diastolic_bp = round(rnorm(n_visits, mean = 80, sd = 10)),
      med_heart_rate = round(rnorm(n_visits, mean = 72, sd = 10)),

      # Physical
      phys_grip_strength_kg = round(rnorm(n_visits, mean = 28, sd = 8), 1),
      phys_gait_speed_ms = round(rnorm(n_visits, mean = 1.1, sd = 0.3), 2),
      phys_chair_stand_time_s = round(rnorm(n_visits, mean = 12, sd = 3), 1),
      phys_sppb_total = round(rnorm(n_visits, mean = 9, sd = 2)),

      # Adherence
      adh_exercise_sessions_per_week = round(rnorm(n_visits, mean = 3, sd = 1)),
      adh_protein_intake_g_per_kg = round(rnorm(n_visits, mean = 1.2, sd = 0.3), 2),
      adh_attendance_pct = round(runif(n_visits, min = 70, max = 100), 1)
    )
  })

  # Combine all visit records
  do.call(rbind, Filter(function(x) !is.null(x), visit_records))
}

#' Generate synthetic adverse events data
#'
#' @param visits_data Visits data (to extract patient IDs and dates)
#' @param ae_rate Average adverse events per patient (default 0.3)
#' @param seed Random seed for reproducibility
#'
#' @return Tibble with synthetic adverse events data
#' @export
generate_synthetic_ae <- function(visits_data, ae_rate = 0.3, seed = 43) {
  set.seed(seed)

  # Get unique patients
  patients <- unique(visits_data$id_client_id)
  n_patients <- length(patients)

  # Determine number of AEs per patient (Poisson distributed)
  n_ae_per_patient <- rpois(n_patients, lambda = ae_rate)

  # Generate AE records
  ae_records <- lapply(seq_len(n_patients), function(i) {
    n_ae <- n_ae_per_patient[i]
    if (n_ae == 0) return(NULL)

    # Get patient visit dates for reference
    patient_visits <- visits_data[visits_data$id_client_id == patients[i], ]
    if (nrow(patient_visits) == 0) return(NULL)

    date_range <- range(patient_visits$id_visit_date)

    tibble::tibble(
      id_client_id = rep(patients[i], n_ae),
      ae_event_id = seq_len(n_ae),
      ae_date = sample(seq(date_range[1], date_range[2], by = "day"), n_ae, replace = TRUE),
      ae_type = sample(c("Fall", "Infection", "Muscle Pain", "Fatigue", "Dizziness"), n_ae, replace = TRUE),
      ae_severity = sample(c("Mild", "Moderate", "Severe"), n_ae, replace = TRUE, prob = c(0.6, 0.3, 0.1)),
      ae_resolved = sample(c(TRUE, FALSE), n_ae, replace = TRUE, prob = c(0.85, 0.15))
    )
  })

  do.call(rbind, Filter(function(x) !is.null(x), ae_records))
}

#' Generate synthetic data dictionary
#'
#' @param visits_data Visits data (to extract column names)
#'
#' @return Tibble with synthetic data dictionary
#' @export
generate_synthetic_dict <- function(visits_data) {
  col_names <- names(visits_data)

  tibble::tibble(
    new_name = col_names,
    original_name = paste0("orig_", col_names),
    domain = sapply(strsplit(col_names, "_"), `[`, 1),
    description = paste("Description of", col_names),
    type = sapply(visits_data, function(x) class(x)[1]),
    valid_range = ifelse(
      sapply(visits_data, is.numeric),
      paste(round(min(visits_data[[1]], na.rm = TRUE), 1), "-", round(max(visits_data[[1]], na.rm = TRUE), 1)),
      NA_character_
    )
  )
}

#' Generate complete synthetic dataset
#'
#' @param n_patients Number of patients (default 200)
#' @param visit_dist Visit distribution (default: 5% 0-visit, 15% 1-visit, 40% 2-visit, 40% 3-visit)
#' @param ae_rate Adverse events per patient (default 0.3)
#' @param seed Random seed (default 42)
#'
#' @return List with visits, ae, and dict tibbles
#' @export
generate_synthetic_dataset <- function(n_patients = 200,
                                        visit_dist = c("0" = 0.05, "1" = 0.15, "2" = 0.40, "3" = 0.40),
                                        ae_rate = 0.3,
                                        seed = 42) {
  visits <- generate_synthetic_visits(n_patients, visit_dist, seed)
  ae <- generate_synthetic_ae(visits, ae_rate, seed + 1)
  dict <- generate_synthetic_dict(visits)

  list(
    visits = visits,
    ae = ae,
    dict = dict
  )
}
