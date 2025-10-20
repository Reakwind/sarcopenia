# ==============================================================================
# Sarcopenia Study - Data Cleaning Script
# ==============================================================================
# Purpose: Clean and tidy the raw audit report data for exploratory analysis
# Input:   Audit report.csv (575 variables, 38 observations)
# Output:  - visits_data.rds (one row per patient-visit, wide format)
#          - adverse_events_data.rds (one row per adverse event, long format)
#          - data_dictionary_cleaned.csv (variable mapping)
# ==============================================================================

library(tidyverse)
library(here)

# ==============================================================================
# Performance Monitoring Setup
# ==============================================================================

# Start total timer
script_start_time <- Sys.time()
step_timings <- list()

# Function to track step performance
track_step <- function(step_name) {
  step_time <- Sys.time()
  mem_usage <- as.numeric(object.size(ls(envir = .GlobalEnv))) / 1024^2  # MB

  list(
    step = step_name,
    time = step_time,
    memory_mb = round(mem_usage, 1)
  )
}

cat("=== PERFORMANCE MONITORING ENABLED ===\n")
cat("Start time:", format(script_start_time, "%Y-%m-%d %H:%M:%S"), "\n\n")

# ==============================================================================
# STEP 1: Import Raw Data
# ==============================================================================

# Input file validation
input_file <- here::here("Audit report.csv")

if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}

file_size <- file.info(input_file)$size
max_size <- 100 * 1024^2  # 100 MB
if (file_size > max_size) {
  stop("Input file too large: ", round(file_size / 1024^2, 1), " MB (max ", max_size / 1024^2, " MB)")
}

cat("Reading input file:", input_file, "\n")
cat("File size:", round(file_size / 1024, 1), "KB\n\n")

# Read data with all columns as character initially for safety
raw <- read_csv(input_file, col_types = cols(.default = "c"))

cat("Raw data dimensions:", nrow(raw), "rows x", ncol(raw), "columns\n")

# ==============================================================================
# STEP 2: Remove Section Markers
# ==============================================================================

# These columns are data export artifacts with no actual data
section_markers <- c(
  "Personal Information FINAL",
  "Physician evaluation FINAL",
  "Physical Health Agility FINAL",
  "Cognitive Health Agility- Final",
  "Adverse events FINAL",
  "Body composition FINAL"
)

# Remove section markers
data_no_markers <- raw %>%
  select(-any_of(section_markers))

cat("After removing section markers:", ncol(data_no_markers), "columns\n")

# ==============================================================================
# STEP 3: Create Variable Mapping
# ==============================================================================

# Define domain classification patterns (broken up for readability)
demo_pattern <- paste(
  "study number", "Date of birth", "study.*part of", "Location of visit",
  "Visit number", "Consent", "Health maintenance", "Address", "Phone",
  "Marital", "Lives with", "Living facilities", "drive", "education",
  "Degree", "Profession", "work", "hand", "Study group",
  sep = "|"
)

cog_pattern <- paste(
  "Verbal", "VF ", "DSST", "MoCA", "Moca", "SAGE", "PHQ", "WHO-5",
  "Visuospatial", "Cube", "Clock", "Naming", "Memory", "digit", "Letter",
  "Subtraction", "Language", "Fluency", "Abstraction", "recall", "Orientation",
  "Attention", "Concentration", "Multitask", "Navigation", "Planning", "Finance",
  "Medication Management", "Meal", "Transportation", "Stair", "Walking", "Dressing",
  "Chair Transfer", "Bathing", "Toileting", "activities of daily", "Score - 178",
  "cheerful", "calm", "relaxed", "active", "vigorous", "fresh", "rested",
  "interest", "pleasure", "down.*depressed", "Trouble falling", "tired.*energy",
  "appetite", "bad about yourself", "concentrating", "Moving.*speaking",
  "better off dead", "difficult.*problems",
  sep = "|"
)

med_pattern <- paste(
  "Primary care", "Hospitalization in the past year", "Medical history",
  "Medication \\(ATC", "Diabetes", "diagnosis", "blood pressure", "Cholesterol",
  "LDL", "HDL", "Triglyceride", "Smoker", "Smoked", "sensor", "glucometer",
  "Glucose", "HbA1c", "insulin", "pump", "Metformin", "Sulphonylurea", "Glinide",
  "Acarbose", "DPP-4", "Pioglitazone", "GLP", "SGLT-2", "ACE inhibitor", "AT-2",
  "Statin", "Aspirin", "hypoglycemia", "Hypoglycemia", "DKA", "Heart attack",
  "Stroke", "blood supply.*legs", "Cardiac catheterization", "Ischemic",
  "Cerebrovascular", "Foot ulcer", "Amputation", "PVD", "Retinopathy",
  "Nephropathy", "Albuminuria", "Microalbumin", "Creatinine", "Neuropathy",
  "sensation.*limb", "Limb pain", "Liver", "AST ", "ALT ", "GGT ", "Bilirubin",
  "Alkaline Phosphatase", "Albumin value", "LDH ", "Systolic", "Diastolic", "Pulse",
  sep = "|"
)

ae_pattern <- paste(
  "Free text - 441", "AE - 523", "Serious adverse", "Severe hypoglycemia",
  "Did you fall\\?", "Fracture", "ER admission", "Hospitalization - 109",
  "Institutionalization", "New Disability", "Death", "Other - 113",
  "Gastrointestinal AE", "Endocrine.*AE", "Cardiovascular AE", "Neurological AE",
  "Dermatological.*AE", "Pancreatitis", "Musculoskeletal injur",
  "Exercise related fall",
  sep = "|"
)

phys_pattern <- paste(
  "Do you exercise", "Physical activity.*fitness", "Unintentional weight loss",
  "Fatigue.*Exhaustion", "Physical activity questionnaire", "Slow walk",
  "Muscle weakness", "Frailty", "fall.*past", "Symptoms before falling",
  "hospitalization.*424", "feel tired", "walking up 10 stairs", "walking.*blocks",
  "doctor.*illness", "Loss of weight.*447", "Frail Scale", "Categorization - 449",
  "lifting.*carrying", "walking across", "transferring", "climbing.*flight",
  "fallen.*past year", "SARC-F", "Fat mass", "Fat free", "SMM", "VAT", "Visceral",
  "Waist.*hip", "Calf", "Body Mass Index", "Right Hand", "Left Hand",
  "times reached.*standing", "Distance - 401", "Time to pass", "Speed",
  "Time up.*go", "FSST", "Balance", "SPPB", "affect the results",
  sep = "|"
)

# Create a data frame to track variable transformations
var_map <- tibble(
  original_name = names(data_no_markers),
  position = seq_along(original_name)
) %>%
  mutate(
    # Determine section based on position and name patterns
    section = case_when(
      # Digital DSST (columns 6-7) - check these BEFORE position-based identifier check
      original_name %in% c("Raw DSS Score", "DSST Score") ~ "cognitive",

      # Core identifiers (columns 1-12, excluding DSST)
      position <= 12 ~ "identifier",

      # Personal/demographic information
      str_detect(original_name, demo_pattern) ~ "demographic",

      # Study administration & adherence
      str_detect(original_name, "Drug Injection|Week \\d|exercise sessions|Exercise Session") ~
        "adherence",

      # Cognitive assessments
      str_detect(original_name, cog_pattern) ~ "cognitive",

      # Medical information
      str_detect(original_name, med_pattern) ~ "medical",

      # Adverse events
      str_detect(original_name, ae_pattern) ~ "adverse_events",

      # Physical health & function
      str_detect(original_name, phys_pattern) ~ "physical",

      # Default to medical if still unclear
      TRUE ~ "medical"
    )
  )

# ==============================================================================
# STEP 4: Standardize Variable Names
# ==============================================================================

# Function to clean variable names
clean_var_name <- function(name) {
  # Input validation
  if (is.null(name)) {
    stop("Input cannot be NULL")
  }

  name %>%
    # Remove trailing reference numbers like " - 392"
    str_remove(" - \\d+$") %>%
    # Remove leading question numbers like "15. "
    str_remove("^\\d+\\.\\s+") %>%
    # Remove newlines
    str_replace_all("\\n", " ") %>%
    # Remove sub-field numbers like " - 0." or " - 1." (preserve trailing space)
    str_remove(" - \\d+\\.") %>%
    # Clean up whitespace
    str_squish() %>%
    # Convert to lowercase
    str_to_lower() %>%
    # Replace non-alphanumeric with underscore
    str_replace_all("[^a-z0-9]+", "_") %>%
    # Remove leading underscores
    str_remove("^_+") %>%
    # Remove trailing underscores
    str_remove("_+$") %>%
    # Collapse multiple underscores
    str_replace_all("_{2,}", "_")
}

# Apply cleaning and add domain prefixes
var_map <- var_map %>%
  mutate(
    # Clean the name first
    cleaned_base = clean_var_name(original_name),

    # Add domain prefix based on section
    prefix = case_when(
      section == "identifier" ~ "id",
      section == "demographic" ~ "demo",
      section == "cognitive" ~ "cog",
      section == "medical" ~ "med",
      section == "physical" ~ "phys",
      section == "adherence" ~ "adh",
      section == "adverse_events" ~ "ae",
      TRUE ~ "other"
    ),

    # Combine prefix with cleaned name
    new_name = paste(prefix, cleaned_base, sep = "_")
  )

# Handle duplicate new names by adding sequence numbers
var_map <- var_map %>%
  group_by(new_name) %>%
  mutate(
    n_duplicates = n(),
    seq_num = row_number(),
    new_name = if_else(
      n_duplicates > 1,
      paste0(new_name, "_v", seq_num),
      new_name
    )
  ) %>%
  ungroup() %>%
  select(-n_duplicates, -seq_num)

# Apply new names to data
data_renamed <- data_no_markers
names(data_renamed) <- var_map$new_name

cat("Variables renamed with domain prefixes\n")

# ==============================================================================
# STEP 5: Handle Specific Key Variables
# ==============================================================================

# Identify key identifier and temporal variables
# Keep the first occurrence of study number and DOB
key_id_vars <- c(
  "id_client_id",
  "id_client_name",
  "id_org_id"
)

key_temporal_vars <- c(
  "id_visit_date",
  "id_visit_no",
  "id_visit_type",
  "id_visit_tag"
)

key_demo_vars <- c(
  "id_gender",
  "id_age"
)

# For study number - use the first occurrence (should be id_participants_study_number)
# Remove the duplicates (v2, v3, v4, v5, v6)
study_num_dups <- names(data_renamed)[str_detect(names(data_renamed), "^demo_participants_study_number_v[2-6]$")]

# For date of birth - identify and remove duplicates
dob_vars <- names(data_renamed)[str_detect(names(data_renamed), "date_of_birth")]
dob_dups <- dob_vars[str_detect(dob_vars, "_v[2-5]$")]

# Remove duplicate fields
data_dedup <- data_renamed %>%
  select(-any_of(c(study_num_dups, dob_dups)))

cat("Duplicate identifier fields removed\n")

# ==============================================================================
# STEP 6: Separate Adverse Events from Visits Data
# ==============================================================================

# Identify adverse event columns
ae_cols <- names(data_dedup)[str_starts(names(data_dedup), "ae_")]
visit_cols <- names(data_dedup)[!str_starts(names(data_dedup), "ae_")]

# Create visits dataframe (all non-AE columns)
visits_data <- data_dedup %>%
  select(all_of(visit_cols))

# Create adverse events dataframe
# Include key identifiers + AE columns
id_cols <- names(data_dedup)[str_starts(names(data_dedup), "id_")]

adverse_events <- data_dedup %>%
  select(all_of(c(id_cols, ae_cols)))

cat("Visits data:", ncol(visits_data), "columns\n")
cat("Adverse events data:", ncol(adverse_events), "columns\n")

# ==============================================================================
# STEP 7: Type Conversion for Visits Data
# ==============================================================================

# Function to safely convert to numeric
safe_numeric <- function(x) {
  # Input validation
  if (is.null(x)) {
    stop("Input cannot be NULL")
  }

  # Extract numeric values, handling formats like "36/41"
  x_clean <- str_extract(x, "^[0-9]+\\.?[0-9]*")
  as.numeric(x_clean)
}

# Function to safely convert to date
safe_date <- function(x) {
  # Input validation
  if (is.null(x)) {
    stop("Input cannot be NULL")
  }

  # Vectorized date conversion with multiple format attempts
  result <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))

  # For elements that are still NA, try other formats
  still_na <- is.na(result) & !is.na(x)
  if (any(still_na)) {
    result[still_na] <- suppressWarnings(as.Date(x[still_na], format = "%d/%m/%Y"))
  }

  still_na <- is.na(result) & !is.na(x)
  if (any(still_na)) {
    result[still_na] <- suppressWarnings(as.Date(x[still_na], format = "%m/%d/%Y"))
  }

  result
}

# Convert key date variables
date_vars <- names(visits_data)[str_detect(names(visits_data), "date|Date")]

visits_data <- visits_data %>%
  mutate(across(
    all_of(date_vars),
    ~safe_date(.x)
  ))

# Convert key numeric variables
# Age, visit number, and other clearly numeric fields
numeric_patterns <- c(
  "age", "visit_no", "score", "value", "number", "years", "units", "bmi",
  "height", "weight", "systolic", "diastolic", "pulse", "percentile",
  "ratio", "mass", "vat", "circumference", "distance", "time", "speed",
  "test_\\d", "trial"
)

numeric_vars <- names(visits_data)[
  str_detect(names(visits_data), paste(numeric_patterns, collapse = "|")) &
  !str_detect(names(visits_data), "date|Date|type|unit|Unit")
]

visits_data <- visits_data %>%
  mutate(across(
    all_of(numeric_vars),
    ~safe_numeric(.x)
  ))

# Convert binary/logical variables
# Variables that are checkboxes or yes/no
binary_patterns <- c(
  "^med_medical_history", "^med_medication", "use_of", "known", "smoker",
  "consent", "drive", "work", "experienced", "feels", "wakes", "suffers",
  "underwent", "decreased", "ischemic", "cerebrovascular", "pvd",
  "private_house", "apartment", "stairs", "elevator", "aerobic", "resistance"
)

binary_vars <- names(visits_data)[
  str_detect(names(visits_data), paste(binary_patterns, collapse = "|"))
]

visits_data <- visits_data %>%
  mutate(across(
    all_of(binary_vars),
    ~case_when(
      str_detect(tolower(.x), "^yes$|^true$|^1$") ~ TRUE,
      str_detect(tolower(.x), "^no$|^false$|^0$") ~ FALSE,
      is.na(.x) ~ NA,
      TRUE ~ NA
    )
  ))

cat("Type conversion completed for visits data\n")

# ==============================================================================
# STEP 8: Type Conversion for Adverse Events Data
# ==============================================================================

# Convert dates in adverse events
ae_date_vars <- names(adverse_events)[str_detect(names(adverse_events), "date|Date")]

adverse_events <- adverse_events %>%
  mutate(across(
    all_of(ae_date_vars),
    ~safe_date(.x)
  ))

# Convert numeric fields in adverse events
ae_numeric_patterns <- c("score", "number", "severity", "count")
ae_numeric_vars <- names(adverse_events)[
  str_detect(names(adverse_events), paste(ae_numeric_patterns, collapse = "|")) &
  !str_detect(names(adverse_events), "date|Date|type|unit")
]

adverse_events <- adverse_events %>%
  mutate(across(
    all_of(ae_numeric_vars),
    ~safe_numeric(.x)
  ))

cat("Type conversion completed for adverse events data\n")

# ==============================================================================
# STEP 9: Patient-Level Missing Data Handling
# ==============================================================================

# For time-invariant variables (characteristics that don't change across visits),
# fill missing values within each patient using available data from any visit.
# A variable is only considered "missing" for a patient if it's missing at ALL visits.

cat("Handling patient-level missingness for time-invariant variables...\n")

# Identify time-invariant variables (should be same across all visits for a patient)
# These are demographic and baseline clinical characteristics
time_invariant_patterns <- c(
  # Demographics
  "^demo_participants_study_number",
  "^demo_date_of_birth",
  "^demo_which_study",
  "^demo_study_group",
  "^demo_number_of_education",
  "^demo_educational_degree",
  "^demo_profession",
  "^demo_dominant_hand",
  "^demo_marital_status",

  # Living situation (may change but typically stable)
  "^demo_health_maintenance",
  "^demo_address",
  "^demo_phone",
  "^demo_lives_with",
  "^demo_living_facilities",
  "^demo_do_you_drive",

  # Baseline medical history
  "^med_diabetes_mellitus_type",
  "^med_year_of_diagnosis",

  # Medical history categories (typically don't change - you can't un-have a disease)
  "^med_medical_history",

  # Baseline physical characteristics
  "^id_gender"
)

# Find columns matching these patterns
time_invariant_cols <- names(visits_data)[
  str_detect(names(visits_data), paste(time_invariant_patterns, collapse = "|"))
]

cat("  Found", length(time_invariant_cols), "time-invariant variables\n")

# For each patient, fill missing values with available data from other visits
# Using fill() function which carries forward/backward within groups
visits_data <- visits_data %>%
  arrange(id_client_id, id_visit_no) %>%
  group_by(id_client_id) %>%
  fill(all_of(time_invariant_cols), .direction = "downup") %>%  # Fill both directions
  ungroup()

cat("  Patient-level filling complete\n")

# Calculate total number of patients dynamically
n_patients <- n_distinct(visits_data$id_client_id)

# Report on remaining patient-level missingness
patients_with_data <- visits_data %>%
  group_by(id_client_id) %>%
  summarise(across(
    all_of(time_invariant_cols),
    ~any(!is.na(.x))
  )) %>%
  summarise(across(
    -id_client_id,
    ~sum(.x)
  ))

cat("  Patients with at least one value (after filling):\n")
cat("    Education years:", patients_with_data$demo_number_of_education_years, "/", n_patients, "\n")
cat("    Dominant hand:", patients_with_data$demo_dominant_hand, "/", n_patients, "\n")
cat("    Marital status:", patients_with_data$demo_marital_status, "/", n_patients, "\n")

# ==============================================================================
# STEP 10: Quality Checks
# ==============================================================================

cat("\n=== DATA QUALITY CHECKS ===\n\n")

# Check 1: Unique patients
cat("1. PATIENT COUNTS:\n")
cat("   Total observations (rows):", nrow(visits_data), "\n")
cat("   Unique patients:", n_distinct(visits_data$id_client_id), "\n")
cat("   Observations per patient:\n")
print(table(table(visits_data$id_client_id)))

# Check 2: Visit distribution
cat("\n2. VISIT DISTRIBUTION:\n")
cat("   Visits per patient:\n")

# Calculate visit distribution (supports 0-3 visits)
visit_dist <- visits_data %>%
  count(id_client_id) %>%
  count(n, name = "n_patients")

print(visit_dist)

# Warn if any patients have 0 visits (shouldn't happen in normal data)
if (nrow(visits_data) == 0) {
  warning("WARNING: No visit data found in dataset!")
}

# Check for expected visit range (0-3)
visit_numbers <- unique(visits_data$id_visit_no)
unexpected_visits <- visit_numbers[!visit_numbers %in% 0:3 & !is.na(visit_numbers)]
if (length(unexpected_visits) > 0) {
  warning("WARNING: Found unexpected visit numbers: ", paste(unexpected_visits, collapse = ", "))
  cat("   ⚠ Unexpected visit numbers detected:", paste(unexpected_visits, collapse = ", "), "\n")
}

# Check 3: DSST scores (check both versions are present)
cat("\n3. DSST SCORES:\n")
# Find digital DSST variables (columns 6-7 from original data: "Raw DSS Score" and "DSST Score")
digital_dsst_vars <- names(visits_data)[
  str_detect(names(visits_data), "cog.*raw.*dss|cog.*dsst.*score") &
  !str_detect(names(visits_data), "total")
]
if (length(digital_dsst_vars) > 0) {
  cat("   Digital DSST variables found:", length(digital_dsst_vars), "\n")
  for (var in digital_dsst_vars) {
    cat("   -", var, "- non-missing:", sum(!is.na(visits_data[[var]])), "\n")
  }
}

# Check if paper DSST exists (look for variables with "dsst.*total" pattern)
paper_dsst_vars <- names(visits_data)[
  str_detect(names(visits_data), "cog.*dsst.*total|cog.*standardized_score")
]
if (length(paper_dsst_vars) > 0) {
  cat("   Paper DSST variables found:", paste(paper_dsst_vars, collapse = ", "), "\n")
  for (var in paper_dsst_vars) {
    cat("   -", var, "- non-missing:", sum(!is.na(visits_data[[var]])), "\n")
  }
}

# Check 4: Adverse events
cat("\n4. ADVERSE EVENTS:\n")
cat("   Total AE observations:", nrow(adverse_events), "\n")
cat("   AE columns:", ncol(adverse_events) - length(id_cols), "(excluding ID columns)\n")

# Check 5: Variable counts by domain
cat("\n5. VARIABLES BY DOMAIN:\n")
domain_counts <- tibble(
  domain = c("id", "demo", "cog", "med", "phys", "adh", "ae"),
  count = c(
    sum(str_starts(names(data_dedup), "id_")),
    sum(str_starts(names(data_dedup), "demo_")),
    sum(str_starts(names(data_dedup), "cog_")),
    sum(str_starts(names(data_dedup), "med_")),
    sum(str_starts(names(data_dedup), "phys_")),
    sum(str_starts(names(data_dedup), "adh_")),
    sum(str_starts(names(data_dedup), "ae_"))
  )
)
print(domain_counts)

# Check 6: Date ranges
cat("\n6. DATE RANGES:\n")
cat("   Visit dates range:",
    format(min(visits_data$id_visit_date, na.rm = TRUE), "%Y-%m-%d"), "to",
    format(max(visits_data$id_visit_date, na.rm = TRUE), "%Y-%m-%d"), "\n")

# Check 7: Age distribution
cat("\n7. AGE DISTRIBUTION:\n")
cat("   Age range:", min(visits_data$id_age, na.rm = TRUE), "-",
    max(visits_data$id_age, na.rm = TRUE), "years\n")
cat("   Mean age:", round(mean(visits_data$id_age, na.rm = TRUE), 1), "years\n")

# Check 8: Gender distribution
cat("\n8. GENDER DISTRIBUTION:\n")
print(table(visits_data$id_gender, useNA = "ifany"))

# ==============================================================================
# STEP 11: Save Cleaned Data
# ==============================================================================

# Create data directory if it doesn't exist
if (!dir.exists("data")) {
  dir.create("data")
}

# Save visits data
visits_file <- here::here("data/visits_data.rds")
saveRDS(visits_data, visits_file)
Sys.chmod(visits_file, mode = "0600")  # Owner read/write only
cat("\n✓ Saved: data/visits_data.rds (permissions: 0600)\n")

# Save adverse events data
ae_file <- here::here("data/adverse_events_data.rds")
saveRDS(adverse_events, ae_file)
Sys.chmod(ae_file, mode = "0600")  # Owner read/write only
cat("✓ Saved: data/adverse_events_data.rds (permissions: 0600)\n")

# Save variable mapping
dict_file <- here::here("data/data_dictionary_cleaned.csv")
write_csv(var_map, dict_file)
Sys.chmod(dict_file, mode = "0600")  # Owner read/write only
cat("✓ Saved: data/data_dictionary_cleaned.csv (permissions: 0600)\n")

# ==============================================================================
# STEP 12: Create Summary Statistics
# ==============================================================================

# Calculate summary statistics for documentation
summary_stats <- list(
  n_patients = n_distinct(visits_data$id_client_id),
  n_observations = nrow(visits_data),
  n_visits_per_patient = visits_data %>%
    count(id_client_id) %>%
    pull(n) %>%
    summary(),
  n_variables_total = ncol(data_dedup),
  n_variables_visits = ncol(visits_data),
  n_variables_ae = ncol(adverse_events) - length(id_cols),
  date_range = range(visits_data$id_visit_date, na.rm = TRUE),
  age_range = range(visits_data$id_age, na.rm = TRUE),
  n_variables_by_domain = domain_counts
)

# Save summary statistics
stats_file <- here::here("data/summary_statistics.rds")
saveRDS(summary_stats, stats_file)
Sys.chmod(stats_file, mode = "0600")  # Owner read/write only
cat("✓ Saved: data/summary_statistics.rds (permissions: 0600)\n")

cat("\n=== DATA CLEANING COMPLETE ===\n")
cat("Next step: Create data cleaning report (docs/cleaning_report.md)\n")

# ==============================================================================
# Performance Summary
# ==============================================================================

script_end_time <- Sys.time()
total_duration <- as.numeric(difftime(script_end_time, script_start_time, units = "secs"))
peak_memory_mb <- as.numeric(object.size(lapply(ls(), get))) / 1024^2

cat("\n=== PERFORMANCE SUMMARY ===\n")
cat("Total execution time:", round(total_duration, 2), "seconds\n")
cat("Peak memory usage:", round(peak_memory_mb, 1), "MB\n")
cat("Processed:", n_patients, "patients with", nrow(visits_data), "visit records\n")
cat("Throughput:", round(nrow(visits_data) / total_duration, 1), "records/second\n")
