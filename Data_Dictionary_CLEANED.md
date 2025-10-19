# Sarcopenia Study - Data Dictionary (Cleaned)
## Audit Report Dataset - Longitudinal Diabetes Study

**Version:** 2.2
**Last Updated:** October 18, 2025
**Dataset:** Audit report.csv

---

## Dataset Overview

| Metric | Value |
|--------|-------|
| Total Variables | 575 |
| Total Observations (Rows) | 38 |
| Unique Patients | 20 |
| Maximum Visits per Patient | 3 |
| Average Visits per Patient | 1.9 |
| Study Design | Longitudinal (repeated measures) |
| Analysis Level | Patient-level (not row-level) |

---

## Important Notes

### Longitudinal Data Structure
This is a **longitudinal dataset** with multiple visits per patient. Each row represents a single visit, and patients may have 1-3 visits recorded.

### Test Scoring
Most cognitive and physical tests include:
1. Individual item scores
2. Total/raw scores
3. Standardized/percentile scores (when available)

### Section Markers (Data Export Artifacts)
The CSV contains several columns that serve as section markers from the data collection platform. These columns should be **excluded from analysis**:
- "Personal Information FINAL"
- "Physician evaluation FINAL"
- "Physical Health Agility FINAL"
- "Cognitive Health Agility- Final"
- "Adverse events FINAL"
- "Body composition FINAL"

These are structural artifacts from the data export and contain no actual data.

---

## Table of Contents

### 1. Core Identifiers & Visit Information (12 variables)
- Patient Identification
- Visit Tracking
- Basic Demographics

### 2. Personal & Demographic Information (30 variables)
- Demographics
- Living Situation & Contact
- Education & Employment History

### 3. Study Administration (58 variables)
- Study Participation Details
- Drug Adherence Tracking
- Exercise Intervention Adherence

### 4. Cognitive Assessments (85 variables)
- Verbal Fluency Test
- Digit Symbol Substitution Test (DSST)
- Montreal Cognitive Assessment (MoCA)
- Standardized Assessment of Global Activities in the Elderly (SAGE)
- Patient Health Questionnaire (PHQ-9)
- WHO-5 Well-Being Index

### 5. Medical Information (233 variables)
- Healthcare Provider
- Hospitalizations
- Medical History (ICD-9 Codes)
- Medications (ATC Codes)
- Diabetes Management
- Hypoglycemia History
- Lipid Profile
- Smoking History
- Diabetic Complications
- Liver Function Tests
- Vital Signs

### 6. Adverse Events (79 variables)
- Serious Adverse Events
- Falls & Fractures
- Hospitalizations & ER Visits
- Gastrointestinal Events
- Endocrine/Metabolic Events
- Cardiovascular Events
- Neurological Events
- Dermatological Events
- Musculoskeletal Injuries

### 7. Physical Health & Function (94 variables)
- Anthropometric Measurements
- Body Composition
- Exercise & Physical Activity
- Frailty Assessment
- Falls History
- SARC-F Sarcopenia Screening
- Physical Performance Tests (Grip Strength, Chair Stand, Gait Speed, TUG, Balance, SPPB)

---

## 1. Core Identifiers & Visit Information

### Patient Identification
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| Org ID | Organization identifier | Categorical | 0% |
| Client ID | Unique patient identifier | Text | 0% |
| Client Name | Patient code/name | Text | 0% |

### Visit Tracking
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| Visit Date | Date of visit | Date | 0% |
| Visit Type | Type of visit (e.g., scheduled) | Categorical | 0% |
| Visit No | Visit number (1, 2, 3, etc.) | Numeric | 0% |
| Visit Tag | Visit label | Text | 0% |
| Submission Tag | Data submission tag | Text | 10% |

### Basic Demographics
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| Gender | Patient gender | Categorical (Male/Female) | 0% |
| Age | Patient age at visit | Numeric (years) | 0% |

---

## 2. Personal & Demographic Information

### Demographics
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 1. Participants study number - 8* | Study participant number (multiple columns) | Text | 0% |
| 3. Which study is the participant part of? - 780 in elderly | Part of 780 elderly study | Binary | 0% |
| 3. Which study is the participant part of? - BIRAX | Part of BIRAX study | Binary | 0% |
| 3. Which study is the participant part of? - Regeneron | Part of Regeneron study | Binary | 0% |
| 23. Study group - 378 | Study group assignment | Categorical | Variable |

*Note: Multiple "Participants study number" columns exist (8, 8.1, 8.2, 8.3, 8.4, 8.5) representing the field across different sections

### Study Administration
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 4. Location of visit - 220 | Visit location | Categorical | 0% |
| 5. Visit number - 221 | Visit number | Numeric | 0% |
| 6. Consent form signed - 222 | Consent status | Binary | 0% |

### Living Situation & Contact
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 7. Health maintenance organization - 223 | HMO provider | Categorical | 0% |
| 8. Address - 224 | Patient address | Text | 5% |
| 9. Phone type - Phone type | Phone type (smartphone/other) | Binary | 5% |
| 9. Phone type - Phone model | Phone model | Text | 50% |
| 10. Phone number - undefined | Phone number | Text | 0% |
| 11. Marital status - 226 | Marital status | Categorical | 0% |
| 12. Lives with - 227 | Living arrangement | Categorical | 0% |
| 13. Living facilities - Private house | Lives in private house | Binary | 0% |
| 13. Living facilities - Apartment | Lives in apartment | Binary | 0% |
| 13. Living facilities - Stairs | Has stairs | Binary | 0% |
| 13. Living facilities - Elevator | Has elevator | Binary | 0% |
| 14. Do you drive - 229 | Drives | Binary | 0% |

### Education & Employment
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 15. Number of education years - 230 | Years of education | Numeric | 10% |
| 16. Educational Degree - 231 | Educational level | Categorical | 0% |
| 17. Profession - 232 | Professional category | Categorical | 5% |
| 18. Do you work? - 233 | Currently working | Categorical | 0% |
| 19. Did you work in the past? - 234 | Worked in past | Binary | 0% |
| 20. What year did you stop working? - 235 | Year stopped working | Numeric (year) | 35% |
| 21. Why did you stop working? - 236 | Reason for stopping work | Categorical | 15% |
| 22. Dominant hand - 237 | Dominant hand | Binary (0=right, 1=left) | 0% |

---

## 3. Cognitive Assessments

### Overview of Cognitive Tests
The following validated assessment tools were administered:

| Test | Full Name | Measures |
|------|-----------|----------|
| **Verbal Fluency** | Phonemic and Semantic Fluency Tests | Language and executive function |
| **DSST (Digital)** | Digit Symbol Substitution Test - Digital Version | Processing speed (smartphone-based) |
| **DSST (Paper)** | Digit Symbol Substitution Test - WAIS-4 | Processing speed (120-second version) |
| **MoCA** | Montreal Cognitive Assessment | Global cognitive function |
| **SAGE** | Standardized Assessment of Global Activities in the Elderly | ADL and IADL function |
| **PHQ-9** | Patient Health Questionnaire-9 | Depression screening |
| **WHO-5** | World Health Organization Well-Being Index | Well-being |

---

### Digit Symbol Substitution Test (DSST)

**Purpose:** Measures processing speed and working memory

This study administered **TWO different versions** of the DSST:

#### 1. Digital DSST (Smartphone-Based)
- **Platform:** Smartphone application developed by study team
- **Columns:** 6-7 (top-level in CSV)

| Variable Name | Location in CSV | Description | Data Type |
|--------------|----------------|-------------|-----------|
| **Raw DSS Score** | Column 6 (top-level) | Raw score from digital DSST | Text |
| **DSST Score** | Column 7 (top-level) | Standardized score from digital DSST | Numeric |

#### 2. Pen and Paper DSST (WAIS-4)
- **Test:** WAIS-4 Digit Symbol Substitution Test
- **Duration:** 120 seconds
- **Columns:** Cognitive section (179-180)

| Variable Name | Location in CSV | Description | Data Type |
|--------------|----------------|-------------|-----------|
| **43. DSST - Total Score - 179** | Cognitive section | Raw score from pen and paper DSST (WAIS-4, 120 sec) | Numeric |
| **44. Standardized Score - 180** | Cognitive section | Standardized score from pen and paper DSST | Numeric |

#### Important Notes:
1. **Two Independent Tests:** Digital and pen-and-paper versions are separate assessments and should not be combined
2. **Raw Score Format:** Digital DSST raw score may appear as "correct/attempted" format (e.g., "36/41")
3. **Standardized Scores:** Both versions include standardized scores for age/education adjustment
4. **Test Selection:** For analysis, choose the appropriate version based on your research question:
   - Digital DSST: May capture different aspects of processing speed (smartphone-based assessment)
   - Pen and Paper DSST: Standard WAIS-4 administration, 120-second version

---

### Montreal Cognitive Assessment (MoCA)

**Purpose:** Brief cognitive screening for mild cognitive impairment
**Score Range:** 0-30 points (≥26 = normal)

#### MoCA Subscale Scores

| Variable Name | Domain | Score Range |
|--------------|---------|-------------|
| 45. Visuospatial/Executive - 181 | Visuospatial/Executive | Variable |
| 46. Cube - 182 | Cube drawing | 0-1 |
| 47. Clock - 183 | Clock drawing | 0-3 |
| 48. Naming - 184 | Object naming | 0-3 |
| 49. Memory first trial - 185 | Memory encoding (trial 1) | 0-5 |
| 50. Memory second trial - 186 | Memory encoding (trial 2) | 0-5 |
| 51. List of digits - 187 | Attention (digit span) | 0-2 |
| 52. Letters - 188 | Attention (vigilance) | 0-1 |
| 53. Subtraction - 189 | Attention (serial 7s) | 0-3 |
| 54. Language - 190 | Language (sentence repetition) | 0-2 |
| 55. Fluency - 191 | Verbal fluency | 0-1 |
| 56. Abstraction - 192 | Abstract reasoning | 0-2 |
| 57. Delayed recall - 193 | Delayed memory recall | 0-5 |
| 58. Orientation - 194 | Orientation to time/place | 0-6 |

#### MoCA Total Score

| Variable Name | Description | Score Range |
|--------------|-------------|
| **59. Moca - Total Score - 195** | Total MoCA score | 0-30 |

---

### Verbal Fluency Tests

**Purpose:** Measure language production and executive function

| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 60. VF phonemic - Total Score - 196 | Phonemic fluency total (e.g., words starting with F, A, S) | Numeric |
| 61. Standardized Score - 197 | Phonemic fluency standardized score | Numeric |
| 62. VF semantic - Total Score - 198 | Semantic fluency total (e.g., animals, foods) | Numeric |
| 63. Standardized Score - 199 | Semantic fluency standardized score | Numeric |

---

### SAGE - Standardized Assessment of Global Activities in the Elderly

**Purpose:** Assess independence in Activities of Daily Living (ADL) and Instrumental ADL (IADL)

#### Cognitive Domains
| Variable Section | Questions | Domains Assessed |
|-----------------|-----------|------------------|
| Attention/Concentration | 22 | Maintaining attention during conversation |
| Memory | 23 | Recent memory |
| Multitasking | 24 | Dual-task performance |
| Concentration Activities | 25 | Sustained attention (games, reading) |
| Spatial Navigation | 26 | Way-finding |
| Trip/Social Planning | 27 | Executive planning |
| Finances/Shopping | 28 | Financial management |
| Medication Management | 29 | Medication organization |
| Meal Prep/Laundry | 30 | Home management |

#### Functional Mobility & ADL
| Variable Section | Questions | Activities Assessed |
|-----------------|-----------|---------------------|
| Transportation | 31 | Driving, public transportation |
| Stair Use | 32-33 | Stair climbing, assistance needed |
| Walking | 34-35 | Walking ability, assistance needed |
| Dressing | 36 | Dressing independence |
| Chair Transfer | 37-38 | Getting up from chair/toilet, assistance needed |
| Bathing/Toileting | 39-40 | Bathing/toileting independence, assistance |

#### Factors Affecting ADL
| Variable Name | Description |
|--------------|-------------|
| 41. Basic activities of daily living | Multiple checkboxes for factors: Memory problems, Arthritis, Shortness of breath, Chest pain, Physical injury, Stroke/TIA, Chronic pain, Heart failure, Vision loss, Unsteadiness, Leg pain, Other, Not sure |

#### SAGE Total Score
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 42. Score - 178 | Total SAGE score | Numeric |

---

### Patient Health Questionnaire (PHQ-9)

**Purpose:** Depression screening tool
**Score Range:** 0-27 (0-4 minimal, 5-9 mild, 10-14 moderate, 15-19 moderately severe, 20-27 severe depression)

#### PHQ-9 Item Scores

| Variable Name | Item | Symptom |
|--------------|------|---------|
| 3. Little interest or pleasure - 119 | Item 1 | Anhedonia |
| 4. Feeling down, depressed, or hopeless - 120 | Item 2 | Depressed mood |
| 5. Trouble falling or staying asleep - 121 | Item 3 | Sleep problems |
| 6. Feeling tired or having little energy - 122 | Item 4 | Fatigue/energy |
| 7. Poor appetite or overeating - 123 | Item 5 | Appetite |
| 8. Feeling bad about yourself - 124 | Item 6 | Self-worth |
| 9. Trouble concentrating - 125 | Item 7 | Concentration |
| 10. Moving or speaking slowly/fidgety - 126 | Item 8 | Psychomotor |
| 11. Thoughts that you would be better off dead - 127 | Item 9 | Suicidal ideation |

#### PHQ-9 Total & Functional Impairment

| Variable Name | Description | Score Range |
|--------------|-------------|
| **12. PHQ9 - Total Score - 128** | Total depression score | 0-27 |
| 13. How difficult have these problems made it - 129 | Functional impairment | Categorical |

---

### WHO-5 Well-Being Index

**Purpose:** Measure subjective well-being
**Score Range:** 0-25 raw score (0-100 when multiplied by 4)

#### WHO-5 Item Scores

| Variable Name | Item | Content |
|--------------|------|---------|
| 14. I have felt cheerful and in good spirits - 130 | Item 1 | Positive mood |
| 15. I have felt calm and relaxed - 131 | Item 2 | Calmness |
| 16. I have felt active and vigorous - 132 | Item 3 | Energy/activity |
| 17. I woke up feeling fresh and rested - 133 | Item 4 | Rest/sleep quality |
| 18. My daily life has been filled with things that interest me - 134 | Item 5 | Interest in activities |

#### WHO-5 Total Score

| Variable Name | Description | Score Range |
|--------------|-------------|
| **19. WHO-5 - Total Score - 135** | Total well-being score | 0-25 (raw) or 0-100 (transformed) |

---

## 4. Medical Information

### Healthcare Provider
| Variable Name | Description |
|--------------|-------------|
| 3. Primary care doctor - 250 | Primary care physician |

### Hospitalizations
| Variable Name | Description |
|--------------|-------------|
| 4. Hospitalization in the past year? - 442 | Any hospitalization in past year |

---

### Medical History (ICD-9 Codes)

20 binary columns indicating medical history by disease category:

| Variable Name | Disease Category | Code Range |
|--------------|------------------|------------|
| 5. Medical history - 001-139 Infectious and Parasitic diseases | Infectious diseases | 001-139 |
| 5. Medical history - 140-239 Neoplasms | Cancers | 140-239 |
| 5. Medical history - 240-246 251-279 Endocrine, Nutritional and Metabolic diseases | Endocrine/metabolic | 240-279 |
| 5. Medical history - 280-289 Diseases of Blood | Blood diseases | 280-289 |
| 5. Medical history - 290-319 Mental disorders | Mental health | 290-319 |
| 5. Medical history - 320-389 Nervous system and Sense organs | Neurological | 320-389 |
| 5. Medical history - 390-459 Circulatory system | Cardiovascular | 390-459 |
| 5. Medical history - 460-519 Respiratory system | Respiratory | 460-519 |
| 5. Medical history - 520-579 Digestive system | Gastrointestinal | 520-579 |
| 5. Medical history - 580-629 Genitourinary system | Genitourinary | 580-629 |
| 5. Medical history - 630-679 Pregnancy, Childbirth | Pregnancy complications | 630-679 |
| 5. Medical history - 680-709 Skin and Subcutaneous Tissue | Dermatological | 680-709 |
| 5. Medical history - 710-739 Musculoskeletal system | Musculoskeletal | 710-739 |
| 5. Medical history - 740-759 Congenital anomalies | Congenital | 740-759 |
| 5. Medical history - 760-779 Perinatal Period | Perinatal | 760-779 |
| 5. Medical history - 780-799 Symptoms, Signs and Ill-defined | Symptoms/signs | 780-799 |
| 5. Medical history - 800-999 Injury and Poisoning | Injuries | 800-999 |
| 5. Medical history - E800-E999 External Causes of Injury | External causes | E800-E999 |
| 5. Medical history - V01-V82 Health status factors | Health services contact | V01-V82 |
| 5. Medical history - M8000-M9970 Morphology of Neoplasms | Neoplasm morphology | M8000-M9970 |

---

### Medications (ATC Codes)

13 binary columns indicating medication use by therapeutic category:

| Variable Name | Medication Category | ATC Code |
|--------------|---------------------|----------|
| 6. Medication - A00 Alimentary Tract and Metabolism | GI/metabolism | A00 |
| 6. Medication - B00 Blood and Blood forming organs | Hematological | B00 |
| 6. Medication - C00 Cardiovascular system | Cardiovascular | C00 |
| 6. Medication - D00 Dermatologicals | Dermatological | D00 |
| 6. Medication - G00 Genito Urinary System and Sex Hormones | GU/hormones | G00 |
| 6. Medication - H00 Systemic Hormonal Preparations | Hormonal (excl. sex/insulin) | H00 |
| 6. Medication - J00 Antiinfectives for Systemic Use | Antiinfectives | J00 |
| 6. Medication - L00 Antineoplastic and Immunomodulating Agents | Oncology/immunology | L00 |
| 6. Medication - M00 Musculo-Skeletal system | Musculoskeletal | M00 |
| 6. Medication - N00 Nervous system | Neurological | N00 |
| 6. Medication - P00 Antiparasitic Products | Antiparasitic | P00 |
| 6. Medication - R00 Respiratory system | Respiratory | R00 |
| 6. Medication - S00 Sensory Organs | Sensory | S00 |
| 6. Medication - V00 Various | Various | V00 |

---

### Diabetes Management

#### Diabetes Type & Diagnosis
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 7. Diabetes mellitus type - 255 | Type of diabetes (Type 1, Type 2, etc.) | Categorical |
| 8. Year of diagnosis - 256 | Year diagnosed with diabetes | Numeric (year) |

#### Glycemic Monitoring
| Variable Name | Description | Unit |
|--------------|-------------|------|
| 21. Use of sensor - 269 | Uses continuous glucose monitor | Binary | Variable |
| 22. Sensor type - 270 | CGM type | Categorical | Variable |
| 23. Use of glucometer - 277 | Uses blood glucose meter | Binary | Variable |
| 24. Glucometer frequency - 278 | Frequency of glucometer use | Categorical | Variable |
| 25. Number of measurements per week - 279 | Weekly BG measurements | Numeric | Variable |
| 26. Number of measurements per day - 280 | Daily BG measurements | Numeric | Variable |
| 27. Morning Glucose value - 281 | Morning glucose level | Numeric | Variable |
| 28. Blood fasting glucose values - 286 | Fasting glucose | Numeric | Variable |
| 29. HbA1c values - 287 | Hemoglobin A1c | Numeric (%) | Variable |

#### Insulin Therapy
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 30. Use of insulin - 288 | Uses any insulin | Binary |
| 31. Use of basal insulin - 289 | Uses basal insulin | Binary |
| 32. Type of basal insulin - 290 | Basal insulin type | Categorical |
| 33. No. of basal insulin units - 291 | Daily basal insulin dose | Numeric |
| 34. Use of bolus insulin - 292 | Uses bolus insulin | Binary |
| 35. Type of Bolus insulin - 293 | Bolus insulin type | Categorical |
| 36. No. of bolus insulin units - 294 | Bolus insulin dose | Numeric |
| 37. Use of Premix Insulin - 295 | Uses premix insulin | Binary |
| 38. No. of Premix Insulin units - 296 | Premix insulin dose | Numeric |
| 39. Use of pump - 297 | Uses insulin pump | Binary |
| 40. Type of pump - 298 | Insulin pump type | Categorical |
| 41. Years of using an insulin pump - 299 | Years on pump | Numeric |

#### Oral Diabetes Medications
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 42. Use of Metformin - 303 | Uses metformin | Binary |
| 43. Use of Sulphonylureas - 304 | Uses sulfonylureas | Binary |
| 44. Type of Sulphonylureas - 305 | Sulfonylurea type | Categorical |
| 45. Use of Glinides - 306 | Uses glinides | Binary |
| 46. Type of Glinides - 307 | Glinide type | Categorical |
| 47. Use of Acarbose - 308 | Uses acarbose | Binary |
| 48. Use of DPP-4 - 309 | Uses DPP-4 inhibitor | Binary |
| 49. Type of DPP-4 - 310 | DPP-4 type | Categorical |
| 50. Use of Pioglitazone - 311 | Uses pioglitazone | Binary |
| 51. Use of GLP - 312 | Uses GLP-1 agonist (current) | Binary |
| 52. Type of GLP - 313 | GLP-1 type (current) | Categorical |
| 53. Use of GLP in the past? | GLP-1 use history (4 sub-fields) | Multiple |
| 54. Use of SGLT-2 - 450 | Uses SGLT-2 inhibitor | Binary |

#### Cardiovascular Medications
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 55. ACE inhibitors - 314 | Uses ACE inhibitor | Binary |
| 56. AT-2 - 315 | Uses ARB (AT-2 blocker) | Binary |
| 57. Statins - 316 | Uses statin | Binary |
| 58. Aspirin-Plavix - 317 | Uses antiplatelet | Binary |

---

### Hypoglycemia History

| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 59. Experienced hypoglycemia requiring help - 318 | Severe hypoglycemia history | Binary |
| 60. If experienced, how many events - 319 | Number of severe hypoglycemia events | Numeric |
| 61. Hypoglycemia events <50 mg/dL in last year - 320 | Hypoglycemia events past year | Numeric |
| 62. Feels hypoglycemia - 321 | Hypoglycemia awareness | Binary |
| 63. Wakes up from hypoglycemia at night - 322 | Nocturnal hypoglycemia | Binary |
| 64. Neuroglycopenia symptoms - 323 | Neuroglycopenic symptoms | Binary/scale |
| 65. Adrenergic symptoms - 324 | Adrenergic symptoms | Binary/scale |
| 66. DKA history in the last 6 months - 326 | Recent DKA | Binary |

---

### Lipid Profile & Cardiovascular Risk

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 9. High blood pressure - 258 | Hypertension diagnosis | Binary | 0% |
| 10. Hypercholesterolemia - 259 | High cholesterol diagnosis | Binary | Variable |
| 11. Cholestrol value - 532 | Total cholesterol | mg/dL or mmol/L | Variable |
| 12. LDL last blood test values - 260 | LDL cholesterol | mg/dL or mmol/L | Variable |
| 14. HDL last blood test values - 262 | HDL cholesterol | mg/dL or mmol/L | Variable |
| 16. Triglycerides last blood test values - 264 | Triglycerides | mg/dL or mmol/L | Variable |

#### Smoking History
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 18. Smoker - 266 | Current smoker | Binary |
| 19. Smoked in the past - 267 | Former smoker | Binary |
| 20. Year of quitting smoking - 268 | Year quit smoking | Numeric (year) |

---

### Diabetic Complications

#### Macrovascular Complications
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 67. Heart attack - 328 | History of MI | Binary |
| 68. Stroke - 329 | History of stroke | Binary |
| 69. Problems with blood supply to legs - 330 | Peripheral vascular symptoms | Binary |
| 70. Underwent Cardiac catheterization - 331 | History of catheterization | Binary |
| 71. Ischemic heart disease - 332 | IHD diagnosis | Binary |
| 72. Cerebrovascular disease - 333 | CVD diagnosis | Binary |
| 75. PVD - 495 | Peripheral vascular disease | Binary |

#### Foot Complications
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 73. Foot ulcer - 334 | History of foot ulcer | Binary |
| 74. Amputation - 335 | History of amputation | Binary |

#### Retinopathy
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 76. Known Retinopathy - 336 | Diabetic retinopathy diagnosis | Binary/severity |

#### Nephropathy & Renal Function
| Variable Name | Description | Unit |
|--------------|-------------|------|
| 77. Known Nephropathy - 340 | Diabetic nephropathy | Binary |
| 78. Known Albuminuria - 341 | Albuminuria | Binary |
| 79. Microalbumin/Creatinine Ratio - 342 | ACR | mg/g or mg/mmol |
| 81. Blood creatinine - 344 | Serum creatinine | mg/dL or μmol/L |

#### Neuropathy
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 83. Known Neuropathy - 426 | Diabetic neuropathy diagnosis | Binary |
| 84. Decreased sensation in lower limbs - 346 | Sensory neuropathy | Binary |
| 85. Limb pain - 347 | Neuropathic pain | Binary |

---

### Liver Function Tests

| Test | Variable Name(s) | Unit |
|------|------------------|------|
| **AST** | 87. AST value - 349 | U/L or IU/L |
| **ALT** | 89. ALT value - 351 | U/L or IU/L |
| **GGT** | 91. GGT value - 353 | U/L or IU/L |
| **Bilirubin** | 93. Bilirubin value - 355 | mg/dL or μmol/L |
| **Alkaline Phosphatase** | 95. Alkaline Phosphatase value - 357 | U/L or IU/L |
| **Albumin** | 97. Albumin value - 359 | g/dL or g/L |
| **LDH** | 99. LDH value - 361 | U/L or IU/L |

Each test includes value, unit, and date fields.

---

### Vital Signs & Anthropometrics

#### Blood Pressure & Heart Rate
| Variable Name | Description | Unit |
|--------------|-------------|------|
| 102. Systolic - 371 | Systolic BP | mmHg | Variable |
| 103. Diastolic - 370 | Diastolic BP | mmHg | Variable |
| 104. Pulse - 369 | Heart rate | bpm | Variable |

#### Body Mass Index
| Variable Name | Description | Unit |
|--------------|-------------|------|
| 101. Body Mass Index - Height | Height | meters |
| 101. Body Mass Index - Weight | Weight | kilograms |
| 101. Body Mass Index - BMI | BMI | kg/m² |

---

## 6. Adverse Events

**Purpose:** Systematic tracking of adverse events and safety outcomes

### Adverse Event Overview
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 2. Free text - 441 | Free text AE description | Text |
| 3. AE - 523 | Adverse event occurred (3 sub-fields) | Multiple |

---

### Serious Adverse Events (SAE)

| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 4. Serious adverse event - 115 | SAE tracking (7 sub-fields) | Multiple |
| └─ if SAE | SAE occurred | Binary |
| └─ if SAE (duplicate field) | SAE occurred | Binary |
| └─ SAE criteria | SAE classification criteria | Categorical |
| └─ Severity | Severity level | Categorical |
| └─ Relationship | Relationship to intervention | Categorical |
| └─ Action taken | Action taken | Categorical |
| └─ Outcome of AE | Outcome | Categorical |

---

### Major Adverse Events

#### Hypoglycemia
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 5. Severe hypoglycemia - 118 | Severe hypoglycemia event | Binary/details |

#### Falls & Fractures
| Variable Name | Description | Data Type | Sub-fields |
|--------------|-------------|-----------|------------|
| 6. Did you fall? - 107 | Fall occurred | Multiple | 4 fields: occurrence, details, date, end date |
| 7. Fracture - 108 | Fracture occurred | Multiple | 4 fields: occurrence, details, date, end date |

#### Healthcare Utilization
| Variable Name | Description | Data Type | Sub-fields |
|--------------|-------------|-----------|------------|
| 8. ER admission - 110 | Emergency room visit | Multiple | 4 fields: occurrence, details, start date, end date |
| 9. Hospitalization - 109 | Hospital admission | Multiple | 4 fields: occurrence, details, start date, end date |
| 10. Institutionalization - 111 | Institutionalization | Multiple | 4 fields: occurrence, details, start date, end date |

#### Disability & Mortality
| Variable Name | Description | Data Type | Sub-fields |
|--------------|-------------|-----------|------------|
| 11. New Disability - 112 | New disability | Multiple | 5 fields: occurrence, details, start date, end date, type |
| 13. Death - 114 | Death | Multiple | 4 fields: occurrence, details, date, end date |

#### Other Events
| Variable Name | Description | Data Type | Sub-fields |
|--------------|-------------|-----------|------------|
| 12. Other - 113 | Other adverse events | Multiple | 4 fields: occurrence, details, start date, end date |

---

### Drug-Related Adverse Events

#### Gastrointestinal Adverse Events
| Variable Name | Symptom | Data Type |
|--------------|---------|-----------|
| 14. Gastrointestinal AE - 513 | GI adverse events (13 symptoms) | Multiple checkboxes |
| └─ Nausea | Nausea | Binary |
| └─ Vomiting | Vomiting | Binary |
| └─ Diarrhoea | Diarrhea | Binary |
| └─ Constipation | Constipation | Binary |
| └─ Abdominal pain | Abdominal pain | Binary |
| └─ Upset stomach or Indigestion | Dyspepsia | Binary |
| └─ Burping | Burping/belching | Binary |
| └─ Gas (flatulence) | Flatulence | Binary |
| └─ Abdominal bloating | Bloating | Binary |
| └─ Inflamed stomach (gastritis) | Gastritis | Binary |
| └─ Reflux or Heartburn | GERD symptoms | Binary |
| └─ Slowing of gastric emptying | Gastroparesis | Binary |

#### Endocrine/Metabolic Adverse Events
| Variable Name | Event | Data Type |
|--------------|-------|-----------|
| 15. Endocrine/Metabolic AE - 514 | Endocrine/metabolic AE (4 types) | Multiple checkboxes |
| └─ Gallstones | Cholelithiasis | Binary |
| └─ Hypoglycaemia | Hypoglycemia | Binary |
| └─ Diabetic Retinopathy | DR onset/worsening | Binary |

#### Cardiovascular Adverse Events
| Variable Name | Event | Data Type |
|--------------|-------|-----------|
| 16. Cardiovascular AE - 515 | Cardiovascular AE (3 types) | Multiple checkboxes |
| └─ Low Blood Pressure | Hypotension | Binary |
| └─ Feeling dizzy or lightheaded on standing | Orthostatic symptoms | Binary |
| └─ Fast heartbeat | Tachycardia | Binary |

#### Neurological Adverse Events
| Variable Name | Event | Data Type |
|--------------|-------|-----------|
| 17. Neurological AE - 516 | Neurological AE (3 types) | Multiple checkboxes |
| └─ Headache | Headache | Binary |
| └─ Feeling weak or tired | Weakness/fatigue | Binary |
| └─ Feeling dizzy | Dizziness | Binary |

#### Dermatological/Other Adverse Events
| Variable Name | Event | Data Type |
|--------------|-------|-----------|
| 18. Dermatological/Other AE - 517 | Dermatological AE (2 types) | Multiple checkboxes |
| └─ Hairloss | Alopecia | Binary |
| └─ Injection site reactions | Injection site reactions | Binary |

#### Acute Pancreatitis
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 19. Acute Pancreatitis - 524 | Acute pancreatitis event | Binary/details |

---

### Exercise-Related Adverse Events

#### Musculoskeletal Injuries
| Variable Name | Injury Type | Data Type |
|--------------|-------------|-----------|
| 20. Musculoskeletal injuries - 518 | Musculoskeletal injuries (4 types) | Multiple checkboxes |
| └─ Muscle strain | Muscle strain | Binary |
| └─ Joint pain | Joint pain (knee, hip, shoulder) | Binary |
| └─ Low back pain | Low back pain | Binary |
| └─ Physical injury due to use of equipment | Equipment-related injury | Binary |

#### Exercise-Related Falls
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 21. Exercise related falls - 521 | Falls during exercise | Binary/details |

---

## 7. Physical Health & Function

### Anthropometric Measurements

#### Body Mass Index
| Variable Name | Description | Unit |
|--------------|-------------|------|
| 101. Body Mass Index - Height | Height | meters | Variable |
| 101. Body Mass Index - Weight | Weight | kilograms | Variable |
| 101. Body Mass Index - BMI | BMI | kg/m² | Variable |

*Note: BMI appears in both medical and body composition sections*

---

### Body Composition Measurements

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 3. Fat mass (kg) - 379 | Total fat mass | kg |
| 4. Fat mass (%) - 380 | Body fat percentage | % |
| 5. Fat free mass (kg) - 381 | Fat-free mass | kg |
| 6. Fat free mass (%) - 382 | FFM percentage | % |
| 7. SMM (kg) - 383 | Skeletal muscle mass | kg |
| 8. VAT - Visceral Adipose Tissue - 385 | Visceral fat | liters |
| 9. Fat (%) - 386 | Body fat percentage (alternate) | % |
| 10. Waist to hip ratio - 440 | WHR (3 sub-fields: waist, hip, ratio) | ratio |
| 11. Calf circumference - 535 | Calf circumference (2 sub-fields: R, L) | cm |
| 12. Body Mass Index - 366 | BMI (3 sub-fields: height, weight, BMI) | kg/m² |

---

### Exercise & Physical Activity

#### Exercise Habits
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 3. Do you exercise? - 537 | Exercise participation (8 sub-fields) | Multiple |
| └─ 0. | Exercises (yes/no) | Binary |
| └─ Aerobic | Does aerobic exercise | Binary |
| └─ Resistance | Does resistance exercise | Binary |
| └─ Other | Does other exercise | Binary |
| └─ 2. Aerobic Exercise (Weekly min) | Weekly aerobic minutes | Numeric |
| └─ 3. Aerobic Exercise Intensity (RPE) | Aerobic intensity | Numeric (RPE scale) |
| └─ 4. Meets Aerobic guidelines? | Meets aerobic guidelines | Binary |
| └─ 5. Resistance exercise (sessions) | Weekly resistance sessions | Numeric |
| └─ 6. Resistance exercise intensity (RPE) | Resistance intensity | Numeric (RPE scale) |
| └─ 7. Meets resistance exercise guidelines? | Meets resistance guidelines | Binary |

#### Physical Activity Assessment
| Variable Name | Description | Data Type |
|--------------|-------------|-----------|
| 4. Physical activity and fitness evaluation questionnaire - 533 | PA questionnaire result | Score/categorical |

---

### Frailty Assessment (Fried Criteria)

**Purpose:** Identify frailty status using validated criteria

#### Frailty Components

| Variable Name | Criterion | Description |
|--------------|-----------|-------------|
| 5. Unintentional weight loss - 239 | Weight loss | >5% body weight or >4.5 kg in past year |
| 6. Fatigue/Exhaustion - 240 | Exhaustion | CES-D scale (2 items) |
| 7. Low level of Physical activity - 244 | Physical activity | Low PA per questionnaire |
| 8. Slow walk - 245 | Walking speed | >7 seconds to walk 3 meters |
| 9. Muscle weakness - 246 | Grip strength | <20th percentile by gender and BMI |

#### Frailty Classification

| Variable Name | Description | Classification |
|--------------|-------------|----------------|
| 10. Frailty Criteria: Pre Frail - 247 | Pre-frail status | 1-2 criteria present |
| 11. Frailty Criteria: Frail - 248 | Frail status | ≥3 criteria present |

---

### Falls History

| Variable Name | Description | Data Type | Sub-fields |
|--------------|-------------|-----------|------------|
| 12. Did you fall? - 107 | Fall occurred | Multiple | 4 fields: occurrence, details, date, end date |
| 13. How many falls in past 6 months? - 422 | Fall frequency | Numeric | - |
| 14. Symptoms before falling? - 423 | Pre-fall symptoms | Multiple | 2 fields: occurrence, details |
| 15. Fall lead to hospitalization? - 424 | Fall → hospitalization | Binary | - |

---

### Frail Scale

**Purpose:** Alternative frailty assessment tool

| Variable Name | Description |
|--------------|-------------|
| 16. How much of the time during past 4 weeks did you feel tired? - 443 | Fatigue frequency |
| 17. Difficulty walking up 10 stairs without resting? - 444 | Stair climbing ability |
| 18. Difficulty walking a couple of blocks? - 445 | Walking endurance |
| 19. Did a doctor tell you that you have [illness]? - 446 | Comorbidity count (11 conditions) |
| 20. Loss of weight - 447 | Weight change (3 sub-fields) |
| 21. Automatic calculation of Frail Scale scores - 448 | Total Frail Scale score |
| 22. Categorization - 449 | Frail Scale category |

---

### SARC-F Sarcopenia Screening

**Purpose:** Screen for sarcopenia risk
**Score Range:** 0-10 (≥4 indicates sarcopenia risk)

| Variable Name | Description |
|--------------|-------------|
| 23. How much difficulty lifting and carrying 10 pounds - 434 | Strength |
| 24. How much difficulty walking across a room? - 435 | Walking |
| 25. How much difficulty transferring from chair or bed? - 436 | Transfers |
| 26. How much difficulty climbing a flight of 10 stairs? - 437 | Stair climbing |
| 27. How many times have you fallen in the past year? - 438 | Falls |
| 28. Automatic calculation of SARC-F scores - 439 | Total SARC-F score |

---

### Physical Performance Tests

#### Grip Strength Test (Dynamometer)

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 29. Right Hand - Test 1 | Right hand test 1 | kg |
| 29. Right Hand - Test 2 | Right hand test 2 | kg |
| 29. Right Hand - Test 3 | Right hand test 3 | kg |
| 29. Right Hand - Average | Right hand average | kg |
| 29. Right Hand - Percentile | Right hand percentile | percentile |
| 30. Left Hand - Test 1 | Left hand test 1 | kg |
| 30. Left Hand - Test 2 | Left hand test 2 | kg |
| 30. Left Hand - Test 3 | Left hand test 3 | kg |
| 30. Left Hand - Average | Left hand average | kg |
| 30. Left Hand - Percentile | Left hand percentile | percentile |

#### Chair Stand Test

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 31. Number of times reached full standing - 416 | Chair stands completed | count |
| 32. Was the test modified? - 421 | Test modification | Binary/details |

#### Walking Distance Test

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 33. Distance - 401 | Walking distance | meters |
| 34. Was the test modified? - 418 | Test modification | Binary/details |

#### Gait Speed Test (3 trials)

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 35. Time to pass 10 meters - 402 | Trial 1 time | seconds |
| 36. Speed | Trial 1 speed | m/s |
| 37. Time to pass 10 meters - 406 | Trial 2 time | seconds |
| 38. Speed - 408 | Trial 2 speed | m/s |
| 39. Time to pass 10 meters - 410 | Trial 3 time | seconds |
| 40. Speed - 412 | Trial 3 speed | m/s |
| 41. Was the test modified? - 419 | Test modification | Binary/details |

#### Timed Up and Go (TUG) Test

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 42. Time up & go test score - 415 | TUG time | seconds |
| 43. Was the test modified? - 420 | Test modification | Binary/details |

#### Four Square Step Test (FSST)

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 44. FSST - 417 | FSST time | seconds |

#### Balance Tests

| Variable Name | Description | Unit |
|--------------|-------------|------|
| 45. Right - 491 | Right leg balance (test 1) | seconds |
| 46. Left - 492 | Left leg balance (test 1) | seconds |
| 47. Right - 493 | Right leg balance (test 2) | seconds |
| 48. Left - 494 | Left leg balance (test 2) | seconds |

#### Short Physical Performance Battery (SPPB)

**Purpose:** Composite assessment of lower extremity function
**Components:** Balance + gait speed + chair stand
**Score Range:** 0-12 points

| Variable Name | Description | Score Range |
|--------------|-------------|
| 49. Balance test score - 430 | Balance component | 0-4 |
| 50. Gait speed test score - 431 | Gait speed component | 0-4 |
| 51. Chair stand test score - 432 | Chair stand component | 0-4 |
| 52. Automatic calculation of SPPB scores - 433 | Total SPPB score | 0-12 |

#### Test Limitations
| Variable Name | Description |
|--------------|-------------|
| 53. Is there anything that can affect the results? - 425 | Factors affecting test (2 sub-fields) |

---

## 8. Study Drug & Exercise Adherence

### Drug Adherence
| Variable Section | Description | Sub-fields |
|-----------------|-------------|------------|
| 1. Drug Injection - 504 | Drug injection tracking | 4 fields: occurrence, dose, unit, date |
| 2-5. Week 1-4 - 540-543 | Weekly dose tracking | 4 fields per week: dose, unit, date, confirmation |

### Exercise Intervention Adherence
| Variable Name | Description |
|--------------|-------------|
| 6. Number of weekly recommended study exercise sessions - 539 | Recommended sessions/week |
| 7. How many study exercise sessions did you participate in? - 505 | Actual sessions completed |
| 8-11. Exercise Session 1-4 - 506-509 | Session details (5 sub-fields each: occurrence, date, duration, type, intensity) |

---

## Data Quality Notes

### Duplicate/Related Fields
Some variables appear multiple times across sections:
- Participant study number (appears 6 times: 8, 8.1-8.5)
- Date of birth (appears 5 times across sections)
- BMI (appears in physician evaluation and body composition sections)
- Falls (appears in frailty, adverse events, and falls history sections)

---

## Recommendations for Data Cleaning

### 1. Remove Section Markers
Exclude these 100% missing columns:
- "Personal Information FINAL"
- "Physician evaluation FINAL"
- "Physical Health Agility FINAL"
- "Cognitive Health Agility- Final"
- "Adverse events FINAL"
- "Body composition FINAL"

### 2. Consolidate Duplicate Fields
- Choose one "Participant study number" field
- Choose one "Date of birth" field (or use calculated Age)
- Choose one BMI field (preferably from body composition section if available)

### 3. DSST Score Selection
Choose the appropriate DSST version based on your research question:

**Digital DSST (smartphone-based):**
- Raw score: "Raw DSS Score" (col 6)
- Standardized score: "DSST Score" (col 7)
- Use for: Smartphone-based cognitive assessment, digital health metrics

**Pen and Paper DSST (WAIS-4, 120 sec):**
- Raw score: "43. DSST - Total Score - 179"
- Standardized score: "44. Standardized Score - 180"
- Use for: Traditional neuropsychological assessment, comparison with WAIS-4 norms

**Important:** Do not combine or average scores from both versions as they are independent tests

### 4. Handle Multi-Visit Data
For longitudinal analysis:
- Use baseline (Visit 1) values for time-invariant characteristics
- Use most recent values for current status
- Model repeated measures appropriately (mixed models, GEE, etc.)

### 5. Create Derived Variables
Consider creating:
- **Diabetes complication count:** Sum of retinopathy, nephropathy, neuropathy, CVD, PVD
- **Polypharmacy indicator:** Count of medication classes
- **Physical function composite:** Combine grip strength, gait speed, SPPB
- **Frailty status:** From Fried criteria or Frail Scale
- **Sarcopenia risk:** From SARC-F score (≥4)

### 6. Variable Naming
Current variable names include reference numbers (e.g., "- 392", "- 220"). Consider:
- Creating clean variable names without reference numbers
- Using standardized medical abbreviations
- Creating a separate codebook linking old to new names

---

## Appendix: Variable Name Format

Most variable names in the CSV follow this format:
```
"[Question number]. [Question text] - [Reference number]"
```

Example: `"15. Number of education years - 230"`

Sub-fields use additional numeric prefixes:
```
"[Question number]. [Question text] - [Subfield number]. [Subfield text] - [Reference number]"
```

Example: `"29. Right Hand - 0. Test 1 - 391"`

---

## Contact & Updates

For questions about this data dictionary or to report errors, please contact the study team.

**Version:** 2.2 (Cleaned)
**Date:** October 18, 2025

**Changes from v1.0:**
- Removed excessive subsection codes (A1, C1, D2-D14, etc.)
- Added comprehensive DSST score documentation (clarified digital vs. pen-and-paper versions)
- Documented section marker columns as data artifacts
- Expanded adverse events documentation with all event types
- Added data cleaning recommendations
- Improved table formatting and navigation

**Changes in v2.1 (October 18, 2025):**
- Clarified that two independent DSST tests are administered:
  - Digital DSST (smartphone-based, study-developed): Columns 6-7
  - Pen and Paper DSST (WAIS-4, 120 sec): Columns 179-180
- Updated DSST documentation to distinguish between test versions
- Added guidance on selecting appropriate DSST version for analysis

**Changes in v2.2 (October 18, 2025):**
- Removed all missingness analysis sections
- Removed missingness columns from all variable tables
- Removed "Patient-Level Missingness" and "Missingness Categories" sections
- Removed "High Missingness Variables" and "Variables with Complete Data" sections
- Dictionary now focuses on data structure, variable types, measurements, and study design
