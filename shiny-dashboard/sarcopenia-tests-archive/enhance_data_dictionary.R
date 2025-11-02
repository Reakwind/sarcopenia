#!/usr/bin/env Rscript
# ============================================================================
# Enhance Data Dictionary with Metadata Columns
# ============================================================================
# Adds: variable_category, data_type, instrument, description, score_range, response_options

library(dplyr)
library(readr)
library(stringr)

# Read existing data dictionary
dict <- read_csv("data_dictionary_cleaned.csv", show_col_types = FALSE)

message("Original dictionary: ", nrow(dict), " rows, ", ncol(dict), " columns")

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Determine if variable is time-invariant or time-varying
determine_variable_category <- function(new_name, prefix, section) {

  # TIME-INVARIANT patterns
  time_invariant_patterns <- c(
    # Demographics (baseline, don't change)
    "^demo_participants_study_number",
    "^demo_date_of_birth",
    "^demo_which_study",
    "^demo_study_group",
    "^demo_number_of_education",
    "^demo_educational_degree",
    "^demo_profession",
    "^demo_dominant_hand",
    # Identifiers
    "^id_gender$",
    "^id_client_id",
    "^id_client_name",
    # Units (measurement units - fill forward)
    "_unit$",
    "_unit_v[0-9]",
    # Baseline medical history
    "^med_diabetes_mellitus_type",
    "^med_year_of_diagnosis",
    "^med_medical_history_icd9"
  )

  # Check if matches time-invariant pattern
  for (pattern in time_invariant_patterns) {
    if (grepl(pattern, new_name)) {
      return("time_invariant")
    }
  }

  # ADVERSE EVENTS - special category (never missing, just leave empty)
  if (prefix == "ae" || section == "adverse_events") {
    return("adverse_event")
  }

  # Default: time-varying
  return("time_varying")
}


#' Determine data type
determine_data_type <- function(new_name, section) {

  # Date columns
  if (grepl("date|_dob", new_name, ignore.case = TRUE)) {
    return("date")
  }

  # Binary (yes/no, true/false)
  if (grepl("^demo_consent_form_signed|^demo_do_you_|^demo_did_you_|^med_hospitalization|_v[0-9]+$", new_name)) {
    return("binary")
  }

  # Numeric (scores, measurements, ages, years)
  numeric_patterns <- c(
    "score$", "total_score$", "_age$", "number_of_education",
    "bmi$", "weight_kg$", "height_m$", "systolic", "diastolic", "pulse",
    "test_[0-9]$", "average$", "percentile$", "speed$", "time_to_pass",
    "number_of_times", "distance$"
  )

  for (pattern in numeric_patterns) {
    if (grepl(pattern, new_name, ignore.case = TRUE)) {
      return("numeric")
    }
  }

  # Categorical
  categorical_patterns <- c(
    "^id_gender$", "^demo_which_study", "^demo_study_group",
    "^demo_marital_status", "^demo_dominant_hand", "^demo_educational_degree",
    "^demo_health_maintenance", "^demo_lives_with", "^demo_living_facilities",
    "^demo_location_of_visit", "^med_diabetes_mellitus_type",
    "severity$", "criteria$", "outcome"
  )

  for (pattern in categorical_patterns) {
    if (grepl(pattern, new_name)) {
      return("categorical")
    }
  }

  # Default: text
  return("text")
}


#' Determine instrument/questionnaire
determine_instrument <- function(new_name, original_name) {

  # MoCA components
  if (grepl("moca|visuospatial|cube|clock|naming|memory.*trial|digits|letters|subtraction|language|fluency|abstraction|delayed_recall|orientation", new_name, ignore.case = TRUE)) {
    return("MoCA")
  }

  # DSST
  if (grepl("dsst|dss_score", new_name, ignore.case = TRUE)) {
    return("DSST")
  }

  # PHQ-9
  if (grepl("phq", new_name, ignore.case = TRUE)) {
    return("PHQ-9")
  }

  # SPPB
  if (grepl("sppb|balance.*test|gait.*test|chair.*stand.*test", new_name, ignore.case = TRUE)) {
    return("SPPB")
  }

  # Grip strength
  if (grepl("hand|grip|dynamometer", new_name, ignore.case = TRUE)) {
    return("Grip Strength")
  }

  # Gait speed
  if (grepl("walk|gait|speed", new_name, ignore.case = TRUE) && !grepl("sppb", new_name, ignore.case = TRUE)) {
    return("Gait Speed")
  }

  # Chair stand
  if (grepl("chair.*stand|sit.*to.*stand", new_name, ignore.case = TRUE) && !grepl("sppb", new_name, ignore.case = TRUE)) {
    return("Chair Stand")
  }

  # SARC-F
  if (grepl("sarc.?f", new_name, ignore.case = TRUE)) {
    return("SARC-F")
  }

  # ADL/IADL
  if (grepl("activities.*daily|bathing|dressing|toileting|transferring|eating|shopping|finances|medication|meal.*prep|driving|stairs|walking.*difficulty", new_name, ignore.case = TRUE)) {
    return("ADL/IADL")
  }

  # Frailty scales
  if (grepl("frail|exhaustion|weight.*loss|physical.*activity", new_name, ignore.case = TRUE)) {
    return("Frailty Scale")
  }

  # Body composition
  if (grepl("bmi|weight|height", new_name, ignore.case = TRUE)) {
    return("Body Composition")
  }

  # Vital signs
  if (grepl("systolic|diastolic|pulse|blood.*pressure", new_name, ignore.case = TRUE)) {
    return("Vital Signs")
  }

  # Demographics
  if (grepl("^demo_", new_name)) {
    return("Demographics")
  }

  # Medical history
  if (grepl("medical_history|diagnosis|hospitalization", new_name, ignore.case = TRUE)) {
    return("Medical History")
  }

  return(NA_character_)
}


#' Generate description
generate_description <- function(new_name, instrument) {

  # Instrument-specific descriptions
  if (!is.na(instrument)) {
    if (instrument == "MoCA") {
      if (grepl("total_score", new_name)) {
        return("Montreal Cognitive Assessment total score (0-30; ≥26 normal)")
      }
      return("MoCA subscale component")
    }

    if (instrument == "DSST") {
      return("Digit Symbol Substitution Test score (processing speed)")
    }

    if (instrument == "PHQ-9") {
      return("Patient Health Questionnaire-9 depression score (0-27)")
    }

    if (instrument == "SPPB") {
      return("Short Physical Performance Battery score or component (0-12)")
    }

    if (instrument == "Grip Strength") {
      return("Handgrip strength measurement (kg)")
    }

    if (instrument == "Gait Speed") {
      return("Walking speed measurement (m/s or sec)")
    }

    if (instrument == "Chair Stand") {
      return("5x sit-to-stand test time (seconds)")
    }

    if (instrument == "ADL/IADL") {
      return("Activities of Daily Living assessment item")
    }
  }

  # Generic description based on variable name
  return(str_replace_all(new_name, "_", " ") %>% str_to_sentence())
}


#' Generate score range
generate_score_range <- function(instrument) {
  if (is.na(instrument)) return(NA_character_)

  ranges <- list(
    "MoCA" = "0-30",
    "DSST" = "0-133 (time dependent)",
    "PHQ-9" = "0-27",
    "SPPB" = "0-12",
    "Grip Strength" = "Variable (kg); M<27, F<16 = low",
    "Gait Speed" = "Variable (m/s); ≤0.8 = low",
    "Chair Stand" = "Time (sec); >15 = fall risk",
    "ADL/IADL" = "0-6 (ADL) or 0-8 (IADL)"
  )

  return(ranges[[instrument]])
}

# ============================================================================
# APPLY METADATA
# ============================================================================

message("Adding metadata columns...")

dict_enhanced <- dict %>%
  mutate(
    # Add new metadata columns
    variable_category = mapply(determine_variable_category, new_name, prefix, section),
    data_type = mapply(determine_data_type, new_name, section),
    instrument = mapply(determine_instrument, new_name, original_name),
    description = mapply(generate_description, new_name, instrument),
    score_range = sapply(instrument, generate_score_range),
    response_options = NA_character_  # Will be filled manually for specific items
  )

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================

message("\n=== METADATA SUMMARY ===")
message("\nVariable Category Distribution:")
print(table(dict_enhanced$variable_category))

message("\nData Type Distribution:")
print(table(dict_enhanced$data_type))

message("\nInstrument Distribution (top 10):")
print(head(sort(table(dict_enhanced$instrument, useNA = "ifany"), decreasing = TRUE), 10))

# ============================================================================
# SAVE ENHANCED DICTIONARY
# ============================================================================

output_file <- "data_dictionary_enhanced.csv"
write_csv(dict_enhanced, output_file)

message("\n=== COMPLETE ===")
message("Enhanced dictionary saved to: ", output_file)
message("Total rows: ", nrow(dict_enhanced))
message("Total columns: ", ncol(dict_enhanced))
message("New columns added: variable_category, data_type, instrument, description, score_range, response_options")
