# Sarcopenia App - Modular Architecture Guide

**Version:** 2.1-modular
**Date:** 2025-10-24
**Status:** Production

---

## Overview

The Sarcopenia Data Cleaning app has been refactored from a single 576-line `app.R` file into a modular, organized structure. This architecture:

- **Protects** core cleaning logic in isolated files
- **Organizes** code by function type (analysis, visualization, reports)
- **Scales** easily as new features are added
- **Maintains** deployment reliability (source-based, NOT Golem package)

---

## Architecture Principles

### 1. Source-Based Modular (NOT Package)

**Critical:** This is NOT a Golem/R package structure. We use simple `source()` calls.

**Why:** Golem package deployment to shinyapps.io had unresolved bundling conflicts. Source-based approach:
- ✅ Works reliably with rsconnect
- ✅ No package build overhead
- ✅ Clean deployment (just files, no DESCRIPTION/NAMESPACE)
- ✅ Same organization benefits as Golem

### 2. Core Protection

**R/fct_cleaning.R is PROTECTED** - contains validated cleaning logic that took extensive testing to perfect. Modifications require:
1. Git backup tag
2. Local testing
3. Validation of all test cases
4. Documentation update

### 3. Scaffold Pattern

Empty scaffold files provide templates for adding features:
- Function scaffolds (`fct_*.R`)
- Module scaffolds (`mod_*.R`)
- Clear TODOs showing where to add code

---

## Directory Structure

```
sarcopenia-app/
├── app.R                          # Entry point (258 lines)
│   ├── Library imports
│   ├── source() all R/ files
│   ├── UI definition
│   ├── Server definition
│   └── shinyApp() call
│
├── R/                             # All modular code
│   ├── fct_cleaning.R             # ⚠️ PROTECTED - Core cleaning
│   ├── fct_analysis.R             # Statistical analysis functions
│   ├── fct_visualization.R        # Plotting/charting functions
│   ├── fct_reports.R              # Report generation functions
│   ├── utils.R                    # Utility functions
│   ├── mod_analysis.R             # Analysis tab module
│   ├── mod_visualization.R        # Visualization tab module
│   └── mod_reports.R              # Reports tab module
│
├── data_dictionary_enhanced.csv   # ⚠️ PROTECTED - Variable metadata
├── test_new_functions.R           # Testing script
├── CORE_PROTECTION.md             # Protection guidelines
├── README.md                      # Project overview
│
└── docs/
    ├── ARCHITECTURE.md            # This file
    ├── DATA_CLEANING_RULES.md     # Business logic
    └── DEVELOPER_SPEC.md          # Technical spec
```

---

## File Naming Conventions

### `fct_*.R` - Function Files
Contain pure functions (no Shiny reactive code).

**Examples:**
- `fct_cleaning.R` - Data cleaning functions
- `fct_analysis.R` - Statistical analysis functions
- `fct_visualization.R` - ggplot/plotting functions
- `fct_reports.R` - Report generation functions

**Usage in app.R:**
```r
source("R/fct_analysis.R")

# In server:
result <- calculate_descriptive_stats(cleaned_data()$visits_data, vars)
```

### `mod_*.R` - Shiny Module Files
Contain Shiny modules with UI and server components.

**Pattern:**
```r
# mod_analysis.R
mod_analysis_ui <- function(id) {
  ns <- NS(id)
  tagList(
    # UI components
  )
}

mod_analysis_server <- function(id, cleaned_data) {
  moduleServer(id, function(input, output, session) {
    # Server logic
  })
}
```

**Usage in app.R:**
```r
source("R/mod_analysis.R")

# In UI:
nav_panel("Analysis", mod_analysis_ui("analysis"))

# In server:
mod_analysis_server("analysis", cleaned_data)
```

### `utils.R` - Utility Functions
Helper functions used across the app.

**Examples:**
- Input validation
- Formatting (p-values, numbers)
- Column name helpers

---

## How app.R Sources Files

```r
# app.R structure:

# 1. Load libraries
library(shiny)
library(dplyr)
# ...

# 2. Source all R files (ORDER MATTERS)
source("R/fct_cleaning.R")      # Core (needed by others)
source("R/fct_analysis.R")       # Can use utils
source("R/fct_visualization.R")  # Can use utils
source("R/fct_reports.R")        # Can use utils
source("R/utils.R")              # Pure helpers
source("R/mod_analysis.R")       # Uses fct_analysis
source("R/mod_visualization.R")  # Uses fct_visualization
source("R/mod_reports.R")        # Uses fct_reports

# 3. Define UI
ui <- page_sidebar(...)

# 4. Define server
server <- function(input, output, session) {
  cleaned_data <- reactiveVal(NULL)
  # ...
}

# 5. Run app
shinyApp(ui, server)
```

---

## Adding New Features

### Example 1: Add Descriptive Statistics

**Step 1:** Implement function in `R/fct_analysis.R`

```r
#' Calculate Descriptive Statistics
calculate_descriptive_stats <- function(data, variables) {
  results <- data %>%
    select(all_of(variables)) %>%
    summarise(across(
      everything(),
      list(
        n = ~sum(!is.na(.)),
        mean = ~mean(., na.rm = TRUE),
        sd = ~sd(., na.rm = TRUE),
        median = ~median(., na.rm = TRUE)
      ),
      .names = "{.col}_{.fn}"
    ))

  return(results)
}
```

**Step 2:** Use in app.R server

```r
# In server function:
output$desc_stats <- renderTable({
  req(cleaned_data())
  req(input$selected_vars)

  calculate_descriptive_stats(
    cleaned_data()$visits_data,
    input$selected_vars
  )
})
```

### Example 2: Add Visualization Tab

**Step 1:** Implement module in `R/mod_visualization.R`

```r
mod_visualization_ui <- function(id) {
  ns <- NS(id)

  tagList(
    card(
      card_header("Variable Selection"),
      selectInput(ns("x_var"), "X Variable:", choices = NULL),
      selectInput(ns("y_var"), "Y Variable:", choices = NULL),
      actionButton(ns("plot_btn"), "Create Plot", class = "btn-primary")
    ),
    card(
      card_header("Scatter Plot"),
      plotOutput(ns("scatter_plot"))
    )
  )
}

mod_visualization_server <- function(id, cleaned_data) {
  moduleServer(id, function(input, output, session) {

    # Update variable choices when data loaded
    observe({
      req(cleaned_data())
      numeric_cols <- names(cleaned_data()$visits_data %>%
                           select(where(is.numeric)))

      updateSelectInput(session, "x_var", choices = numeric_cols)
      updateSelectInput(session, "y_var", choices = numeric_cols)
    })

    # Create plot
    output$scatter_plot <- renderPlot({
      req(input$x_var, input$y_var)
      req(cleaned_data())

      plot_scatter_regression(
        cleaned_data()$visits_data,
        input$x_var,
        input$y_var
      )
    })
  })
}
```

**Step 2:** Add to app.R

```r
# In UI navset_card_tab:
nav_panel("Visualizations", mod_visualization_ui("viz"))

# In server:
mod_visualization_server("viz", cleaned_data)
```

### Example 3: Add Report Generation

**Step 1:** Implement function in `R/fct_reports.R`

```r
#' Generate Analysis Report
generate_analysis_report <- function(data, output_format = "pdf", include_sections = c("descriptive", "comparative")) {
  # Check if rmarkdown package is available
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    warning("Package 'rmarkdown' is required for report generation. Please install it with: install.packages('rmarkdown')")
    return(NULL)
  }

  message("Generating ", output_format, " report...")

  tryCatch({
    # Create temporary R Markdown file
    temp_rmd <- tempfile(fileext = ".Rmd")

    # Generate R Markdown content
    rmd_content <- paste0(
      "---\n",
      "title: 'Sarcopenia Data Analysis Report'\n",
      "date: '", format(Sys.Date(), "%B %d, %Y"), "'\n",
      "output: ", output_format, "_document\n",
      "---\n\n",
      "```{r setup, include=FALSE}\n",
      "knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)\n",
      "library(dplyr)\n",
      "library(knitr)\n",
      "```\n\n"
    )

    # Write and render document
    writeLines(rmd_content, temp_rmd)
    output_file <- tempfile(fileext = paste0(".", output_format))
    rmarkdown::render(temp_rmd, output_file = output_file, quiet = TRUE)

    message("Report generated successfully: ", output_file)
    return(output_file)

  }, error = function(e) {
    warning("Failed to generate report: ", e$message)
    return(NULL)
  })
}
```

**Note:** This function uses `requireNamespace()` for optional dependencies (rmarkdown, knitr) with graceful degradation if not installed.

**Step 2:** Add download handler in app.R

```r
output$download_report <- downloadHandler(
  filename = function() {
    paste0("analysis_report_", Sys.Date(), ".pdf")
  },
  content = function(file) {
    req(cleaned_data())
    generate_analysis_report(cleaned_data()$visits_data, file)
  }
)
```

---

## Data Flow

```
1. User uploads CSV
   ↓
2. app.R: read_csv() with na = character()
   ↓
3. R/fct_cleaning.R: clean_csv() called
   ├── apply_variable_mapping()
   ├── split_visits_and_ae()
   ├── convert_patient_level_na()     ← Patient-level logic
   ├── fill_time_invariant()           ← Fill demographics
   └── create_analysis_columns()       ← Create dual columns
   ↓
4. cleaned_data reactiveVal populated
   ↓
5. Modules/outputs access cleaned_data()
   ├── $visits_data        (main data)
   ├── $adverse_events_data (AE data)
   └── $summary            (stats)
```

---

## Testing Strategy

### Local Testing
```bash
# Test core cleaning functions
Rscript test_new_functions.R

# Check for expected results:
# - 5,842 NA conversions
# - 938 time-invariant fills
# - 114 analysis columns created
```

### Integration Testing
1. Run app locally: `R -e "shiny::runApp()"`
2. Upload test CSV
3. Click "Clean Data"
4. Verify:
   - Summary stats correct
   - Tables render
   - Downloads work
5. Check R console for cleaning messages

### Deployment Testing
1. Deploy to shinyapps.io
2. Test full workflow in production
3. Verify cleaning logs in shinyapps.io dashboard

---

## Deployment

### What rsconnect Bundles

```
Deployed files:
- app.R
- R/*.R (all source files)
- data_dictionary_enhanced.csv
- (NOT docs/, tests/, dev/ - excluded by .rscignore)
```

### Deployment Command

```bash
Rscript -e "rsconnect::deployApp(appName='sarcDash', forceUpdate=TRUE)"
```

### .rscignore Configuration

Already configured to exclude:
- test files
- documentation
- development files
- R package files (DESCRIPTION, NAMESPACE, etc.)

**Critical:** Source-based deployment works. Do NOT introduce package structure.

---

## Common Patterns

### Accessing Cleaned Data in Modules

```r
mod_myfeature_server <- function(id, cleaned_data) {
  moduleServer(id, function(input, output, session) {

    # Always req() cleaned data first
    output$my_output <- renderTable({
      req(cleaned_data())  # ← Ensures data exists

      df <- cleaned_data()$visits_data
      # Your logic here
    })
  })
}
```

### Using Analysis Columns

```r
# Original columns: character, preserves "" vs NA
data$cog_moca_total_score  # "29", "", NA

# Analysis columns: numeric/factor/date for stats
data$cog_moca_total_score_numeric  # 29, NA, NA (both "" and NA → NA)
data$demo_gender_factor            # factor levels
data$id_visit_date_date            # Date class
```

### Error Handling

```r
result <- tryCatch({
  my_analysis_function(data)
}, error = function(e) {
  showNotification(
    paste("Error:", e$message),
    type = "error",
    duration = 10
  )
  NULL
})
```

---

## Troubleshooting

### "Object not found" Errors

**Cause:** Function not sourced or sourced in wrong order

**Solution:**
1. Check function exists in appropriate R/ file
2. Ensure file is sourced in app.R
3. Check source order (dependencies first)

### "Function doesn't see cleaned_data"

**Cause:** Module not receiving cleaned_data reactive

**Solution:**
```r
# In app.R server:
mod_myfeature_server("myfeature", cleaned_data)  # ← Pass reactive
```

### Deployment Works Locally but Fails on shinyapps.io

**Possible causes:**
1. Absolute file paths (use relative)
2. Missing library in app.R
3. File not included in deployment (check .rscignore)

---

## Future Enhancements

### Planned Features (Scaffolds Ready)

1. **Statistical Analysis Tab**
   - Descriptive statistics
   - Group comparisons
   - Correlation analysis
   - Regression modeling

2. **Visualization Tab**
   - Distribution plots
   - Comparison charts
   - Scatter plots with regression
   - Heatmaps

3. **Reports Tab**
   - PDF report generation
   - Excel export with multiple sheets
   - HTML reports

### Adding New Features

1. Implement in scaffold files
2. Test locally
3. Update app.R to use module
4. Deploy and verify
5. Document in README.md

---

## Version Control

### Git Tags

- `v2.0-pre-refactor` - Rollback point (single-file app.R)
- `v2.0-stable` - Stable single-file version
- `v2.1-modular` - Current modular architecture

### Rollback Procedure

```bash
# If modular version has issues:
git checkout v2.0-pre-refactor
git checkout -b emergency-fix
# Deploy from emergency-fix branch
```

---

## Key Takeaways

1. ✅ **Source-based modular** - NOT Golem package
2. ✅ **R/fct_cleaning.R is PROTECTED** - follow testing protocol
3. ✅ **Scaffolds provide templates** - fill in TODOs
4. ✅ **Modules isolate features** - easy to add/remove tabs
5. ✅ **Deployment unchanged** - rsconnect bundles files normally
6. ✅ **All tests passing** - validated functionality maintained

---

**Maintainer:** Etay Cohen
**Last Updated:** 2025-10-24
**Status:** Production-ready modular architecture
