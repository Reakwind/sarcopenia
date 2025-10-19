# Sarcopenia Study - Data Cleaning Pipeline

**Version:** 1.0
**Last Updated:** October 19, 2025
**Status:** ✅ Production

---

## Overview

This repository contains the data cleaning and preprocessing pipeline for the Sarcopenia study. The pipeline processes raw patient visit data, handles missing values at the patient level, and outputs clean, analysis-ready datasets.

### Key Features

- ✅ **Patient-Level Missing Data Handling**: Time-invariant variables filled across all patient visits
- ✅ **Domain-Prefixed Variables**: Systematic naming (id_, demo_, cog_, med_, phys_, adh_, ae_)
- ✅ **Comprehensive Testing**: Unit, integration, and end-to-end tests
- ✅ **Security Review**: PHI/PII protection and input validation
- ✅ **Automated Quality Checks**: Pre-commit hooks and CI/CD pipeline
- ✅ **Documentation**: Complete code review checklist and testing guide

---

## Quick Start

### Prerequisites

- R ≥ 4.3.0
- Required packages:
  ```r
  install.packages(c(
    "tidyverse",
    "here",
    "testthat",
    "lintr",
    "covr"
  ))
  ```

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd Sarcopenia

# Install Git hooks
./scripts/install_hooks.sh

# Run tests to verify setup
Rscript -e "testthat::test_dir('tests/testthat')"
```

### Running the Data Cleaning Pipeline

```r
# From R console in project root
source("scripts/01_data_cleaning.R")
```

**Input:** `Audit report.csv` (raw patient visit data)

**Outputs:**
- `data/visits_data.rds` - Clean visit data
- `data/adverse_events_data.rds` - Adverse events data
- `data/data_dictionary_cleaned.csv` - Variable mapping
- `data/summary_statistics.rds` - Summary statistics

---

## Testing

### Running Tests

```r
# Run all tests
testthat::test_dir("tests/testthat")

# Run specific test suite
testthat::test_file("tests/testthat/test-unit-functions.R")
testthat::test_file("tests/testthat/test-patient-filling.R")
testthat::test_file("tests/testthat/test-e2e.R")

# Run with filter
testthat::test_dir("tests/testthat", filter = "patient")
```

### Test Coverage

```r
# Generate coverage report
library(covr)
cov <- package_coverage()
report(cov)  # Opens in browser
```

**Target Coverage:** ≥ 80%

### Test Suites

| Suite | Tests | Purpose |
|-------|-------|---------|
| `test-unit-functions.R` | 42 | Helper functions (clean_var_name, safe_numeric, safe_date) |
| `test-patient-filling.R` | 12 | Patient-level missing data handling |
| `test-e2e.R` | 18 | Complete pipeline validation |

**Total:** 72+ tests

### Pre-Commit Hooks

Automatically run before each commit:
- ✅ PHI/PII detection
- ✅ Large file detection (>10MB)
- ✅ Code style linting
- ✅ Unit tests
- ✅ Debugging code detection
- ✅ Security checks

To bypass (use sparingly): `git commit --no-verify`

### CI/CD Pipeline

GitHub Actions runs on:
- Every push to `main` or `develop`
- Every pull request
- Nightly at 2 AM UTC

Pipeline includes:
1. **Test Job**: Unit tests, coverage (80% threshold), security audit
2. **Style Check**: Code formatting validation
3. **Documentation Check**: Required docs exist

See [Testing Guide](docs/testing_guide.md) for complete documentation.

---

## Project Structure

```
Sarcopenia/
├── scripts/
│   ├── 01_data_cleaning.R      # Main data cleaning script
│   ├── pre-commit               # Pre-commit hook
│   └── install_hooks.sh         # Hook installation script
├── data/
│   ├── visits_data.rds          # Clean visit data (output)
│   ├── adverse_events_data.rds  # AE data (output)
│   ├── data_dictionary_cleaned.csv
│   └── summary_statistics.rds
├── tests/
│   ├── testthat.R               # Test runner
│   ├── testthat/
│   │   ├── test-unit-functions.R
│   │   ├── test-patient-filling.R
│   │   └── test-e2e.R
│   └── fixtures/
│       └── sample_raw_data.csv
├── docs/
│   ├── cleaning_report.md       # Data cleaning documentation
│   ├── testing_guide.md         # Testing documentation
│   ├── security_review.md       # Security checklist
│   └── code_review_checklist.md # Code review standards
├── .github/
│   └── workflows/
│       └── test.yml             # CI/CD configuration
└── README.md
```

---

## Data Processing

### Variable Classification

Variables are classified into domains with prefixes:

| Prefix | Domain | Examples |
|--------|--------|----------|
| `id_` | Identifiers | client_id, visit_no, visit_date |
| `demo_` | Demographics | gender, education_years, ethnicity |
| `cog_` | Cognitive | dsst_score, moca_total, memory_score |
| `med_` | Medical | diagnosis, medications, comorbidities |
| `phys_` | Physical | height, weight, gait_speed |
| `adh_` | Adherence | medication_adherence |
| `ae_` | Adverse Events | ae_description, ae_severity |

### Patient-Level Missing Data Handling

**Critical Feature:** Time-invariant variables (gender, ethnicity, education) are filled across all patient visits using bidirectional filling (`fill(.direction = "downup")`).

**Logic:**
1. If variable present in **any** visit → propagate to all visits for that patient
2. If variable missing in **all** visits → remains NA (true patient-level missingness)

**Example:**
```
Patient P001:
  Visit 1: gender = "Male", education = NA
  Visit 2: gender = NA,     education = 16
  Visit 3: gender = NA,     education = NA

After filling:
  Visit 1: gender = "Male", education = 16
  Visit 2: gender = "Male", education = 16
  Visit 3: gender = "Male", education = 16
```

See `tests/testthat/test-patient-filling.R` for comprehensive test cases.

---

## Security

### PHI/PII Protection

- ✅ No patient identifiers in code or logs
- ✅ No hardcoded secrets or passwords
- ✅ Input validation on all file operations
- ✅ Secure file permissions (0600) on output
- ✅ Pre-commit hook checks for PHI patterns

**Pattern Detection:** `004-[0-9]{5}` (patient ID format)

### Security Review

Complete security audit available in [docs/security_review.md](docs/security_review.md).

**Status:** 🟡 Conditional Pass (3 critical issues identified with fixes)

---

## Code Quality

### Style Guide

This project follows the [Tidyverse Style Guide](https://style.tidyverse.org/):
- snake_case for variables and functions
- 2-space indentation (no tabs)
- 80-character line limit
- Space after commas and around operators

### Code Review

All code must pass review using [docs/code_review_checklist.md](docs/code_review_checklist.md).

**Minimum Passing Score:** 4.0/5.0 average across 8 weighted categories

### Linting

```r
# Lint single file
lintr::lint("scripts/01_data_cleaning.R")

# Lint directory
lintr::lint_dir("scripts")
```

---

## Contributing

### Workflow

1. Create feature branch: `git checkout -b feature/description`
2. Make changes and write tests
3. Run tests locally: `testthat::test_dir("tests/testthat")`
4. Check coverage: `covr::package_coverage()`
5. Commit (pre-commit hooks will run automatically)
6. Push and create pull request
7. CI/CD pipeline runs automatically
8. Request code review

### Requirements

- ✅ All tests pass
- ✅ Code coverage ≥ 80%
- ✅ Code review score ≥ 4.0/5.0
- ✅ All CRITICAL items = 5/5
- ✅ No security vulnerabilities

### Documentation

When adding new features:
1. Write tests first (TDD)
2. Add roxygen2 comments to functions
3. Update relevant documentation
4. Add examples to testing guide if applicable

---

## Documentation

| Document | Purpose |
|----------|---------|
| [cleaning_report.md](docs/cleaning_report.md) | Data cleaning methodology and results |
| [testing_guide.md](docs/testing_guide.md) | Complete testing documentation |
| [security_review.md](docs/security_review.md) | Security audit and recommendations |
| [code_review_checklist.md](docs/code_review_checklist.md) | Code review scoring rubric |

---

## Troubleshooting

### Tests Fail Locally

```r
# Clear R session
rm(list = ls())

# Restart R
.rs.restartR()  # RStudio

# Update packages
update.packages()

# Verify R version
R.version.string  # Should be ≥ 4.3.0
```

### Coverage Too Low

```r
# Identify untested code
cov <- package_coverage()
report(cov)  # Opens browser with line-by-line coverage
```

### Pre-Commit Hook Issues

```bash
# Reinstall hook
./scripts/install_hooks.sh

# Check hook is executable
ls -la .git/hooks/pre-commit

# Bypass hook (emergency only)
git commit --no-verify
```

---

## Contact & Support

**Project Lead:** [To be filled]
**Maintainer:** [To be filled]
**Issues:** [GitHub Issues](https://github.com/user/repo/issues)

---

## License

[To be determined]

---

## Changelog

### Version 1.0 (October 19, 2025)
- ✅ Initial data cleaning pipeline
- ✅ Patient-level missing data handling
- ✅ Comprehensive testing framework (72+ tests)
- ✅ Security review and code review checklists
- ✅ Pre-commit hooks and CI/CD pipeline
- ✅ Complete documentation

---

**Last Updated:** October 19, 2025
**Document Version:** 1.0
