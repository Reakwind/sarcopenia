# Sarcopenia Data Cleaning Pipeline - Developer Specification

**Version**: 2.0
**Last Updated**: 2025-10-22
**Status**: Implementation Phase

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Data Structure](#data-structure)
3. [Critical Concept: Missingness Logic](#critical-concept-missingness-logic)
4. [Pipeline Architecture](#pipeline-architecture)
5. [Data Dictionary Metadata](#data-dictionary-metadata)
6. [Function Specifications](#function-specifications)
7. [Implementation Guidelines](#implementation-guidelines)
8. [Testing Requirements](#testing-requirements)
9. [Deployment Considerations](#deployment-considerations)

---

## Project Overview

### Purpose
Clean and process longitudinal sarcopenia study data from audit report CSVs, properly handling missing data patterns across patient visits.

### Key Requirements
- **Input**: Raw CSV audit reports (~575 columns × 38 rows)
- **Output**: Two cleaned datasets (visits data, adverse events data)
- **Critical Feature**: Distinguish between "test not performed this visit" (empty string "") vs "truly missing across all visits" (NA)
- **Deployment**: Single-file Shiny app on shinyapps.io

### Technology Stack
- **Language**: R (base R + tidyverse)
- **UI Framework**: Shiny with bslib
- **Data Visualization**: reactable
- **Deployment**: shinyapps.io

---

## Data Structure

### Format
- **Longitudinal data in long format**
- Each row = one patient visit
- Each patient has 0-3 visits
- ~575 variables per visit
- 20 unique patients in test data

### Example Structure
```
Patient ID | Visit | Education | MoCA Score | Grip Strength
004-00232  |   1   |    16     |    29      |    25.3
004-00232  |   2   |    NA     |    NA      |    24.8
004-00232  |   5   |    NA     |    NA      |    NA
```

### Variable Categories
Based on `data_dictionary_enhanced.csv`:

1. **Time-Invariant** (n=108)
   - Demographics: study number, date of birth, education years, educational degree, profession, dominant hand
   - Baseline medical: diabetes type, year of diagnosis, medical history (ICD9 codes)
   - Identifiers: patient ID, patient name, gender
   - Measurement units: All `_unit` columns

2. **Time-Varying** (n=416)
   - Cognitive assessments: MoCA, DSST, PHQ-9, verbal fluency
   - Physical assessments: SPPB, gait speed, chair stand, grip strength
   - Functional assessments: ADL, IADL, frailty scales
   - Medical measurements: BMI, blood pressure, pulse
   - Questionnaires: Mood, physical activity, fatigue

3. **Adverse Events** (n=45)
   - Falls, fractures, hospitalizations, ER admissions
   - Special handling: Never convert to NA, leave empty if empty

---

## Critical Concept: Missingness Logic

### The Problem
Raw CSV reads empty cells as `""` (empty string). We must distinguish:
- **Empty String ("")**: Test not performed THIS visit (but patient has data in other visits)
- **NA**: Truly missing (empty across ALL patient's visits)

### Rules by Variable Category

#### 1. Time-Invariant Variables
**Examples**: Education years, date of birth, gender, study group

**Logic**:
```
IF variable is time-invariant:
  1. For each patient:
     - IF has non-empty value in ANY visit → Fill that value to ALL visits
     - IF empty in ALL visits → Convert all to NA
```

**Example**:
```r
# Patient 004-00232, education years
Visit 1: "16"   → Keep: 16
Visit 2: ""     → Fill: 16
Visit 5: ""     → Fill: 16

# Patient 004-00233, education years
Visit 1: ""     → Convert: NA
Visit 2: ""     → Convert: NA
Visit 3: ""     → Convert: NA
```

#### 2. Time-Varying Variables
**Examples**: MoCA score, grip strength, PHQ-9, gait speed

**Logic**:
```
IF variable is time-varying:
  1. For each patient:
     - IF has non-empty value in ANY visit:
       - Keep non-empty values as-is
       - Keep empty values as "" (test not performed)
     - IF empty in ALL visits → Convert all to NA (truly missing)
  2. Create dual columns:
     - original_col: Keep as character (preserves "" vs NA distinction)
     - original_col_numeric: Convert to numeric for analysis (both "" and NA → NA)
```

**Example**:
```r
# Patient 004-00232, MoCA score
Visit 1: "29"   → original: "29", _numeric: 29
Visit 2: ""     → original: "",   _numeric: NA (test not performed)
Visit 5: ""     → original: "",   _numeric: NA (test not performed)

# Patient 004-00233, MoCA score
Visit 1: ""     → original: NA,   _numeric: NA (truly missing)
Visit 2: ""     → original: NA,   _numeric: NA (truly missing)
Visit 3: ""     → original: NA,   _numeric: NA (truly missing)
```

#### 3. Adverse Events
**Logic**:
```
IF variable is adverse_event:
  - NEVER convert to NA
  - Leave empty as empty string ""
  - These are event logs, not measurements
```

#### 4. Measurement Units
**Logic**:
```
IF variable ends with "_unit":
  - Treat as time-invariant
  - Fill forward within patient
  - Units don't change across visits
```

---

## Pipeline Architecture

### Current Issues (v1.0)
1. ❌ Doesn't distinguish "" from NA before processing
2. ❌ No patient-level NA conversion
3. ❌ No dual column creation for time-varying variables
4. ❌ Factorization happens before filling (type mismatch)

### New Architecture (v2.0)

```
clean_csv(raw_data)
├── 1. remove_section_markers()
├── 2. apply_variable_mapping(data, dict)
├── 3. split_visits_and_ae(data)
│   ├── visits_data
│   └── adverse_events_data
├── 4. convert_patient_level_na(visits_data, dict)  [NEW]
│   └── "" → NA if empty across ALL patient visits
├── 5. fill_time_invariant(visits_data, dict)       [NEW]
│   └── Fill time-invariant vars within patient
├── 6. create_analysis_columns(visits_data, dict)   [NEW]
│   ├── Identify time-varying numeric/date/binary/categorical
│   ├── Create original_col (character, preserves "" vs NA)
│   └── Create original_col_numeric/date/factor (for analysis)
├── 7. convert_column_types(visits_data)
│   └── Type conversion for non-dual columns
├── 8. generate_summary(raw_data, visits_data, ae_data)
└── 9. generate_quality_report(visits_data, dict)   [NEW]
    └── Missingness patterns, data quality metrics
```

---

## Data Dictionary Metadata

### Enhanced Dictionary Structure
**File**: `data_dictionary_enhanced.csv` (569 rows × 12 columns)

**Columns**:
1. `original_name`: Raw column name from CSV
2. `position`: Column position in raw data
3. `section`: Section category (identifier, demographic, medical, physical, cognitive, adverse_events)
4. `cleaned_base`: Base cleaned name
5. `prefix`: Variable prefix (id, demo, med, phys, cog, ae)
6. `new_name`: Final cleaned variable name
7. `variable_category`: **time_invariant | time_varying | adverse_event**
8. `data_type`: **numeric | binary | categorical | date | text**
9. `instrument`: Assessment instrument name (MoCA, DSST, PHQ-9, SPPB, etc.)
10. `description`: Human-readable description
11. `score_range`: Valid score ranges for instruments
12. `response_options`: Valid response options (for future use)

### Usage in Pipeline
```r
# Load enhanced dictionary
dict <- read_csv("data_dictionary_enhanced.csv")

# Get time-invariant variables
time_inv_vars <- dict %>%
  filter(variable_category == "time_invariant") %>%
  pull(new_name)

# Get time-varying numeric variables
time_var_numeric <- dict %>%
  filter(variable_category == "time_varying",
         data_type %in% c("numeric", "binary")) %>%
  pull(new_name)

# Get adverse event variables
ae_vars <- dict %>%
  filter(variable_category == "adverse_event") %>%
  pull(new_name)
```

---

## Function Specifications

### 1. `convert_patient_level_na(data, dict)`

**Purpose**: Convert empty strings to NA ONLY when empty across all patient visits

**Input**:
- `data`: Dataframe with id_client_id column
- `dict`: Enhanced data dictionary

**Output**: Dataframe with patient-level "" → NA conversion

**Algorithm**:
```r
convert_patient_level_na <- function(data, dict) {
  # Get non-adverse-event columns
  target_cols <- dict %>%
    filter(variable_category != "adverse_event") %>%
    pull(new_name) %>%
    intersect(names(data))

  # Get unique patients
  patient_ids <- unique(data$id_client_id)

  # For each target column
  for (col in target_cols) {
    # For each patient
    for (pid in patient_ids) {
      # Get patient's rows
      patient_mask <- data$id_client_id == pid
      patient_values <- data[[col]][patient_mask]

      # Check if ALL values are empty string
      all_empty <- all(patient_values == "" | is.na(patient_values))

      if (all_empty) {
        # Convert all to NA for this patient
        data[[col]][patient_mask] <- NA
      }
    }
  }

  return(data)
}
```

**Test Case**:
```r
# Input
#   Patient | Visit | Education
#   001     | 1     | "16"
#   001     | 2     | ""
#   002     | 1     | ""
#   002     | 2     | ""

# Output
#   Patient | Visit | Education
#   001     | 1     | "16"      (has value in visit 1)
#   001     | 2     | ""        (keep empty - has value elsewhere)
#   002     | 1     | NA        (empty in ALL visits)
#   002     | 2     | NA        (empty in ALL visits)
```

---

### 2. `fill_time_invariant(data, dict)`

**Purpose**: Fill time-invariant variables within each patient

**Input**:
- `data`: Dataframe with patient-level NAs converted
- `dict`: Enhanced data dictionary

**Output**: Dataframe with time-invariant variables filled

**Algorithm**:
```r
fill_time_invariant <- function(data, dict) {
  # Get time-invariant columns
  time_inv_cols <- dict %>%
    filter(variable_category == "time_invariant") %>%
    pull(new_name) %>%
    intersect(names(data))

  patient_ids <- unique(data$id_client_id)

  # For each time-invariant column
  for (col in time_inv_cols) {
    # For each patient
    for (pid in patient_ids) {
      patient_mask <- data$id_client_id == pid
      patient_indices <- which(patient_mask)
      patient_values <- data[[col]][patient_indices]

      # Get first non-NA, non-empty value
      non_missing <- patient_values[!is.na(patient_values) & patient_values != ""]

      if (length(non_missing) > 0) {
        fill_value <- non_missing[1]

        # Fill all empty strings and NAs
        for (idx in patient_indices) {
          if (is.na(data[[col]][idx]) || data[[col]][idx] == "") {
            data[[col]][idx] <- fill_value
          }
        }
      }
    }
  }

  return(data)
}
```

**Test Case**:
```r
# Input (after convert_patient_level_na)
#   Patient | Visit | Education
#   001     | 1     | "16"
#   001     | 2     | ""
#   002     | 1     | NA
#   002     | 2     | NA

# Output
#   Patient | Visit | Education
#   001     | 1     | "16"      (original value)
#   001     | 2     | "16"      (filled from visit 1)
#   002     | 1     | NA        (truly missing - no fill)
#   002     | 2     | NA        (truly missing - no fill)
```

---

### 3. `create_analysis_columns(data, dict)`

**Purpose**: Create dual columns for time-varying variables

**Input**:
- `data`: Dataframe with filled time-invariant vars
- `dict`: Enhanced data dictionary

**Output**: Dataframe with additional _numeric, _date, _factor columns

**Algorithm**:
```r
create_analysis_columns <- function(data, dict) {
  # Get time-varying variables by data type
  time_var_numeric <- dict %>%
    filter(variable_category == "time_varying",
           data_type == "numeric") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_binary <- dict %>%
    filter(variable_category == "time_varying",
           data_type == "binary") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_categorical <- dict %>%
    filter(variable_category == "time_varying",
           data_type == "categorical") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_date <- dict %>%
    filter(variable_category == "time_varying",
           data_type == "date") %>%
    pull(new_name) %>%
    intersect(names(data))

  # Create numeric analysis columns
  for (col in time_var_numeric) {
    new_col_name <- paste0(col, "_numeric")
    data[[new_col_name]] <- suppressWarnings(as.numeric(data[[col]]))
  }

  # Create binary/categorical factor columns
  for (col in c(time_var_binary, time_var_categorical)) {
    new_col_name <- paste0(col, "_factor")
    # Only factorize non-empty values
    data[[new_col_name]] <- ifelse(data[[col]] == "" | is.na(data[[col]]),
                                    NA,
                                    as.factor(data[[col]]))
  }

  # Create date columns
  for (col in time_var_date) {
    new_col_name <- paste0(col, "_date")
    data[[new_col_name]] <- parse_date_time(data[[col]],
                                              orders = c("ymd", "dmy", "mdy"),
                                              quiet = TRUE) %>%
                             as.Date()
  }

  return(data)
}
```

**Test Case**:
```r
# Input
#   Patient | Visit | cog_moca_total_score
#   001     | 1     | "29"
#   001     | 2     | ""
#   002     | 1     | NA
#   002     | 2     | NA

# Output
#   Patient | Visit | cog_moca_total_score | cog_moca_total_score_numeric
#   001     | 1     | "29"                 | 29
#   001     | 2     | ""                   | NA
#   002     | 1     | NA                   | NA
#   002     | 2     | NA                   | NA
```

---

### 4. `generate_quality_report(data, dict)`

**Purpose**: Generate data quality metrics and missingness patterns

**Output**: List with quality statistics

**Metrics to Include**:
1. **Missingness by variable category**:
   - Time-invariant: % truly missing (NA) vs % filled
   - Time-varying: % NA, % empty (""), % with values

2. **Missingness by patient**:
   - Patient ID
   - Number of visits
   - % variables missing per visit
   - Complete vs incomplete variables

3. **Instrument completeness**:
   - For each instrument (MoCA, DSST, etc.)
   - % patients with complete data
   - % patients with partial data
   - % patients with no data

4. **Data quality flags**:
   - Variables with >50% missingness
   - Patients with <50% completeness
   - Out-of-range values for scored instruments

**Algorithm**:
```r
generate_quality_report <- function(data, dict) {
  report <- list()

  # 1. Overall missingness
  report$overall <- data %>%
    summarise(across(everything(), ~sum(is.na(.) | . == ""))) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
    mutate(pct_missing = n_missing / nrow(data) * 100) %>%
    arrange(desc(pct_missing))

  # 2. By variable category
  report$by_category <- dict %>%
    select(new_name, variable_category, instrument) %>%
    left_join(report$overall, by = c("new_name" = "variable")) %>%
    group_by(variable_category) %>%
    summarise(
      n_vars = n(),
      mean_pct_missing = mean(pct_missing, na.rm = TRUE),
      median_pct_missing = median(pct_missing, na.rm = TRUE)
    )

  # 3. By patient
  report$by_patient <- data %>%
    group_by(id_client_id) %>%
    summarise(
      n_visits = n(),
      pct_complete = mean(!is.na(.) & . != "", na.rm = TRUE) * 100
    ) %>%
    arrange(pct_complete)

  # 4. By instrument
  report$by_instrument <- dict %>%
    filter(!is.na(instrument)) %>%
    select(new_name, instrument) %>%
    left_join(report$overall, by = c("new_name" = "variable")) %>%
    group_by(instrument) %>%
    summarise(
      n_vars = n(),
      mean_pct_missing = mean(pct_missing, na.rm = TRUE)
    ) %>%
    arrange(mean_pct_missing)

  return(report)
}
```

---

## Implementation Guidelines

### Order of Operations (CRITICAL)

1. ✅ Load raw CSV with `col_types = cols(.default = "c")` (all character)
2. ✅ Apply variable name mapping
3. ✅ Split visits and adverse events
4. ✅ **Convert patient-level NAs** (MUST be first cleaning step)
5. ✅ **Fill time-invariant variables** (MUST be after NA conversion)
6. ✅ **Create dual analysis columns** (MUST be before type conversion)
7. ✅ Convert column types for remaining variables
8. ✅ Generate summaries and quality reports

### Common Pitfalls

**❌ DON'T DO THIS**:
```r
# Converting to numeric before patient-level NA conversion
data$moca <- as.numeric(data$moca)  # Converts "" to NA too early!

# Factorizing before filling
data$gender <- as.factor(data$gender)
# Then trying to fill: Error - can't assign character to factor
```

**✅ DO THIS**:
```r
# Keep as character through all patient-level operations
data$education <- as.character(data$education)

# Convert patient-level NAs
data <- convert_patient_level_na(data, dict)

# Fill time-invariant
data <- fill_time_invariant(data, dict)

# THEN create analysis columns with proper types
data <- create_analysis_columns(data, dict)
```

### Performance Considerations

For large datasets (>10,000 rows):
- Use vectorized operations where possible
- Consider `data.table` for patient-level operations
- Profile with `profvis` package
- Test with progressr for progress reporting

### Error Handling

```r
# Validate required columns
required_cols <- c("id_client_id", "id_visit_no")
if (!all(required_cols %in% names(data))) {
  stop("Missing required columns: ",
       paste(setdiff(required_cols, names(data)), collapse = ", "))
}

# Validate data dictionary
if (!"variable_category" %in% names(dict)) {
  stop("Data dictionary missing 'variable_category' column. ",
       "Please use enhanced dictionary.")
}

# Check for duplicate patient-visit combinations
dupes <- data %>%
  group_by(id_client_id, id_visit_no) %>%
  filter(n() > 1)

if (nrow(dupes) > 0) {
  warning("Duplicate patient-visit combinations found: ", nrow(dupes))
}
```

---

## Testing Requirements

### Unit Tests

Each function must have tests covering:

1. **Normal cases**:
   - Single patient, single visit
   - Single patient, multiple visits
   - Multiple patients, varying visits

2. **Edge cases**:
   - Patient with all NAs
   - Patient with all empty strings
   - Patient with mixed NA and ""
   - Variable with all missing data
   - Variable with no missing data

3. **Error conditions**:
   - Missing id_client_id column
   - Invalid data types
   - Empty dataframe
   - Mismatched dictionary

### Integration Tests

**Test File**: Use `Audit report.csv` (38 rows, 20 patients)

**Test Cases**:
```r
# Test 1: Time-invariant filling
test_that("Education years filled within patient", {
  cleaned <- clean_csv(raw_data)

  patient_232 <- cleaned$visits_data %>%
    filter(id_client_id == "004-00232")

  # All visits should have education = 16
  expect_equal(unique(patient_232$demo_number_of_education_years), "16")
})

# Test 2: Time-varying preservation
test_that("MoCA empty preserved when has value in other visit", {
  cleaned <- clean_csv(raw_data)

  patient_232 <- cleaned$visits_data %>%
    filter(id_client_id == "004-00232")

  # Visit 1 should have MoCA = "29" (character)
  expect_equal(patient_232$cog_moca_total_score[patient_232$id_visit_no == 1], "29")

  # Visit 2 should have MoCA = "" (not NA)
  expect_equal(patient_232$cog_moca_total_score[patient_232$id_visit_no == 2], "")

  # Visit 2 _numeric should be NA
  expect_true(is.na(patient_232$cog_moca_total_score_numeric[patient_232$id_visit_no == 2]))
})

# Test 3: Patient-level NA conversion
test_that("Variables missing in all visits become NA", {
  # Create test patient with all empty for variable X
  # Verify all converted to NA, not ""
})

# Test 4: Adverse events unchanged
test_that("Adverse events preserve empty strings", {
  cleaned <- clean_csv(raw_data)

  # Empty AE fields should remain ""
  ae_empty <- cleaned$adverse_events_data %>%
    filter(is.na(ae_did_you_fall))

  # Should not have NA, only ""
  expect_true(all(is.na(ae_empty$ae_did_you_fall) |
                  ae_empty$ae_did_you_fall == ""))
})
```

### Validation Tests

After integration test, manually verify:
1. Open cleaned visits CSV in Excel
2. Check patient 004-00232:
   - Education = 16 in all 3 visits ✓
   - MoCA = 29 (visit 1), empty (visits 2,5) ✓
   - MoCA_numeric = 29 (visit 1), NA (visits 2,5) ✓
3. Check variable with all missing → all NA
4. Check adverse events → no NAs introduced

---

## Deployment Considerations

### shinyapps.io Specifics

**Issue**: Package loading vs sourcing conflicts

**Solution**: Single-file app approach
- All functions in app.R
- No separate R/ directory
- Data dictionary in inst/ or root

**Deployment checklist**:
```r
# 1. Ensure all dependencies listed
library(shiny)
library(bslib)
library(reactable)
library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(stringr)

# 2. Data dictionary must be accessible
# Place in same directory as app.R
file.exists("data_dictionary_enhanced.csv")

# 3. Test locally first
runApp()

# 4. Deploy
rsconnect::deployApp(appName = "sarcDash", forceUpdate = TRUE)
```

### Memory Considerations

- Reactive values can grow large with full dataset
- Use `req()` to prevent unnecessary recalculation
- Clear intermediate objects after use
- Monitor with `pryr::object_size()`

### Security

- Validate uploaded file size (<10MB recommended)
- Check file extension (.csv only)
- Sanitize column names
- No user code evaluation (avoid `eval()`, `parse()`)

---

## Change Log

### v2.0 (2025-10-22)
- Added patient-level NA conversion logic
- Implemented dual column approach for time-varying variables
- Enhanced data dictionary with metadata
- Separated time-invariant filling from type conversion
- Added quality reporting functions

### v1.0 (Previous)
- Basic cleaning pipeline
- Variable name mapping
- Type conversion
- Split visits and adverse events
- (Had issues with missingness logic)

---

## References

### Assessment Instruments
- **MoCA**: Nasreddine et al. (2005) - Montreal Cognitive Assessment
- **DSST**: Wechsler Adult Intelligence Scale
- **PHQ-9**: Kroenke et al. (2001) - Patient Health Questionnaire
- **SPPB**: Guralnik et al. (1994) - Short Physical Performance Battery
- **Grip Strength**: EWGSOP2 sarcopenia criteria
- **ADL/IADL**: Katz Index, Lawton Scale

### Data Dictionary
- Location: `data_dictionary_enhanced.csv`
- Generated by: `enhance_data_dictionary.R`
- Last updated: 2025-10-22

### Test Data
- Location: `/Users/etaycohen/Documents/Sarcopenia/Audit report.csv`
- Patients: 20 unique
- Rows: 38 (visit records)
- Columns: 575 (raw variables)

---

## Contact & Support

For questions about this specification:
1. Review DATA_CLEANING_RULES.md for business logic
2. Check test cases in this document
3. Run integration tests with Audit report.csv
4. Verify against enhanced data dictionary

**Critical Reminders**:
- ✅ Always convert patient-level NAs BEFORE filling
- ✅ Keep data as character through patient-level operations
- ✅ Create dual columns for time-varying variables
- ✅ Test with real data (Audit report.csv) before deployment
- ✅ Adverse events NEVER get NA conversion
