# sarcDash - Sarcopenia Study Data Dashboard

**Version:** 0.1.0
**Status:** 🚧 Development

---

## Overview

Interactive Shiny dashboard for exploring cleaned Sarcopenia study data with:

- ✅ **Bilingual Support**: English/Hebrew with RTL layout
- ✅ **Domain Analysis**: Demographics, Cognitive, Medical, Physical, Adherence, Adverse Events
- ✅ **Cohort Builder**: Comprehensive filtering system
- ✅ **Longitudinal Tracking**: Paired visit analysis with change detection
- ✅ **Quality Checks**: Missingness analysis and outlier detection
- ✅ **Secure Exports**: Anonymized data and plots
- ✅ **Accessibility**: AA-level compliance, keyboard navigation

---

## Prerequisites

- R >= 4.3.0
- RStudio (recommended)
- Data files from pipeline:
  - `visits_data.rds`
  - `adverse_events_data.rds`
  - `data_dictionary_cleaned.csv`
  - `summary_statistics.rds`

---

## Installation

### 1. Clone/Download

```bash
cd /path/to/sarcopenia/shiny-dashboard/sarcDash
```

### 2. Restore Dependencies

```r
# Install renv if not already installed
if (!require("renv")) install.packages("renv")

# Restore project library
renv::restore()
```

### 3. Install Development Dependencies (optional)

```r
golem::install_dev_deps()
```

---

## Running the App

### Development Mode

```r
# Load and run
golem::run_dev()
```

### Production Mode

```r
# Using run_app()
sarcDash::run_app()

# Or from command line
Rscript -e "sarcDash::run_app()"
```

---

## Testing

### Run All Tests

```r
# Load test framework
library(testthat)

# Run tests
test_dir("tests/testthat")
```

### Run Specific Test File

```r
test_file("tests/testthat/test-smoke.R")
```

### Code Coverage

```r
library(covr)
cov <- package_coverage()
report(cov)
```

### Linting

```r
library(lintr)
lint_package()
```

---

## Project Structure

```
sarcDash/
├── R/                      # App code
│   ├── app_config.R        # Configuration
│   ├── app_server.R        # Server logic
│   ├── app_ui.R            # UI layout
│   ├── data_store.R        # Data loading (Prompt 1)
│   └── mod_*.R             # Shiny modules
├── inst/
│   ├── app/                # App resources
│   │   ├── www/            # Static files (CSS, JS, images)
│   │   └── i18n/           # Translation files (EN/HE)
│   └── golem-config.yml    # Golem configuration
├── tests/
│   ├── testthat/           # Unit tests
│   └── testthat.R          # Test runner
├── dev/                    # Development scripts
├── DESCRIPTION             # Package metadata
├── NAMESPACE               # Package exports
└── README.md               # This file
```

---

## Development Workflow

### Adding a New Module

```r
# Create module files
golem::add_module(name = "module_name", open = FALSE)

# This creates:
# - R/mod_module_name.R (UI and server)
# - R/mod_module_name_fct.R (helper functions)
```

### Adding Dependencies

```r
# Add package to DESCRIPTION
usethis::use_package("package_name")

# Install from DESCRIPTION
renv::install()
renv::snapshot()
```

### Running Checks

```r
# R CMD check
devtools::check()

# Spell check
spelling::spell_check_package()
```

---

## Features

### 🏠 Home Page
- Dataset health cards
- Quick action links
- Guided tour (6+ steps, bilingual)

### 📚 Data Dictionary
- Interactive search and filtering
- Domain prefix legend (id_, demo_, cog_, med_, phys_, adh_, ae_)
- CSV export

### 🔬 Cohort Builder
- Filters: Age, Gender, MoCA, DSST, Visit dates, Retention
- Save/load filter sets (JSON)
- Human-readable query summary

### 📊 Domain Modules
1. **Demographics**: Age, gender, education distributions
2. **Cognitive**: DSST & MoCA analysis with correlations
3. **Medical**: HbA1c, diabetes duration, complications
4. **Physical**: BMI, BP, gait speed
5. **Adherence**: Adherence scores and categories
6. **Adverse Events**: Timeline and rates

### 📈 Longitudinal Analysis
- Paired visit comparisons
- Change metrics with 95% CI
- Spaghetti plots, paired boxplots

### ✅ Quality Checks
- Missingness heatmaps
- Range validations
- Duplicate detection

### 🚀 Settings
- Light/dark theme toggle
- Language: EN/HE with RTL support
- Performance knobs

---

## Security & Privacy

⚠️ **PHI Protection**:
- No patient names or identifiers displayed
- All exports use hashed IDs
- No console logging of sensitive data

---

## Deployment

### shinyapps.io

```r
# Deploy
rsconnect::deployApp()
```

### Docker (optional)

```bash
# Build image
docker build -t sarcdash .

# Run container
docker run -p 3838:3838 sarcdash
```

---

## Troubleshooting

### Issue: "Package not found"
**Solution**: Run `renv::restore()` to install dependencies

### Issue: "Data files not found"
**Solution**: Ensure data files are in correct location (see configuration)

### Issue: "renv.lock out of sync"
**Solution**: Run `renv::snapshot()` to update lockfile

---

## Development Roadmap

- [x] Prompt 0: Bootstrap (golem + renv + tests)
- [ ] Prompt 1: Data loader with validation
- [ ] Prompt 2: Internationalization (EN/HE + RTL)
- [ ] Prompt 3: App shell with theming
- [ ] Prompts 4-6: Core UI (Home, Dictionary, Cohort Builder)
- [ ] Prompts 7-12: Domain modules
- [ ] Prompts 13-15: Advanced analysis
- [ ] Prompts 16-17: Exports & Settings
- [ ] Prompts 18-20: Accessibility, Performance, Testing
- [ ] Prompts 21-23: Deployment & Polish

---

## Contributing

This project follows the TDD (Test-Driven Development) approach:

1. Write tests first
2. Implement functionality
3. Refactor as needed
4. Run full test suite
5. Commit with meaningful messages

---

## Contact

**Team**: Sarcopenia Study Team
**Email**: team@sarcopenia.study

---

## License

MIT License - see LICENSE file for details
