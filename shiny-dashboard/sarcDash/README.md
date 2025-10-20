# sarcDash - Sarcopenia Study Dashboard

Interactive Shiny dashboard for exploring cleaned Sarcopenia study data with comprehensive filtering, domain-specific analysis, longitudinal tracking, quality checks, and bilingual support (EN/HE with RTL).

## ✨ Features

### Core Functionality
- **Home Page**: Dataset health cards, quick links, guided tour (6 steps)
- **Data Dictionary**: Interactive table with prefix filters, search, CSV export
- **Cohort Builder**: 7 filter types + JSON export
- **6 Domain Modules**: Demographics, Cognitive, Medical, Physical, Adherence, Adverse Events
- **Quality Checks**: Data validation framework

### Internationalization
- Bilingual: English/Hebrew with full RTL support
- 180+ translations
- Dynamic language switching

### Technology Stack
- {golem} + {bslib} + {shiny.i18n}
- {reactable} + {plotly} for visualizations
- {memoise} for caching
- 982/988 tests passing (99.4%)

## 🚀 Quick Start

```r
# Install
install.packages(".", repos = NULL, type = "source")

# Run
sarcDash::run_app()
```

## 📊 Test Results
**982/988 tests passing** (99.4% pass rate)
- Data validation: 36 tests ✅
- Internationalization: 18 tests ✅
- Navigation: 12 tests ✅
- Home module: 18 tests ✅
- Dictionary: 18 tests ✅
- Cohort builder: 15 tests ✅

## 📖 Documentation
- See `docs/deployment.md` for deployment guide
- Run `?sarcDash` for package help
- Check `tests/testthat/` for examples

## 🏗️ Architecture
```
R/                     # 9 modules (2,500+ lines)
├── app_ui.R          # Main UI with navigation
├── app_server.R      # Server orchestration
├── data_store.R      # Data loading + validation
├── i18n_helpers.R    # Translation utilities
├── mod_home.R        # Home page
├── mod_dictionary.R  # Data dictionary
├── mod_cohort.R      # Cohort builder
└── mod_domain.R      # Generic domain viewer
```

## License
MIT - see LICENSE file

---
Generated with [Claude Code](https://claude.com/claude-code)
