# Column Comparison Diagnostic Tool

## Problem
You believe the DSST standardized score exists in your raw data but disappears after cleaning. This tool helps verify what's actually happening.

## How to Use

### Step 1: Open R Console
Open RStudio or R terminal in this project directory:
```r
setwd("/Users/etaycohen/Documents/Sarcopenia/shiny-dashboard/sarcopenia-app")
```

### Step 2: Source the Diagnostic Script
```r
source("diagnostic_column_comparison.R")
```

### Step 3: Set Your Raw Data Path
Replace with your actual file path:
```r
raw_csv <- "path/to/your/Audit report.csv"
# Example:
# raw_csv <- "/Users/etaycohen/Documents/Data/Audit report.csv"
```

### Step 4: Run Diagnostics

#### Option A: Full Column Comparison
```r
results <- compare_columns(raw_csv)
```

This will show:
- How many columns in raw data
- How many columns in cleaned data
- Which columns appear "missing" (likely renamed)
- Which columns are new (analysis columns like `_numeric`, `_factor`)

#### Option B: Find DSST Columns Specifically
```r
dsst_info <- find_dsst_columns(raw_csv)
```

This will show:
- All DSST-related columns in raw data
- All DSST-related columns in cleaned data
- All "standardized" or "standard" columns in both

#### Option C: Search for Specific Pattern
```r
# Search for any pattern
search_columns(raw_csv, "standard")
search_columns(raw_csv, "percentile")
search_columns(raw_csv, "moca")
```

### Step 5: Save Results (Optional)
```r
# Save column lists to text files
results <- compare_columns(raw_csv)
writeLines(results$raw_columns, "raw_columns.txt")
writeLines(results$cleaned_columns, "cleaned_columns.txt")
```

## What to Look For

### If DSST Standardized Score Exists in Raw Data:
Look at the output from `find_dsst_columns()`. You should see something like:
```
DSST-related columns in RAW data:
  - DSST Score
  - Standardized Score
  - Raw DSS Score
```

**If you see it in RAW but not in CLEANED:**
- The column name doesn't match the data dictionary
- We need to add the correct mapping

### If DSST Standardized Score is NOT in Raw Data:
Then it's not being removed by cleaning - it simply doesn't exist in your export. You may need to:
- Re-export data from RedCap with all fields enabled
- Check if it's in a different form/instrument
- Verify the field exists in your RedCap project

## Common Patterns

### Renamed Columns
If a column appears in "missing_from_cleaned" but you see a similar name in the cleaned data, it was renamed:
- Raw: `DSST Score` → Cleaned: `cog_dsst_score`
- Raw: `MoCA Total` → Cleaned: `cog_moca_total_score`

### New Columns
Columns ending in:
- `_numeric` - Numeric analysis version
- `_factor` - Factor analysis version
- `_date` - Date analysis version

These are ADDED by cleaning, not present in raw data.

### Truly Missing Columns
If a column is in raw data but completely absent from cleaned data (no renamed version), that's a bug we need to fix.

## Next Steps

After running the diagnostic, report back:
1. **EXACT column name** in your raw data for DSST standardized score
2. Whether it appears in cleaned data (under any name)
3. Any other columns that are truly missing

Then we can:
- Update the data dictionary mapping
- Or fix the cleaning code if there's a bug
