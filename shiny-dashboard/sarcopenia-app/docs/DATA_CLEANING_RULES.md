# Sarcopenia Data Cleaning Rules

**Version**: 2.0
**Last Updated**: 2025-10-22
**Audience**: Research staff, data analysts, clinical investigators

---

## Purpose

This document explains the business rules for cleaning sarcopenia study data. It describes **what** the cleaning process does and **why**, without deep technical implementation details.

---

## Overview

The data cleaning process transforms raw audit report CSVs into analysis-ready datasets. The key challenge is properly handling **missing data** in longitudinal studies where each patient has 0-3 visits.

### Key Principle

**We must distinguish between:**
- **Test not performed at this visit** (patient didn't take MoCA at visit 2, but took it at visit 1)
- **Data truly missing** (patient never provided education information across any visit)

This distinction is critical for accurate statistical analysis.

---

## Data Structure

### Input
- **Format**: CSV audit reports from study database
- **Structure**: Long format (one row per patient visit)
- **Size**: ~575 variables × ~40 rows
- **Patients**: Each patient has 0-3 visits over the study period

### Output
Two cleaned datasets:
1. **Visits Data**: Patient visits with clinical assessments and demographics
2. **Adverse Events Data**: Falls, hospitalizations, and adverse events

---

## Variable Categories

Variables are classified into three categories based on their temporal nature:

### 1. Time-Invariant Variables (n=108)

**Definition**: Variables that don't change across a patient's visits

**Examples**:
- **Demographics**: Study number, date of birth, education years, profession, dominant hand
- **Baseline Medical**: Diabetes type, year of diagnosis, medical history codes
- **Identifiers**: Patient ID, gender, name

**Cleaning Rule**:
- If a patient has this value in **any** visit → Fill it to **all** visits
- If missing from **all** visits → Mark as truly missing (NA)

**Example - Education Years**:
```
Patient 004-00232:
Raw Data:
  Visit 1: 16 years
  Visit 2: (empty)
  Visit 5: (empty)

After Cleaning:
  Visit 1: 16 years
  Visit 2: 16 years  ← Filled from visit 1
  Visit 5: 16 years  ← Filled from visit 1

Rationale: Education doesn't change between visits
```

**Example - Study Number (Missing)**:
```
Patient 004-00245:
Raw Data:
  Visit 1: (empty)
  Visit 2: (empty)

After Cleaning:
  Visit 1: NA  ← Truly missing
  Visit 2: NA  ← Truly missing

Rationale: Never provided across any visit
```

---

### 2. Time-Varying Variables (n=416)

**Definition**: Variables that can change between visits

**Examples**:
- **Cognitive Tests**: MoCA score, DSST score, PHQ-9 depression score
- **Physical Tests**: Gait speed, grip strength, chair stand time, SPPB score
- **Functional Assessments**: ADL, IADL, frailty scales
- **Medical Measurements**: BMI, blood pressure, pulse
- **Questionnaires**: Mood, physical activity, fatigue levels

**Cleaning Rule**:
- **Preserve test-specific patterns**: Empty at one visit doesn't mean missing
- **Only mark as truly missing (NA)** if empty across **all** patient visits
- **Create two versions** for analysis:
  - **Original column** (text): Preserves the distinction between "not performed" and "missing"
  - **Analysis column** (numeric/factor): Converts both empty and NA to NA for statistical tests

**Example - MoCA Score (Not Performed)**:
```
Patient 004-00232:
Raw Data:
  Visit 1: 29 (performed, scored 29/30)
  Visit 2: (empty - test not given this visit)
  Visit 5: (empty - test not given this visit)

After Cleaning:
  cog_moca_total_score (original):
    Visit 1: "29"
    Visit 2: ""         ← Keep empty (not performed, but has data elsewhere)
    Visit 5: ""         ← Keep empty (not performed, but has data elsewhere)

  cog_moca_total_score_numeric (for analysis):
    Visit 1: 29
    Visit 2: NA         ← Statistical analysis treats as missing
    Visit 5: NA         ← Statistical analysis treats as missing

Rationale: Patient DID take MoCA (visit 1 = 29). Visits 2 & 5 were empty
           because test wasn't administered, not because data is missing.
           For analysis, we need numeric version that treats both as NA.
```

**Example - Grip Strength (Truly Missing)**:
```
Patient 004-00250:
Raw Data:
  Visit 1: (empty)
  Visit 2: (empty)
  Visit 3: (empty)

After Cleaning:
  phys_right_hand_average (original):
    Visit 1: NA  ← Truly missing
    Visit 2: NA  ← Truly missing
    Visit 3: NA  ← Truly missing

  phys_right_hand_average_numeric (for analysis):
    Visit 1: NA
    Visit 2: NA
    Visit 3: NA

Rationale: Patient never had grip strength measured across any visit.
           This is TRUE missingness, not "test not performed."
```

---

### 3. Adverse Events (n=45)

**Definition**: Event tracking variables (falls, fractures, hospitalizations)

**Examples**:
- Falls
- Fractures
- ER admissions
- Hospitalizations
- Serious adverse events

**Cleaning Rule**:
- **Never convert to NA**
- **Leave empty as empty**
- These are event logs, not measurements

**Example**:
```
Patient 004-00232:
Raw Data:
  Visit 1: (no fall reported)
  Visit 2: "Yes - fell on 2024-03-15"
  Visit 5: (no fall reported)

After Cleaning:
  ae_did_you_fall:
    Visit 1: ""    ← Empty means no event, not missing data
    Visit 2: "Yes - fell on 2024-03-15"
    Visit 5: ""    ← Empty means no event, not missing data

Rationale: Empty adverse event = no event occurred. This is valid data,
           not missingness. Do not convert to NA.
```

---

## Special Case: Measurement Units

**Variables**: Any column ending in `_unit` (e.g., `height_m_unit`, `weight_kg_unit`)

**Category**: Treated as time-invariant

**Cleaning Rule**:
- Units don't change across visits
- Fill forward within each patient
- If missing from all visits → Mark as NA

**Example**:
```
Patient 004-00232:
Raw Data:
  Visit 1: grip_strength = 25.3, unit = "kg"
  Visit 2: grip_strength = 24.8, unit = (empty)
  Visit 5: grip_strength = (empty), unit = (empty)

After Cleaning:
  Visit 1: grip_strength = 25.3, unit = "kg"
  Visit 2: grip_strength = 24.8, unit = "kg"  ← Filled from visit 1
  Visit 5: grip_strength = (empty), unit = "kg"  ← Filled from visit 1

Rationale: The unit of measurement doesn't change between visits.
```

---

## Cleaning Process Steps

The data is cleaned in this specific order:

### Step 1: Load Raw Data
- Read CSV file with all columns as text
- Preserve empty cells as empty strings (not NA yet)

### Step 2: Apply Variable Name Mapping
- Use data dictionary to rename columns
- Example: "15. Number of education years - 230" → "demo_number_of_education_years"

### Step 3: Split Visits and Adverse Events
- Separate adverse event columns (ae_*) into their own dataset
- Keep all other variables in visits dataset

### Step 4: Convert Patient-Level Missing Data ⭐
**This is the critical step!**

For each variable (except adverse events):
  - For each patient:
    - Check if empty across **all** patient's visits
    - If yes → Convert all empty to NA (truly missing)
    - If no → Keep empty as empty string (test not performed)

### Step 5: Fill Time-Invariant Variables
For variables like demographics and baseline medical:
  - For each patient:
    - Find first non-empty value across visits
    - Fill that value to all other visits for that patient
    - If all visits are NA (from step 4) → Leave as NA

### Step 6: Create Analysis Columns
For time-varying variables:
  - Create duplicate column with `_numeric`, `_factor`, or `_date` suffix
  - Convert to appropriate data type for statistical analysis
  - Both empty string and NA become NA in analysis column
  - Keep original column as text to preserve distinction

### Step 7: Final Type Conversion
- Convert remaining columns to appropriate types
- Dates → Date format
- Numeric scores → Numeric
- Categorical → Keep as text (or convert to factor later)

### Step 8: Generate Summary Reports
- Count rows, columns
- Unique patients
- Missing data patterns
- Data quality metrics

---

## Assessment Instruments

The dataset includes standardized clinical assessment instruments. Understanding these helps explain the time-varying nature:

### Cognitive Assessments

**MoCA (Montreal Cognitive Assessment)**
- **Range**: 0-30 points
- **Interpretation**: ≥26 = normal, <26 = cognitive impairment
- **Time-Varying**: Yes - cognitive function can change between visits
- **Missing Rule**: If empty in some visits but present in others, keep empty (test not administered)

**DSST (Digit Symbol Substitution Test)**
- **Range**: Number of correct symbols in 90-120 seconds
- **Purpose**: Measures processing speed and attention
- **Time-Varying**: Yes - performance can vary between visits

**PHQ-9 (Patient Health Questionnaire)**
- **Range**: 0-27 points
- **Interpretation**: Depression severity (0-4 minimal, 5-9 mild, 10-14 moderate, 15-19 moderately severe, 20-27 severe)
- **Time-Varying**: Yes - mood changes between visits

### Physical Assessments

**SPPB (Short Physical Performance Battery)**
- **Range**: 0-12 points
- **Components**: Balance test, gait speed, chair stand
- **Interpretation**: <10 indicates mobility limitations
- **Time-Varying**: Yes - physical function changes with interventions

**Gait Speed**
- **Measurement**: Meters per second (m/s) or time to walk distance
- **Cutoff**: ≤0.8 m/s indicates low physical performance
- **Time-Varying**: Yes - walking speed can improve or decline

**Chair Stand Test**
- **Measurement**: Time (seconds) to complete 5 sit-to-stands
- **Interpretation**: >15 sec = increased fall risk
- **Time-Varying**: Yes - leg strength changes with training

**Grip Strength**
- **Measurement**: Kilograms (kg) using hand dynamometer
- **Sarcopenia Cutoffs**: Men <27 kg, Women <16 kg
- **Time-Varying**: Yes - muscle strength responds to interventions

### Functional Assessments

**ADL (Activities of Daily Living)**
- **Range**: 0-6 points
- **Measures**: Basic self-care (bathing, dressing, toileting, transferring, eating, continence)
- **Time-Varying**: Yes - functional status can change

**IADL (Instrumental Activities of Daily Living)**
- **Range**: 0-8 points
- **Measures**: Complex activities (shopping, finances, medication management, housekeeping)
- **Time-Varying**: Yes - independence level varies

---

## Why This Matters for Analysis

### Problem with Simple Approach
If we convert ALL empty cells to NA:
- Lose distinction between "test not performed" and "data missing"
- Can't tell if patient declined test vs. data was lost
- Inflates missingness statistics

### Solution with Dual Columns

**For Researchers**:
- Use **original column** to see actual data patterns
- Identify which visits had assessments
- Understand testing patterns

**For Statistical Analysis**:
- Use **_numeric/_factor columns** in regression models
- Both "not performed" and "truly missing" → NA for analysis
- Get correct sample sizes and power calculations

### Example Use Case

**Research Question**: Does cognitive function (MoCA) decline over time?

**Using Original Column**:
```r
# See which patients actually had MoCA administered
patients_with_moca <- visits %>%
  filter(cog_moca_total_score != "" & !is.na(cog_moca_total_score))
# Shows: 15 patients tested at visit 1, 8 at visit 2, 5 at visit 3
```

**Using Numeric Column for Analysis**:
```r
# Linear mixed model treats both "" and NA as missing
lmer(cog_moca_total_score_numeric ~ visit_no + (1|patient_id))
# Correctly uses only patients with actual scores
```

---

## Data Quality Checks

After cleaning, the following quality checks are performed:

### 1. Completeness by Variable Category
- **Time-Invariant**: Should have high completeness (>90%) after filling
- **Time-Varying**: Expected to vary by visit and assessment schedule
- **Adverse Events**: Completeness not applicable (empty = no event)

### 2. Missingness by Patient
- Identify patients with <50% completeness
- Flag for data collection review
- May indicate dropout or incomplete enrollment

### 3. Instrument Completeness
- For each assessment battery (MoCA, SPPB, etc.)
- Calculate % patients with complete data
- Identify systematic gaps in data collection

### 4. Out-of-Range Values
- MoCA scores outside 0-30
- PHQ-9 scores outside 0-27
- SPPB scores outside 0-12
- Flag for data entry errors

---

## Common Questions

### Q: Why keep empty strings instead of converting everything to NA?
**A**: Because empty string at visit 2 when patient has data at visit 1 means "test not performed this visit", not "data missing". This distinction is important for understanding testing patterns and sample sizes.

### Q: Why create duplicate columns (_numeric, _factor)?
**A**: Researchers need to see actual data patterns (original column), but statistical software needs clean numeric data (analysis column). Both serve different purposes.

### Q: What if a patient has education = 16 at visit 1 but education = 18 at visit 2?
**A**: This would indicate a data entry error, as education years shouldn't increase. The first non-empty value (16) is used to fill all visits. Data quality reports flag such inconsistencies.

### Q: How are measurement units handled?
**A**: Units are treated as time-invariant and filled forward. If patient has weight measured in "kg" at visit 1, all visits get "kg" even if empty.

### Q: What happens to adverse events that are empty?
**A**: They stay empty. Empty adverse event means "no event occurred", which is valid data, not missingness.

---

## Example: Complete Patient Cleaning

**Patient 004-00232** (3 visits)

### Time-Invariant Variables
| Variable | Visit 1 | Visit 2 | Visit 5 | After Cleaning |
|----------|---------|---------|---------|----------------|
| Education years | 16 | (empty) | (empty) | 16, 16, 16 |
| Gender | Male | (empty) | (empty) | Male, Male, Male |
| Study number | 004-00232 | 004-00232 | 004-00232 | 004-00232, 004-00232, 004-00232 |

### Time-Varying Variables
| Variable | Visit 1 | Visit 2 | Visit 5 | Original Column | _numeric Column |
|----------|---------|---------|---------|-----------------|-----------------|
| MoCA score | 29 | (empty) | (empty) | "29", "", "" | 29, NA, NA |
| Grip strength | 25.3 | 24.8 | (empty) | "25.3", "24.8", "" | 25.3, 24.8, NA |
| PHQ-9 | 5 | (empty) | 8 | "5", "", "8" | 5, NA, 8 |

### Adverse Events
| Variable | Visit 1 | Visit 2 | Visit 5 | After Cleaning |
|----------|---------|---------|---------|----------------|
| Falls | (empty) | Yes | (empty) | "", "Yes", "" |
| Hospitalizations | (empty) | (empty) | (empty) | "", "", "" |

---

## Version History

### Version 2.0 (2025-10-22)
- Implemented patient-level NA conversion logic
- Added dual column approach for time-varying variables
- Enhanced documentation with assessment instruments
- Added data quality checks

### Version 1.0 (Previous)
- Basic cleaning pipeline
- Had issues with properly distinguishing "" from NA
- Did not create analysis columns

---

## References

For technical implementation details, see:
- **DEVELOPER_SPEC.md**: Complete technical specification
- **data_dictionary_enhanced.csv**: Variable metadata and categorization
- **enhance_data_dictionary.R**: Script to update dictionary metadata

For assessment instrument details, see published literature on:
- MoCA: Nasreddine et al. (2005)
- SPPB: Guralnik et al. (1994)
- PHQ-9: Kroenke et al. (2001)
- EWGSOP2: European sarcopenia criteria
