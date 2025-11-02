# Data Pipeline Conventions

This document describes the data pipeline architecture and conventions for working with cleaned data in analysis features.

## Overview

The sarcopenia app has a three-stage data pipeline:

```
Raw CSV → Cleaning (fct_cleaning.R) → Cleaned Data → Analysis Features → UI Display
```

Understanding how column names change through this pipeline is critical for building analysis features.

---

## Column Naming Conventions

### Dictionary → Cleaned Data Mapping

**Time-Varying Variables** get analysis suffixes:

| Data Type     | Suffix      | Example |
|--------------|-------------|---------|
| `numeric`    | `_numeric`  | `cog_moca_total_score` → `cog_moca_total_score_numeric` |
| `binary`     | `_factor`   | `cog_standardized_score_v1` → `cog_standardized_score_v1_factor` |
| `categorical`| `_factor`   | `demo_educational_degree` → `demo_educational_degree_factor` |
| `date`       | `_date`     | `id_visit_date` → `id_visit_date_date` |
| `text`       | (none)      | `med_primary_care_doctor` → `med_primary_care_doctor` |

**Time-Invariant Variables** keep their base name (no suffix):

```r
demo_dominant_hand  →  demo_dominant_hand  (no suffix)
```

**Why suffixes?**
- Allows both numeric and factor versions to coexist
- Analysis features can choose which to use
- Prevents name collisions

### Metadata Columns

Analysis features can add metadata columns:

| Metadata Type   | Suffix           | Example |
|----------------|------------------|---------|
| Missing data flag | `_is_missing` | `cog_moca_total_score_numeric_is_missing` |
| Outlier type | `_outlier_type` | `cog_moca_total_score_numeric_outlier_type` |

---

## Using Data in Analysis Features

### DON'T Do This (Manual Resolution)

```r
# ❌ BAD: Hardcoded suffix logic
cols_to_select <- c("cog_moca_total_score_numeric", "cog_dsst_score_numeric")

# ❌ BAD: Assuming column exists without checking
moca_score <- data$cog_moca_total_score_numeric

# ❌ BAD: Not converting factors before display
reactable::reactable(data)  # Will show "[object Object]" for factors
```

### DO This (Use Utilities)

```r
library(utils_data_pipeline)

# ✓ GOOD: Resolve column names from dictionary
dict_vars <- c("cog_moca_total_score", "cog_dsst_score")
actual_cols <- get_analysis_columns(dict_vars, dict, data)

# ✓ GOOD: Access data safely using resolved names
moca_score <- data[[actual_cols["cog_moca_total_score"]]]

# ✓ GOOD: Prepare for display
display_col <- prepare_for_display(moca_score)
reactable::reactable(data.frame(score = display_col))
```

---

## Utility Functions Reference

### 1. `resolve_column_name()`

Resolves a single dictionary variable name to its actual column name.

```r
resolve_column_name("cog_moca_total_score", dict, data)
# Returns: "cog_moca_total_score_numeric"

resolve_column_name("cog_standardized_score_v1", dict, data)
# Returns: "cog_standardized_score_v1_factor"
```

**Parameters:**
- `dict_var_name`: Variable name from dictionary
- `dict`: Data dictionary tibble
- `data`: Cleaned data tibble
- `prefer`: "auto" (default), "numeric", or "factor"

**Returns:** Actual column name or `NA` if not found

### 2. `get_analysis_columns()`

Resolves multiple variables at once. Returns named vector.

```r
dict_vars <- c("cog_moca_total_score", "cog_dsst_total_score")
cols <- get_analysis_columns(dict_vars, dict, data)

# Returns:
# c(cog_moca_total_score = "cog_moca_total_score_numeric",
#   cog_dsst_total_score = "cog_dsst_total_score_numeric")

# Access data using resolved names:
data[[cols["cog_moca_total_score"]]]
```

### 3. `prepare_for_display()`

Converts data for UI display (factors → character, dates formatted).

```r
# Convert factor column for reactable
display_col <- prepare_for_display(data$cog_standardized_score_v1_factor)

# Works with any data type
display_col <- prepare_for_display(data$id_visit_date)
```

### 4. `validate_instrument_variables()`

Validates that all instrument variables exist before rendering.

```r
validation <- validate_instrument_variables(dict, "DSST", data)

if (!validation$valid) {
  warning(validation$message)
  # Handle missing variables
} else {
  # Proceed with rendering
  resolved_vars <- validation$resolved_vars
}
```

### 5. `get_metadata_column_name()`

Gets consistent metadata column names.

```r
actual_col <- "cog_moca_total_score_numeric"
missing_col <- get_metadata_column_name(actual_col, "is_missing")
# Returns: "cog_moca_total_score_numeric_is_missing"

outlier_col <- get_metadata_column_name(actual_col, "outlier_type")
# Returns: "cog_moca_total_score_numeric_outlier_type"
```

---

## Adding New Analysis Features

Follow this pattern for all new analysis features:

### Step 1: Get Variables from Dictionary

```r
# Get instrument variables (dictionary names)
instrument_vars_dict <- get_instrument_variables(dict, "MoCA")
```

### Step 2: Resolve to Actual Column Names

```r
# Resolve to actual column names in data
actual_cols <- get_analysis_columns(instrument_vars_dict, dict, data)
```

### Step 3: Validate (Optional but Recommended)

```r
# Validate before proceeding
validation <- validate_instrument_variables(dict, "MoCA", data)
if (!validation$valid) {
  stop(validation$message)
}
```

### Step 4: Extract and Process Data

```r
# Select columns
data_subset <- data %>%
  dplyr::select(tidyselect::all_of(unname(actual_cols)))

# Process numeric columns only
numeric_cols <- actual_cols[sapply(actual_cols, function(col) {
  is_numeric_for_analysis(data_subset[[col]])
})]

# Detect outliers, calculate stats, etc.
```

### Step 5: Prepare for Display

```r
# Convert factors to character for reactable
for (col in names(data_subset)) {
  data_subset[[col]] <- prepare_for_display(data_subset[[col]])
}

# Add metadata columns (use safe_unname to avoid warnings)
data_subset$moca_is_missing <- safe_unname(is.na(data_subset[[actual_cols["cog_moca_total_score"]]]))
```

### Step 6: Render UI

```r
reactable::reactable(data_subset, columns = column_defs)
```

---

## Complete Example

Here's a complete example of a new analysis feature:

```r
#' Get MoCA Analysis Table
#'
#' @param data Cleaned visits data
#' @param dict Data dictionary
#' @return Tibble ready for display
get_moca_analysis_table <- function(data, dict) {

  # 1. Get dictionary variable names
  moca_vars_dict <- get_instrument_variables(dict, "MoCA")

  if (length(moca_vars_dict) == 0) {
    return(NULL)
  }

  # 2. Resolve to actual column names
  moca_cols <- get_analysis_columns(moca_vars_dict, dict, data, warn_missing = TRUE)

  if (length(moca_cols) == 0) {
    return(NULL)
  }

  # 3. Validate
  validation <- validate_instrument_variables(dict, "MoCA", data)
  if (!validation$valid) {
    warning(validation$message)
  }

  # 4. Extract data
  result_table <- data %>%
    dplyr::select(id_client_id, id_client_name, tidyselect::all_of(unname(moca_cols)))

  # 5. Detect outliers (only on numeric columns)
  numeric_cols <- unname(moca_cols)[sapply(unname(moca_cols), function(col) {
    is_numeric_for_analysis(result_table[[col]])
  })]

  if (length(numeric_cols) > 0) {
    outliers <- detect_outliers(result_table, numeric_cols)

    # Add metadata
    for (col in numeric_cols) {
      result_table[[get_metadata_column_name(col, "is_missing")]] <-
        safe_unname(is.na(result_table[[col]]))

      result_table[[get_metadata_column_name(col, "outlier_type")]] <-
        get_outlier_type(outliers, col)
    }
  }

  # 6. Prepare for display
  for (col in unname(moca_cols)) {
    result_table[[col]] <- prepare_for_display(result_table[[col]])
  }

  return(result_table)
}
```

---

## Common Pitfalls

### Pitfall 1: Hardcoded Suffixes

```r
# ❌ DON'T
data$cog_moca_total_score_numeric  # Assumes suffix

# ✓ DO
cols <- get_analysis_columns("cog_moca_total_score", dict, data)
data[[cols["cog_moca_total_score"]]]
```

### Pitfall 2: Not Preparing for Display

```r
# ❌ DON'T
reactable::reactable(data)  # Factors render as "[object Object]"

# ✓ DO
display_data <- data
for (col in names(display_data)) {
  display_data[[col]] <- prepare_for_display(display_data[[col]])
}
reactable::reactable(display_data)
```

### Pitfall 3: Named Vectors in Metadata

```r
# ❌ DON'T
result_table$is_missing <- is.na(data$moca)  # May have row names

# ✓ DO
result_table$is_missing <- safe_unname(is.na(data$moca))
```

### Pitfall 4: Assuming Columns Exist

```r
# ❌ DON'T
data$cog_moca_total_score  # May not exist

# ✓ DO
validation <- validate_instrument_variables(dict, "MoCA", data)
if (validation$valid) {
  # Proceed safely
}
```

---

## When to Use Which Function

| Task | Function |
|------|----------|
| Resolve 1 variable name | `resolve_column_name()` |
| Resolve multiple variables | `get_analysis_columns()` |
| Check all variables exist | `validate_instrument_variables()` |
| Prepare data for UI | `prepare_for_display()` |
| Get metadata column name | `get_metadata_column_name()` |
| Check if numeric | `is_numeric_for_analysis()` |
| Remove names from vector | `safe_unname()` |

---

## Testing Your Feature

Always test with:

1. **Numeric variables** (e.g., MoCA total score)
2. **Factor variables** (e.g., binary standardized scores)
3. **Missing instruments** (ensure graceful failure)
4. **Missing columns** (ensure error messages are clear)

```r
# Test script template
test_my_feature <- function() {
  dict <- read_csv("data_dictionary_enhanced.csv")
  raw_data <- read_csv("path/to/Audit report.csv")
  cleaned <- clean_csv(raw_data)

  # Test with valid instrument
  result <- my_feature(cleaned$visits_data, "MoCA", dict)
  stopifnot(!is.null(result))

  # Test with invalid instrument
  result <- my_feature(cleaned$visits_data, "Invalid", dict)
  stopifnot(is.null(result))

  cat("✓ Tests passed\n")
}
```

---

## Questions?

If you're unsure about column naming or data pipeline conventions:
1. Check this document first
2. Look at existing features (`R/fct_instrument_analysis.R`, `R/fct_analysis.R`)
3. Use utility functions - they encapsulate best practices
