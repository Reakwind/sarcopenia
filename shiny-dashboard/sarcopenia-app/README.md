# Sarcopenia Data Cleaning App v2.1

**Status:** ✅ Modular Architecture - Production-Ready
**Deployed:** https://780-data-explorer.shinyapps.io/sarcDash/
**Version:** v2.1-modular
**Architecture:** Source-based modular (NOT Golem package)

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
├── app.R                              # Main app entry point (258 lines)
├── R/                                 # Modular code organization
│   ├── fct_cleaning.R                 # Core cleaning functions (PROTECTED)
│   ├── fct_analysis.R                 # Statistical analysis (scaffold)
│   ├── fct_visualization.R            # Plotting/charting (scaffold)
│   ├── fct_reports.R                  # Report generation (scaffold)
│   ├── utils.R                        # Utility functions
│   ├── mod_analysis.R                 # Analysis tab module (scaffold)
│   ├── mod_visualization.R            # Visualization tab module (scaffold)
│   └── mod_reports.R                  # Reports tab module (scaffold)
├── data_dictionary_enhanced.csv       # Variable metadata (PROTECTED)
├── test_new_functions.R               # Test script
├── CORE_PROTECTION.md                 # Protection guidelines (READ THIS!)
├── DEPLOYMENT_SUMMARY.md              # Deployment info
├── docs/
│   ├── DATA_CLEANING_RULES.md         # Business logic (IMMUTABLE)
│   ├── DEVELOPER_SPEC.md              # Technical spec (IMMUTABLE)
│   └── ARCHITECTURE.md                # Modular architecture guide
└── rsconnect/                         # Deployment config
```

## Adding New Features (Safe with Modular Architecture)

### ✅ SAFE: Add Analysis Functions
```r
# In R/fct_analysis.R - add your statistical analysis function
calculate_my_stats <- function(data, variables) {
  # Implement your analysis
  # Uses cleaned_data()$visits_data
  return(results)
}

# In app.R server - call your function
output$my_results <- renderTable({
  req(cleaned_data())
  calculate_my_stats(cleaned_data()$visits_data, selected_vars)
})
```

### ✅ SAFE: Add Visualization Functions
```r
# In R/fct_visualization.R - add plotting function
plot_my_chart <- function(data, x_var, y_var) {
  # Create ggplot
  ggplot(data, aes(x = !!sym(x_var), y = !!sym(y_var))) +
    geom_point()
}

# In R/mod_visualization.R - use in module
output$my_plot <- renderPlot({
  req(cleaned_data())
  plot_my_chart(cleaned_data()$visits_data, input$x, input$y)
})
```

### ✅ SAFE: Add New Tab Module
```r
# Step 1: Implement module in R/mod_mynew.R
source("R/mod_mynew.R")  # Add to app.R source section

# Step 2: Add UI to app.R navset_card_tab
nav_panel("My Feature", mod_mynew_ui("mynew"))

# Step 3: Call server in app.R server function
mod_mynew_server("mynew", cleaned_data)
```

### ⚠️ CAUTION: Modify Output
```r
# Test thoroughly if changing write_csv()
# Ensure "" vs "NA" distinction preserved
```

### ❌ NEVER: Modify Core Cleaning File
```r
# DO NOT modify R/fct_cleaning.R without following testing protocol!
# Protected functions:
# - convert_patient_level_na()
# - fill_time_invariant()
# - create_analysis_columns()
# - Pipeline order in clean_csv()
#
# See CORE_PROTECTION.md for details
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

### v2.1-modular (2025-10-24) - CURRENT
- ✅ **Modular architecture** - Code organized in R/ directory
- ✅ **Core protected** - Cleaning functions in R/fct_cleaning.R
- ✅ **Scaffolds ready** - Analysis, visualization, reports modules
- ✅ **Simplified app.R** - Reduced from 576 to 258 lines
- ✅ **All tests passing** - Exact same functionality maintained
- ✅ **Deployment unchanged** - Source-based (NOT Golem package)
- ✅ **Rollback available** - v2.0-pre-refactor tag

### v2.0-stable (2025-10-23)
- ✅ Patient-level NA conversion working
- ✅ Time-invariant filling working
- ✅ Dual columns created
- ✅ CSV output correct
- ✅ Table rendering optimized
- ✅ Core protection documented
- ⚠️ Single-file app.R (576 lines)

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
