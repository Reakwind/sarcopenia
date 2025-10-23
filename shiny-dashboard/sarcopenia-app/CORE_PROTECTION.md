# Core Data Cleaning Pipeline - PROTECTION NOTICE

**⚠️ CRITICAL: These files and functions are the backbone of the project**

## Protected Core Components

### 1. Data Cleaning Functions (app.R lines 26-381)
**DO NOT MODIFY without extensive testing:**

- `clean_csv()` - Main cleaning pipeline orchestrator
- `convert_patient_level_na()` - Patient-level missingness logic
- `fill_time_invariant()` - Time-invariant variable filling
- `create_analysis_columns()` - Dual column creation
- `apply_variable_mapping()` - Variable name mapping
- `split_visits_and_ae()` - Data splitting logic

**Pipeline Order (CRITICAL - DO NOT REORDER):**
1. Remove section markers
2. Apply variable name mapping
3. Remove duplicate identifiers
4. Split visits and adverse events
5. Convert patient-level NAs ← MUST BE FIRST!
6. Fill time-invariant variables
7. Create dual analysis columns
8. Generate summary statistics

### 2. Data Dictionary (data_dictionary_enhanced.csv)
**Protected Fields:**
- `variable_category` (time_invariant | time_varying | adverse_event)
- `data_type` (numeric | binary | categorical | date | text)
- `new_name` (variable name mapping)

**⚠️ Changes to these fields affect cleaning logic!**

### 3. Documentation (IMMUTABLE)
**Reference documents:**
- `docs/DATA_CLEANING_RULES.md` - Business logic specification
- `docs/DEVELOPER_SPEC.md` - Technical implementation details

**These document the validated, working logic. Update ONLY if core logic changes.**

---

## Rules for Adding New Features

### ✅ SAFE: Add features AFTER cleaning
```r
# In server function, AFTER cleaned_data() is populated:
observeEvent(input$new_analysis_button, {
  # New analysis using cleaned_data()$visits_data
  # This is SAFE - doesn't affect cleaning pipeline
})
```

### ✅ SAFE: Add new UI elements
```r
# Add new tabs, buttons, visualizations
# As long as they READ from cleaned_data(), they're safe
```

### ✅ SAFE: Add new download formats
```r
# Download Excel, JSON, etc.
# Just reads cleaned_data(), doesn't modify pipeline
```

### ⚠️ CAUTION: Modifying display/output
- Changing `write_csv()` parameters affects output format
- Test that "" vs NA distinction is preserved
- Verify downloaded data matches expectations

### ❌ DANGEROUS: Modifying cleaning functions
- Changing step order in `clean_csv()`
- Modifying logic in `convert_patient_level_na()`
- Altering time-invariant filling logic
- Changing data dictionary categorization

---

## Testing Protocol for Core Changes

**IF you must modify core cleaning logic:**

1. **Backup Current Working Version**
   ```bash
   git tag -a v2.0-stable -m "Working data cleaning pipeline"
   git push origin v2.0-stable
   ```

2. **Test Locally First**
   ```bash
   Rscript test_new_functions.R
   ```

3. **Validate Test Cases**
   - Patient 004-00232 education: 16, 16, 16 (filled)
   - Patient 004-00232 MoCA: 29, NA, NA (preserved)
   - Patient 004-00246 cholesterol unit: mg/dL, mg/dL (filled)
   - Check: 5,842 patient-level NA conversions
   - Check: 938 time-invariant fills
   - Check: 114 analysis columns created

4. **Manual Verification**
   - Download cleaned CSV
   - Verify "" vs "NA" text distinction
   - Check filled vs empty vs NA patterns

5. **Document Changes**
   - Update DATA_CLEANING_RULES.md
   - Update DEVELOPER_SPEC.md
   - Update commit message with reasoning

---

## Version History

### v2.0 (CURRENT - STABLE)
**Date:** 2025-10-23
**Status:** ✅ Fully functional and tested

**Core Logic:**
- Patient-level NA conversion (5,842 conversions)
- Time-invariant filling (938 fills across 108 columns)
- Dual column creation (114 analysis columns)
- CSV output preserves "" vs NA distinction

**Validated Test Cases:**
- Education filling: PASS
- Unit filling: PASS
- MoCA preservation: PASS
- Patient-level logic: PASS

**Git Commits:**
- 4bc9d38: Remove old sarcDash golem package
- bfff325: Fix CSV download - write empty cells instead of 'NA' text
- 389e683: Fix CSV reading to preserve empty strings
- 2a69031: Fix CSV output to preserve "" vs NA distinction
- cc06df9: Improve table preview rendering

**DO NOT roll back beyond commit 389e683 - earlier versions have broken logic!**

---

## Emergency Rollback

**If core cleaning breaks:**

```bash
# Rollback to last stable version
git revert HEAD
git push

# Or restore from stable tag
git checkout v2.0-stable
git checkout -b fix-branch
# Deploy from fix-branch
```

---

## Adding Analysis Features (Safe Examples)

### Example 1: Add Summary Statistics Tab
```r
# Add new tab in UI
nav_panel("Statistics",
  card(
    card_header("Descriptive Statistics"),
    tableOutput("stats_table")
  ))

# Add output in server
output$stats_table <- renderTable({
  req(cleaned_data())
  # Analyze cleaned_data()$visits_data
  # Does NOT modify cleaning pipeline
})
```

### Example 2: Add Visualization
```r
# Add plot output
output$plot <- renderPlot({
  req(cleaned_data())
  df <- cleaned_data()$visits_data
  # Use the _numeric columns for plotting
  # Does NOT modify cleaning pipeline
})
```

### Example 3: Add Export Format
```r
# Add Excel download
output$download_excel <- downloadHandler({
  req(cleaned_data())
  write_xlsx(cleaned_data()$visits_data, file)
  # Reads from cleaned data, safe
})
```

---

## Contact for Core Changes

**Before modifying core cleaning logic:**
1. Review this document
2. Check if change can be done AFTER cleaning instead
3. Create backup/tag
4. Test extensively
5. Document thoroughly

**Remember:** It took multiple iterations to get the cleaning logic right. Protect it!

---

**Last Updated:** 2025-10-23
**Maintainer:** Etay Cohen
**Status:** PROTECTED - HANDLE WITH CARE

