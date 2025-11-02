# ============================================================================
# GENERATE SYNTHETIC TEST DATA
# ============================================================================
#
# Generates realistic synthetic data for 200 patients × 10 visits
# Matches RedCap export schema from actual data
#
# ============================================================================

library(readr)
library(dplyr)
library(lubridate)

set.seed(42)  # Reproducible results

cat("Generating synthetic test data...\n")

# Read actual CSV to get column structure
actual_csv <- "/Users/etaycohen/Documents/Sarcopenia/Audit report.csv"
actual_data <- read_csv(actual_csv, n_max = 1, show_col_types = FALSE)
column_names <- names(actual_data)

cat("Found", length(column_names), "columns in actual data\n")

# Parameters
n_patients <- 50
n_visits_per_patient <- 10
missing_rate <- 0.15  # 15% missing data
outlier_rate <- 0.05  # 5% outliers

# Generate patient IDs
patient_ids <- sprintf("004-%05d", 1:n_patients)

# Generate data row by row
all_rows <- list()
row_counter <- 1

cat("Generating data for", n_patients, "patients with", n_visits_per_patient, "visits each...\n")

for (patient_idx in 1:n_patients) {

  if (patient_idx %% 50 == 0) {
    cat("  Progress:", patient_idx, "/", n_patients, "patients\n")
  }

  patient_id <- patient_ids[patient_idx]
  patient_name <- paste("Patient", patient_id)

  # Patient-level (time-invariant) data
  age <- sample(65:90, 1)
  gender <- sample(c("Male", "Female"), 1)
  education_years <- sample(8:20, 1)
  dominant_hand <- sample(c("Right", "Left"), 1)
  study_group <- sample(c("780 in elderly", "BIRAX", "Regeneron"), 1)

  # Generate visits
  for (visit_idx in 1:n_visits_per_patient) {

    # Visit date (spread over 12 months)
    base_date <- as.Date("2024-01-01")
    days_offset <- (visit_idx - 1) * 30 + sample(-7:7, 1)  # ~monthly visits
    visit_date <- base_date + days(days_offset)

    # Create row
    row_data <- list()

    # Process each column
    for (col_name in column_names) {

      # Helper: Add missing data randomly
      add_missing <- function(value) {
        if (runif(1) < missing_rate) NA else value
      }

      # Helper: Add outliers randomly
      add_outlier <- function(value, range_min, range_max) {
        if (runif(1) < outlier_rate) {
          # Make it way outside range
          sample(c(range_min - 20, range_max + 20), 1)
        } else {
          value
        }
      }

      # Generate value based on column name
      value <- if (col_name == "Org ID") {
        "ORG001"
      } else if (col_name == "Client ID") {
        patient_id
      } else if (col_name == "Client Name") {
        patient_name
      } else if (col_name == "Gender") {
        gender
      } else if (col_name == "Age") {
        age
      } else if (col_name == "Visit Date") {
        format(visit_date, "%Y-%m-%d")
      } else if (col_name == "Visit Type") {
        if (visit_idx == 1) "Baseline" else "Follow-up"
      } else if (col_name == "Visit No") {
        as.character(visit_idx)
      } else if (col_name == "Visit Tag") {
        paste0("V", visit_idx)
      } else if (grepl("MoCA|moca", col_name, ignore.case = TRUE)) {
        if (grepl("Total Score", col_name)) {
          add_missing(add_outlier(sample(15:30, 1), 0, 30))
        } else {
          add_missing(sample(0:5, 1))
        }
      } else if (grepl("DSST|DSS", col_name, ignore.case = TRUE)) {
        if (grepl("Total Score", col_name)) {
          add_missing(add_outlier(sample(20:100, 1), 0, 135))
        } else if (grepl("Standardized Score", col_name)) {
          add_missing(sample(c("Yes", "No", "Uncertain"), 1))
        } else {
          add_missing(sample(20:100, 1))
        }
      } else if (grepl("PHQ", col_name, ignore.case = TRUE)) {
        if (grepl("Total Score", col_name)) {
          add_missing(add_outlier(sample(0:20, 1), 0, 27))
        } else {
          add_missing(sample(0:3, 1))
        }
      } else if (grepl("WHO.*5|WHO-5", col_name, ignore.case = TRUE)) {
        if (grepl("Total Score", col_name)) {
          add_missing(add_outlier(sample(10:25, 1), 0, 25))
        } else {
          add_missing(sample(0:5, 1))
        }
      } else if (grepl("VF phonemic|VF semantic", col_name, ignore.case = TRUE)) {
        if (grepl("Total Score", col_name)) {
          add_missing(sample(10:30, 1))
        } else if (grepl("Standardized Score", col_name)) {
          add_missing(sample(c("Above Average", "Average", "Below Average"), 1))
        } else {
          add_missing(sample(5:15, 1))
        }
      } else if (grepl("SPPB", col_name, ignore.case = TRUE)) {
        if (grepl("Total|score", col_name, ignore.case = TRUE)) {
          add_missing(add_outlier(sample(4:12, 1), 0, 12))
        } else {
          add_missing(sample(0:4, 1))
        }
      } else if (grepl("Grip|grip", col_name, ignore.case = TRUE)) {
        if (grepl("Test|Average", col_name)) {
          add_missing(add_outlier(sample(15:45, 1), 0, 80))
        } else if (grepl("Percentile", col_name)) {
          add_missing(sample(10:90, 1))
        } else if (grepl("Unit", col_name)) {
          "kg"
        } else {
          add_missing(sample(15:45, 1))
        }
      } else if (grepl("Gait|gait|Walking|walking", col_name, ignore.case = TRUE)) {
        if (grepl("Speed|speed", col_name)) {
          add_missing(round(runif(1, 0.5, 1.5), 2))
        } else {
          add_missing(sample(c("No difficulty", "Some difficulty", "Much difficulty"), 1))
        }
      } else if (grepl("BMI|bmi", col_name, ignore.case = TRUE)) {
        if (grepl("Height", col_name)) {
          add_missing(round(runif(1, 1.5, 1.9), 2))
        } else if (grepl("Weight", col_name)) {
          add_missing(round(runif(1, 55, 95), 1))
        } else if (grepl("BMI", col_name) && !grepl("Unit", col_name)) {
          add_missing(add_outlier(round(runif(1, 18, 35), 1), 10, 60))
        } else if (grepl("Unit", col_name)) {
          if (grepl("Height", col_name)) "m" else "kg"
        } else {
          add_missing(round(runif(1, 18, 35), 1))
        }
      } else if (grepl("SARC", col_name, ignore.case = TRUE)) {
        add_missing(sample(0:10, 1))
      } else if (grepl("Frailty", col_name, ignore.case = TRUE)) {
        if (grepl("criteria", col_name, ignore.case = TRUE)) {
          add_missing(sample(c("Not Frail", "Pre-frail", "Frail"), 1))
        } else {
          add_missing(sample(0:5, 1))
        }
      } else if (grepl("education|Education", col_name)) {
        if (grepl("years", col_name, ignore.case = TRUE)) {
          education_years
        } else if (grepl("degree", col_name, ignore.case = TRUE)) {
          sample(c("High School", "Bachelor", "Master", "PhD"), 1)
        } else {
          add_missing(sample(c("High School", "College", "Graduate"), 1))
        }
      } else if (grepl("Date|date", col_name) && !grepl("birth", col_name, ignore.case = TRUE)) {
        if (runif(1) < missing_rate) {
          NA
        } else {
          format(visit_date + sample(-30:30, 1), "%Y-%m-%d")
        }
      } else if (grepl("birth", col_name, ignore.case = TRUE)) {
        format(Sys.Date() - years(age) - sample(1:365, 1), "%Y-%m-%d")
      } else if (grepl("study number|Participants study", col_name)) {
        patient_id
      } else if (grepl("study.*part|Which study", col_name)) {
        if (grepl(study_group, col_name)) "Yes" else NA
      } else if (grepl("dominant.*hand", col_name, ignore.case = TRUE)) {
        dominant_hand
      } else if (grepl("Visit number", col_name)) {
        as.character(visit_idx)
      } else if (grepl("Unit", col_name)) {
        # Most units
        if (grepl("pressure|Pressure", col_name)) {
          "mmHg"
        } else if (grepl("glucose|Glucose", col_name)) {
          "mg/dL"
        } else {
          ""
        }
      } else if (grepl("Yes|No", col_name) || grepl("checkbox", col_name, ignore.case = TRUE)) {
        add_missing(sample(c("Yes", "No"), 1))
      } else {
        # Default: random text or number
        if (runif(1) < 0.3) {
          NA
        } else if (runif(1) < 0.5) {
          as.character(sample(1:100, 1))
        } else {
          ""
        }
      }

      row_data[[col_name]] <- value
    }

    all_rows[[row_counter]] <- as.data.frame(row_data, stringsAsFactors = FALSE)
    row_counter <- row_counter + 1
  }
}

cat("Combining all rows...\n")

# Combine all rows
synthetic_data <- bind_rows(all_rows)

cat("Generated", nrow(synthetic_data), "rows\n")
cat("Columns:", ncol(synthetic_data), "\n")

# Save
output_file <- "tests/synthetic_50patients_10visits.csv"
dir.create("tests", showWarnings = FALSE)

cat("Writing to", output_file, "...\n")
write_csv(synthetic_data, output_file)

cat("✓ Synthetic data generation complete!\n")
cat("  File:", output_file, "\n")
cat("  Size:", file.size(output_file) / 1024 / 1024, "MB\n")
cat("  Rows:", nrow(synthetic_data), "\n")
cat("  Columns:", ncol(synthetic_data), "\n")
