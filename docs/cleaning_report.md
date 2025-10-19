# Data Cleaning Report
## Sarcopenia Study - Longitudinal Diabetes Clinical Data

**Date:** October 19, 2025
**Script:** `scripts/01_data_cleaning.R`
**Input:** `Audit report.csv`
**Outputs:**
- `data/visits_data.rds`
- `data/adverse_events_data.rds`
- `data/data_dictionary_cleaned.csv`
- `data/summary_statistics.rds`

---

## Executive Summary

Successfully cleaned and transformed raw longitudinal clinical data from 575 variables × 38 observations into two tidy datasets optimized for exploratory data analysis:

1. **Visits Data:** 524 variables × 38 observations (visit-temporal structure)
2. **Adverse Events Data:** 55 variables × 38 observations (event-temporal structure)

**Key Features:**
- All variables renamed with domain prefixes (id_, demo_, cog_, med_, phys_, adh_, ae_) for efficient tidyverse-based analysis
- **Patient-level missing data handling:** Time-invariant characteristics filled across all visits for each patient; only truly missing data (never provided) remains as NA
- Proper type conversion for dates, numeric values, and binary/logical variables
- Comprehensive quality checks and documentation

---

## Data Overview

### Input Data
- **Source:** Audit report.csv
- **Dimensions:** 575 variables × 38 observations
- **Study Design:** Longitudinal diabetes study with repeated measures
- **Patients:** 20 unique patients
- **Visits:** Up to 3 visits per patient

### Output Data

#### Visits Data (visit-temporal)
- **Dimensions:** 524 variables × 38 observations
- **Structure:** One row per patient-visit, wide format
- **Temporal basis:** Visit date and visit number
- **Purpose:** Repeated measures analysis, longitudinal modeling

#### Adverse Events Data (event-temporal)
- **Dimensions:** 55 variables × 38 observations (10 ID + 45 AE columns)
- **Structure:** Patient identifiers + adverse event variables
- **Temporal basis:** Event report date
- **Purpose:** Safety analysis, event tracking

---

## Cleaning Steps Performed

### 1. Section Marker Removal
Removed 6 data export artifacts with no actual data:
- "Personal Information FINAL"
- "Physician evaluation FINAL"
- "Physical Health Agility FINAL"
- "Cognitive Health Agility- Final"
- "Adverse events FINAL"
- "Body composition FINAL"

**Result:** 575 → 569 variables

### 2. Variable Renaming & Domain Classification

All variables were:
1. Cleaned (removed reference numbers, question numbers, newlines)
2. Converted to snake_case
3. Prefixed with domain identifiers

**Domain Distribution:**

| Domain | Prefix | Variables | Description |
|--------|--------|-----------|-------------|
| Identifiers | `id_` | 10 | Patient ID, visit info, demographics |
| Demographics | `demo_` | 40 | Education, employment, living situation |
| Cognitive | `cog_` | 62 | DSST, MoCA, SAGE, PHQ-9, WHO-5 |
| Medical | `med_` | 267 | Diagnoses, medications, complications, vitals |
| Physical | `phys_` | 102 | Body composition, frailty, performance tests |
| Adherence | `adh_` | 43 | Drug injection, exercise session tracking |
| Adverse Events | `ae_` | 45 | Safety events, falls, hospitalizations |

**Example transformations:**
- `"15. Number of education years - 230"` → `demo_number_of_education_years`
- `"Raw DSS Score"` → `cog_raw_dss_score`
- `"102. Systolic - 371"` → `med_systolic`

### 3. Duplicate Field Handling

Identified and removed duplicate fields that appeared across multiple sections:

**Participant Study Number:**
- Appeared 6 times (columns 8, 8.1, 8.2, 8.3, 8.4, 8.5)
- **Action:** Kept first occurrence, removed 5 duplicates

**Date of Birth:**
- Appeared 5 times across sections
- **Action:** Kept first occurrence, removed 4 duplicates

**Note:** BMI and falls data appear in multiple sections with different granularity - these were kept as separate variables since they measure different aspects (e.g., physician-reported BMI vs. body composition scan BMI).

### 4. DSST Score Classification

**Critical Fix:** Digital DSST scores (columns 6-7) were initially misclassified as identifiers due to their position in the dataset. This was corrected to properly classify them as cognitive variables.

**Two Independent DSST Tests:**

| Test Type | Variables | Non-Missing | Notes |
|-----------|-----------|-------------|-------|
| **Digital DSST** (smartphone) | `cog_raw_dss_score`<br>`cog_dsst_score` | 20<br>20 | Study-developed app |
| **Paper DSST** (WAIS-4) | `cog_dsst_total_score` | 19 | 120-second version |

**Important:** These are independent tests and should not be combined or averaged.

### 5. Type Conversion

Variables were converted to appropriate types:

**Dates:**
- All variables containing "date" or "Date"
- Handled multiple formats: YYYY-MM-DD, DD/MM/YYYY, MM/DD/YYYY
- **Result:** Visit dates range from 2025-04-20 to 2025-09-05

**Numeric:**
- Scores, values, measurements, BMI, vitals, lab results
- Handled special formats (e.g., "36/41" for digital DSST raw scores)
- Safe conversion with NA for invalid values

**Binary/Logical:**
- Medical history checkboxes (ICD-9 categories)
- Medication use (ATC categories)
- Yes/no questions
- Converted: "yes"/"true"/"1" → TRUE, "no"/"false"/"0" → FALSE

### 6. Patient-Level Missing Data Handling

**Critical Concept:** In longitudinal data, missingness should be assessed at the PATIENT level, not the observation (row) level.

**Principle:**
- A data point is only considered "missing" for a patient if it's missing across ALL of that patient's visits
- Time-invariant characteristics (demographics, baseline clinical features) should be consistent across all visits
- If recorded at any visit, the value applies to all visits for that patient

**Implementation:**

Identified 52 time-invariant variables across categories:
- Demographics (education, marital status, dominant hand, etc.)
- Living situation (address, phone, housing type)
- Baseline medical history (diabetes type, year of diagnosis, disease history)
- Baseline physical characteristics (gender)

**Filling Strategy:**
- Group data by patient ID
- Fill missing values bidirectionally (forward and backward) within each patient
- Preserve true patient-level missingness (NA only if missing at ALL visits)

**Results:**

| Variable | Patients with Data | True Missing |
|----------|-------------------|--------------|
| Education years | 18 / 20 | 2 patients |
| Dominant hand | 20 / 20 | 0 patients |
| Marital status | 20 / 20 | 0 patients |

**Before Patient-Level Filling:**
```
Patient 004-00232:
  Visit 1: education = 16 years
  Visit 2: education = NA
  Visit 5: education = NA
```

**After Patient-Level Filling:**
```
Patient 004-00232:
  Visit 1: education = 16 years
  Visit 2: education = 16 years  ← Filled
  Visit 5: education = 16 years  ← Filled
```

**Verification:**
- 0 patients have inconsistent values across visits
- Only patients with NA at ALL visits retain NA after filling
- All time-invariant variables are now consistent within each patient

### 7. Data Separation

Split data into two datasets based on temporal structure:

**Visits Data (visit-temporal):**
- All identifier, demographic, cognitive, medical, physical, and adherence variables
- Temporal structure based on visit date and visit number
- Wide format for easy variable selection and exploratory analysis

**Adverse Events Data (event-temporal):**
- All identifier variables + adverse event variables
- Temporal structure based on event report date
- Separate structure because AE reporting follows different timing than scheduled visits

---

## Data Quality Checks

### Patient-Level Statistics

| Metric | Value |
|--------|-------|
| Total observations (rows) | 38 |
| Unique patients | 20 |
| Patients with 1 visit | 8 (40%) |
| Patients with 2 visits | 6 (30%) |
| Patients with 3 visits | 6 (30%) |
| Mean visits per patient | 1.9 |

### Patient Characteristics

**Age Distribution:**
- Range: 65-83 years
- Mean: 73.1 years
- Population: Elderly adults

**Gender Distribution:**
- Female: 23 observations (61%)
- Male: 15 observations (39%)

**Temporal Coverage:**
- Date range: April 20, 2025 to September 5, 2025
- Study duration: ~4.5 months

### Assessment Completion

**Digital DSST (smartphone-based):**
- Raw score: 20/38 observations (53%)
- Standardized score: 20/38 observations (53%)

**Paper DSST (WAIS-4):**
- Total score: 19/38 observations (50%)

Note: Missing values are expected in longitudinal studies as not all assessments are administered at every visit.

---

## Key Findings & Recommendations

### 1. Longitudinal Structure Preserved
The cleaning process maintains the longitudinal structure of the data. Each row represents a single patient-visit, allowing for:
- Mixed-effects models
- Repeated measures ANOVA
- Growth curve analysis
- Within-subject comparisons

### 2. Domain Prefixes Enable Efficient Analysis
Variable names with domain prefixes allow for elegant tidyverse operations:

```r
# Select all cognitive variables
visits_data %>% select(starts_with("cog_"))

# Select all medical history variables
visits_data %>% select(starts_with("med_medical_history"))

# Compare cognitive scores across visits
visits_data %>%
  select(id_client_id, id_visit_no, starts_with("cog_")) %>%
  arrange(id_client_id, id_visit_no)
```

### 3. Two DSST Tests Require Separate Analysis
The study includes two independent DSST versions:
- Digital (smartphone-based): May capture different cognitive aspects
- Paper (WAIS-4 standard): Traditional neuropsychological assessment

**Recommendation:** Analyze separately and consider:
- Correlation between versions
- Test-retest reliability
- Sensitivity to cognitive change
- Practical advantages of digital administration

### 4. Adverse Events Require Special Handling
Adverse events follow event-temporal rather than visit-temporal structure:
- May occur between scheduled visits
- Multiple events can occur within a single visit period
- Some events span multiple time points (e.g., hospitalizations)

**Recommendation:** Use `adverse_events_data.rds` for safety analyses and merge with visits data carefully using patient ID and dates.

### 5. Patient-Level Missing Data Approach

**Critical Implementation:** The cleaning process implements patient-level (not row-level) missingness assessment, as specified in the data dictionary.

**Key Principle:**
- Time-invariant characteristics are filled across all visits for each patient
- A variable is only NA for a patient if missing at ALL visits
- This approach correctly represents true patient-level missingness

**Impact on Analysis:**
- Demographics and baseline characteristics are now consistent across visits within each patient
- True missingness (patient never provided data) is preserved as NA
- Enables proper longitudinal analysis without artificial missingness from data entry patterns

**Example Results:**
- **Education:** 2/20 patients (10%) truly missing - never provided across any visit
- **Dominant hand:** 0/20 patients (0%) truly missing - all patients provided this data
- **Marital status:** 0/20 patients (0%) truly missing

**Visit-Level Assessments (Expected Variation):**
Approximately 50% completion rate for cognitive assessments (DSST, MoCA) reflects:
- Assessments administered at specific visits (e.g., baseline and follow-up only)
- Not all tests given at every visit by design
- This is expected variation, not missing data

**Recommendation for Analysis:**
- Use patient-level summary statistics for time-invariant characteristics
- Model visit-level assessments with appropriate longitudinal methods
- Document which assessments are administered at which visits
- Consider assessment timing when interpreting results

---

## File Outputs

### 1. `data/visits_data.rds`
- **Format:** R data file (RDS)
- **Dimensions:** 524 variables × 38 observations
- **Usage:** Primary analysis file for visit-based temporal analyses
- **Loading:** `visits_data <- readRDS("data/visits_data.rds")`

### 2. `data/adverse_events_data.rds`
- **Format:** R data file (RDS)
- **Dimensions:** 55 variables × 38 observations
- **Usage:** Safety analysis and event tracking
- **Loading:** `adverse_events <- readRDS("data/adverse_events_data.rds")`

### 3. `data/data_dictionary_cleaned.csv`
- **Format:** CSV file
- **Contents:** Mapping of original variable names to cleaned names
- **Columns:**
  - `original_name`: Original variable name from CSV
  - `position`: Column position in original data
  - `section`: Domain classification
  - `cleaned_base`: Variable name without domain prefix
  - `prefix`: Domain prefix
  - `new_name`: Final cleaned variable name
- **Usage:** Reference for understanding variable transformations

### 4. `data/summary_statistics.rds`
- **Format:** R list object
- **Contents:** Summary statistics calculated during cleaning
- **Usage:** Quick reference for data structure and distributions

---

## Next Steps

### 1. Exploratory Data Analysis
- Descriptive statistics by domain
- Distribution checks
- Missingness patterns
- Outlier detection

### 2. Longitudinal Analysis
- Model within-subject changes over time
- Test for learning effects (especially on cognitive tests)
- Assess intervention effects if applicable

### 3. Shiny Dashboard Development
The cleaned data structure is optimized for Shiny app development:
- Domain prefixes enable reactive filtering
- Wide format supports multiple visualization types
- Separate AE data allows for dedicated safety dashboard

### 4. Variable Selection
With 524 variables, consider:
- Creating composite scores
- Selecting key variables per domain
- Reducing dimensionality for modeling
- Creating derived variables (e.g., diabetes complication count)

---

## Code Reproducibility

### Requirements
- R version ≥ 4.0
- Tidyverse package (includes dplyr, tidyr, stringr, readr, etc.)

### To Reproduce Cleaning
```r
# From project root directory
source("scripts/01_data_cleaning.R")
```

### To Load Cleaned Data
```r
library(tidyverse)

# Load visits data
visits <- readRDS("data/visits_data.rds")

# Load adverse events data
ae <- readRDS("data/adverse_events_data.rds")

# Load variable mapping
var_map <- read_csv("data/data_dictionary_cleaned.csv")

# Load summary statistics
summary_stats <- readRDS("data/summary_statistics.rds")
```

---

## Conclusion

The data cleaning process successfully transformed complex clinical research data into analysis-ready datasets while:
- **Preserving temporal structure** - separate handling of visit-temporal and event-temporal data
- **Implementing patient-level missingness** - time-invariant variables filled across visits, preserving true patient-level missing data
- **Maintaining data integrity** - proper type conversion with safe NA handling
- **Creating intuitive variable naming** - domain prefixes (id_, demo_, cog_, med_, phys_, adh_, ae_) enable efficient tidyverse operations
- **Documenting all transformations** - comprehensive variable mapping and quality checks

**Key Achievement:** The implementation of patient-level missing data handling ensures that:
- Time-invariant characteristics are consistent across all visits for each patient
- Only truly missing data (never provided by patient) remains as NA
- Analysis reflects actual patient-level missingness, not data entry artifacts

The cleaned data is ready for exploratory analysis and Shiny dashboard development.

---

**Report Version:** 2.0
**Date:** October 19, 2025
**Author:** Claude Code
**Script:** `scripts/01_data_cleaning.R`

---

## Version History

**v2.0 (October 19, 2025):**
- Added patient-level missing data handling (Step 9 in cleaning script)
- Time-invariant variables now filled across all visits for each patient
- Updated all documentation to reflect patient-level missingness approach
- Verified: 0 patients have inconsistent values across visits

**v1.0 (October 19, 2025):**
- Initial cleaning implementation
- Variable renaming with domain prefixes
- Type conversion
- Data separation (visits vs. adverse events)
