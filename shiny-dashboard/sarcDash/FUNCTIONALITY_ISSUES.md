# Functionality Issues Found

## Critical Issues (App-Breaking)

### 1. MoCA Column Name Mismatch
**Location**: `R/mod_cohort.R` lines 207-210, 286-291, 324-333

**Problem**: Code references `cog_moca_total` but actual column is `cog_moca_total_score`

**Impact**: MoCA filtering will fail with error "object 'cog_moca_total' not found"

**Evidence**:
```r
# mod_cohort.R line 207
visits <- dplyr::filter(visits,
                       !is.na(cog_moca_total),  # ❌ WRONG
                       cog_moca_total >= moca_range_debounced()[1],
                       cog_moca_total <= moca_range_debounced()[2])
```

**Actual column**: `cog_moca_total_score`

**Fix Required**: Replace all 6 instances of `cog_moca_total` with `cog_moca_total_score`

---

### 2. Visit Number Mismatch
**Location**: `R/mod_cohort.R` lines 44-55

**Problem**: UI offers visit numbers 0, 1, 2, 3 but data contains 1, 2, 3, 5

**Impact**:
- Visit 0 checkbox does nothing (no data)
- Visit 5 data is always excluded
- Users cannot access 6 records from visit 5

**Evidence**:
```r
# UI checkboxes (mod_cohort.R lines 48-53)
choices = list(
  "Visit 0" = "0",  # ❌ No data
  "Visit 1" = "1",  # ✓
  "Visit 2" = "2",  # ✓
  "Visit 3" = "3"   # ✓
  # Missing Visit 5!
)

# Actual data distribution:
# Visit 1: 20 records
# Visit 2: 6 records
# Visit 3: 6 records
# Visit 5: 6 records  # ❌ INACCESSIBLE
```

**Fix Required**:
1. Update checkbox choices to match actual data: 1, 2, 3, 5
2. Update default selection to include all actual visits

---

## Major Issues (Functionality Broken)

### 3. Adverse Events Domain Shows No Data
**Location**: `R/mod_domain.R` line 63, `R/app_server.R` line 57

**Problem**: Adverse events domain tries to extract `ae_*` columns from visits data, but adverse events are in separate `ae` data file

**Impact**: Adverse Events tab will always show "No data available"

**Evidence**:
- Visits data: No `ae_` columns (checked via grep '^ae_')
- AE data file: 55 columns, 45 are `ae_*` columns
- mod_domain_server extracts from cohort_data (visits only)

**Fix Required**:
1. Create separate adverse events module that uses `d$ae` data
2. OR: Merge ae columns into visits data during ds_connect()
3. Update app_server.R to pass ae data to adverse_events domain

---

## Moderate Issues (UX Problems)

### 4. Missing Translation Keys
**Location**: `inst/i18n/translation.csv`

**Problem**: 5 translation keys missing, causing warnings

**Missing Keys**:
1. "Upload Custom Data"
2. "Upload CSV File"
3. "Browse..."
4. "No file chosen"
5. "Export CSV"

**Impact**: English text shows with warnings, Hebrew translations missing

**Fix Required**: Add these 5 keys to translation.csv with Hebrew translations

---

### 5. Data Status Path Resolution Issue
**Location**: `R/data_store.R` line 235

**Problem**: `ds_status()` checks default path instead of using `get_data_dir()`

**Impact**: Status shows "error" even when data loads fine (checks wrong directory)

**Evidence**:
```
Test output:
  ✓ PASS: Data loaded successfully
  ✓ PASS: Status check works
    - Health: error   # ❌ Contradictory!
    - Message: Missing files: visits, ae, dict, summary
```

**Fix Required**: Update ds_status() to use get_data_dir() as default

---

### 6. Reset Filters Button Behavior
**Location**: `R/mod_cohort.R` lines 274-308

**Problem**: Reset filters button resets to data-driven ranges instead of meaningful defaults

**Impact**: After reset, filters might be set to unusual ranges (e.g., age 65-83 instead of 40-100)

**Current Behavior**:
```r
# Resets to actual data min/max
age_min <- min(visits$id_age, na.rm = TRUE)  # 65
age_max <- max(visits$id_age, na.rm = TRUE)  # 83
```

**Expected Behavior**: Reset to sensible defaults (40-100) or keep data-driven (document decision)

---

## Minor Issues (Polish/Quality)

### 7. Inconsistent Domain Column Filtering
**Location**: `R/mod_domain.R` line 60

**Problem**: Domains use simple prefix matching which may catch unintended columns

**Example**: `^demo_` could match `demo_test_column` unintentionally

**Fix**: Consider using data dictionary to validate domain membership

---

### 8. Performance: No Memoization for Domain Data
**Location**: `R/mod_domain.R` lines 54-64

**Problem**: Domain data extracted on every reactive call without caching

**Impact**: With 524 columns, repeated grep operations could slow down UI

**Fix**: Consider memoizing domain column extraction

---

## Summary Statistics

### Tests Run: 10
- ✓ PASS: 6
- ✗ FAIL: 4

### Critical Bugs: 2
1. MoCA column name
2. Visit number mismatch

### Must-Fix Before Production: 5
1. MoCA column name (critical)
2. Visit numbers (critical)
3. Adverse events domain (major)
4. Translation keys (moderate)
5. Data status path (moderate)

### Data Characteristics
- Rows: 38 visits
- Patients: 20 unique
- Retention Rate: 60% (12/20 have 2+ visits)
- Columns: 524 total
  - Demographics: 40
  - Cognitive: 62
  - Medical: 267
  - Physical: 102
  - Adherence: 43
  - Adverse Events: 0 in visits data (separate file)
- Age range: 65-83
- Genders: Male (15 visits), Female (23 visits)
- Visit distribution: V1(20), V2(6), V3(6), V5(6)
