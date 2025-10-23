# Sarcopenia Data Cleaning App v2.0

**Status:** ✅ Stable and Production-Ready  
**Deployed:** https://780-data-explorer.shinyapps.io/sarcDash/  
**Version:** v2.0-stable (tagged)

## Quick Start

1. **Visit:** https://780-data-explorer.shinyapps.io/sarcDash/
2. **Upload:** Your audit report CSV
3. **Clean:** Click "Clean Data" button
4. **Download:** Get cleaned visits and adverse events data

## Core Features

✅ **Patient-Level Missingness Logic** - Distinguishes "test not performed" from "truly missing"  
✅ **Time-Invariant Filling** - Demographics and units filled across all patient visits  
✅ **Dual Column Creation** - Original + analysis columns for statistical use  
✅ **Data Quality Preservation** - Empty cells vs "NA" text distinction maintained

## Performance Metrics

- **Conversions:** 5,842 patient-level empty → NA  
- **Fills:** 938 values across 108 time-invariant columns  
- **New Columns:** 114 analysis columns (_numeric, _factor, _date)  
- **Output:** 638 total columns, 38 rows (test dataset)

## 🔒 CORE PROTECTION

**⚠️ The data cleaning pipeline is PROTECTED - See [CORE_PROTECTION.md](CORE_PROTECTION.md)**

**Protected Components:**
- Data cleaning functions (app.R lines 26-381)
- Data dictionary (data_dictionary_enhanced.csv)
- Documentation (docs/DATA_CLEANING_RULES.md, docs/DEVELOPER_SPEC.md)

**Before Modifying Core Logic:**
1. Read CORE_PROTECTION.md
2. Check if change can be done AFTER cleaning
3. Create backup: `git tag v2.0-backup-$(date +%Y%m%d)`
4. Test locally: `Rscript test_new_functions.R`
5. Validate all test cases
6. Document changes

## File Structure

```
sarcopenia-app/
├── app.R                              # Main Shiny app
├── data_dictionary_enhanced.csv       # Variable metadata (PROTECTED)
├── test_new_functions.R              # Test script
├── CORE_PROTECTION.md                # Protection guidelines (READ THIS!)
├── DEPLOYMENT_SUMMARY.md             # Deployment info
├── docs/
│   ├── DATA_CLEANING_RULES.md       # Business logic (IMMUTABLE)
│   └── DEVELOPER_SPEC.md            # Technical spec (IMMUTABLE)
└── rsconnect/                        # Deployment config
```

## Adding New Features (Safe)

### ✅ SAFE: Add Analysis Tab
```r
# Add new nav_panel AFTER cleaning
nav_panel("My Analysis",
  card(plotOutput("my_plot")))
  
# Use cleaned_data()$visits_data
output$my_plot <- renderPlot({
  req(cleaned_data())
  df <- cleaned_data()$visits_data
  # Your analysis here - SAFE!
})
```

### ⚠️ CAUTION: Modify Output
```r
# Test thoroughly if changing write_csv()
# Ensure "" vs "NA" distinction preserved
```

### ❌ NEVER: Modify Core Functions
```r
# DO NOT change:
# - convert_patient_level_na()
# - fill_time_invariant()
# - create_analysis_columns()
# - Pipeline order in clean_csv()
```

## Testing

### Run Local Tests
```bash
Rscript test_new_functions.R
```

### Expected Results
- Patient 004-00232 education: 16, 16, 16 ✅
- Patient 004-00232 MoCA: 29, NA, NA ✅  
- Patient 004-00246 cholesterol unit: mg/dL, mg/dL ✅
- Console: "[CONVERT_NA] Converted 5842..." ✅
- Console: "[FILL] Total filled: 938..." ✅

## Deployment

```bash
# Deploy to shinyapps.io
Rscript -e "rsconnect::deployApp(appName='sarcDash', forceUpdate=TRUE)"
```

## Emergency Rollback

```bash
# Restore stable version
git checkout v2.0-stable
git checkout -b emergency-fix
# Deploy from emergency-fix branch
```

## Documentation

- **[CORE_PROTECTION.md](CORE_PROTECTION.md)** - Protection guidelines ⚠️ READ FIRST
- **[DATA_CLEANING_RULES.md](docs/DATA_CLEANING_RULES.md)** - Business logic explanation
- **[DEVELOPER_SPEC.md](docs/DEVELOPER_SPEC.md)** - Technical implementation
- **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - Deployment history

## Version History

### v2.0-stable (2025-10-23) - CURRENT
- ✅ Patient-level NA conversion working
- ✅ Time-invariant filling working
- ✅ Dual columns created
- ✅ CSV output correct
- ✅ Table rendering optimized
- ✅ Core protection documented

### v1.0 (Previous)
- ❌ Broken - column-based NA assignment
- ❌ No patient-level logic
- ⚠️ DO NOT USE

## Support

**Issues with data cleaning:** Review [DATA_CLEANING_RULES.md](docs/DATA_CLEANING_RULES.md)  
**Technical questions:** Review [DEVELOPER_SPEC.md](docs/DEVELOPER_SPEC.md)  
**Adding features:** Review [CORE_PROTECTION.md](CORE_PROTECTION.md)

---

**Maintainer:** Etay Cohen  
**Last Updated:** 2025-10-23  
**Status:** Production-ready, fully tested, core protected
