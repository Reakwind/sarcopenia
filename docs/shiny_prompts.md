# Shiny Dashboard — Prompts Plan (User Journey + UX/UI + TDD)

Below is a complete, sequenced **prompts file** you can paste to a code‑generation LLM. Follow the order. Each prompt is **standalone**, written as `text` to encourage test‑driven, incremental development with no orphaned code. The app targets the cleaned datasets produced by your pipeline (`visits_data.rds`, `adverse_events_data.rds`, `data_dictionary_cleaned.csv`, `summary_statistics.rds`).

---

## User Journey (reference map for the prompts)

**Persona:** Clinical researcher validating DSST and exploring longitudinal trends in older adults with diabetes. Limited dev time, high safety standards, zero tolerance for PHI leaks.

**Happy-path:**  
1) Open app → Landing page shows dataset status (row/col counts, last modified), PHI warning, language/theme toggles.  
2) Review **Data Dictionary** → understand variable names/prefixes/domains.  
3) **Build cohort** → filter by age, gender, MoCA, DSST, visit windows; confirm sample size.  
4) Explore **Domain tabs**: Demographics, Cognitive (DSST, MoCA), Medical, Physical, Adherence, Adverse Events.  
5) Use **Longitudinal** view: per-patient change, visit comparisons, paired plots, delta summaries.  
6) Run **QC/Missingness** checks & outlier flags (no PHI).  
7) **Export** filtered cohort (anonymized) and selected plots; capture report notes.  
8) Adjust **Settings**: theme (light/dark), language (EN/HE, RTL), numeric/date formats, performance knobs.  
9) **Guided tour** on first run; all actions keyboard accessible; no console leaks.

**Skeptical checkpoints:**  
- Are we accidentally exposing names/identifiers?  
- Do longitudinal deltas recompute correctly when filters change?  
- Are performance caches invalidated on the right events?  
- Is RTL layout actually usable? (mirroring, alignment, bidi text)

---

## Prompt 0 — Project bootstrap with {golem}, tests, and renv
```text
Objective: Create a modular Shiny package app scaffold using {golem} with tests, {shinytest2}, and {renv} for reproducibility.

Tasks:
1) Create package project "sarcDash" using golem::create_golem().
2) Add dependencies: shiny, bslib, thematic, shinyvalidate, shinyWidgets, reactable, plotly, ggplot2, dplyr, tidyr, purrr, readr, glue, stringr, lubridate, memoise, shinybusy, waiter, shiny.i18n, cicerone, shinytest2, testthat (>=3.0), covr, lintr, vroom, data.table (optional), fs, here.
3) Initialize renv; snapshot lockfile.
4) Add GitHub Actions workflow skeleton (R CMD check).

Acceptance:
- R CMD check passes locally (no NOTES beyond package title/desc).
- testthat is active (edition 3), shinytest2 installed, tests directory created.
- renv.lock exists; README has dev run instructions: golem::run_dev() and sarcDash::run_app().
```

---

## Prompt 1 — Global data contract & loader (with memoization and validation)
```text
Objective: Define strict data contract and a single loader for all datasets with validation and caching.

Tasks:
1) Create R/data_store.R exporting: ds_connect(data_dir = "data") -> list(visits, ae, dict, summary).
2) Validate files exist: visits_data.rds, adverse_events_data.rds, data_dictionary_cleaned.csv, summary_statistics.rds.
3) On load: enforce types for key columns (id_*, dates as Date, numerics) and basic dimensional sanity checks.
4) Use memoise::memoise to cache loads by data_dir+file mtimes.
5) Provide ds_status() that returns counts, last_modified timestamps, and a short health string for UI.

Acceptance:
- Unit tests (testthat) cover: missing file errors, wrong types rejection, caching behavior, status summary.
- No console printing; all messages returned as values.
```

---

## Prompt 2 — Internationalization and RTL support (EN/HE) with shiny.i18n
```text
Objective: Add bilingual support (English/Hebrew) with runtime language toggle and RTL layout switch.

Tasks:
1) Create inst/i18n/translations.json with keys for all static UI strings (EN/HE).
2) In app_ui, add language dropdown (EN/HE) and a toggle for RTL (dir='rtl') that persists in shiny::reactiveVal.
3) Provide i18n$t("...") helper and wrapper t_() to translate labels in UI and modules.
4) Add a small RTL CSS override for alignment, flex direction, and icon placement.

Acceptance:
- shinytest2 UI snapshot tests verify language strings switch and html[dir=rtl] applied.
- Accessibility: lang attribute and dir attribute toggle present; no layout break (basic smoke test).
```

---

## Prompt 3 — App shell with bslib theme tokens and top-level navigation
```text
Objective: Create a cohesive layout and consistent design tokens using {bslib}.

Tasks:
1) app_ui(): navbar or sidebar layout with sections: Home, Data Dictionary, Cohort Builder, Domains (Demographics, Cognitive, Medical, Physical, Adherence, AE), Longitudinal, QC/Missingness, Settings.
2) Define a bslib::bs_theme with primary, base font sizes, and spacing scale; add dark/light auto via thematic::thematic_shiny().
3) Add global PHI warning banner (dismissible) and last-updated indicator from ds_status().
4) Keyboard skip links (“Skip to content”, “Skip to filters”).

Acceptance:
- shinytest2 navigation test: can switch all tabs.
- lintr passes; no inline styles; all colors from theme vars.
```

---

## Prompt 4 — Home page: dataset health, quick actions, guided tour
```text
Objective: Landing page that confirms data readiness and orients the user.

Tasks:
1) Cards: (a) Dataset health (rows, variables, last modified), (b) Quick links (Cohort Builder, Domains, QC), (c) Learn (start guided tour).
2) Add cicerone walkthrough with at least 6 steps (language-aware); store “seen_tour” in shiny::reactiveFileReader or local storage.
3) Show spinner while ds_status() resolves; handle failures with non-blocking alerts.

Acceptance:
- shinytest2: guided tour starts and completes; status cards populated from fixture datasets.
```

---

## Prompt 5 — Data Dictionary viewer with search and prefix legend
```text
Objective: Interactive data dictionary driven by data_dictionary_cleaned.csv.

Tasks:
1) Use reactable to show columns: original_name, new_name, domain, type, description (if available).
2) Add prefix legend cards (id_, demo_, cog_, med_, phys_, adh_, ae_) with filters by clicking.
3) Search box filters by any text; export CSV of filtered view.

Acceptance:
- Unit test: mapping columns present and filter produces expected subset on small test dict.
- No PHI (original names shouldn’t contain identifiers; assert).
```

---

## Prompt 6 — Cohort Builder (filters + state + summary)
```text
Objective: Build a reproducible filter state that all tabs respect.

Tasks:
1) Left sidebar with filters: Age (range), Gender (multi), MoCA (range), DSST (range), Diabetes duration (range), Visit date window, Visit number (1/2/both), Retention (has both visits).
2) Reset Filters button; Save Filter Set (serialize to JSON and download).
3) Cohort summary: N patients, N visits, distribution chips; show current “filter query” as human-readable text.

Acceptance:
- shinytest2: adjust filters updates counts.
- Unit tests for helper that computes retention and human-readable query.
```

---

## Prompt 7 — Demographics domain module
```text
Objective: Demographics view keeping cohort filters in sync.

Tasks:
1) KPIs: N, median age [IQR], gender breakdown, education years if present.
2) Plots: Age histogram/density (plotly), gender bar, education distribution.
3) Table: reactable of selected demographic fields; column visibility toggles; CSV export (anonymized).

Acceptance:
- Smoke test that toggling gender filter updates charts and table row count.
- Accessibility: charts have descriptive titles and aria labels.
```

---

## Prompt 8 — Cognitive domain module (DSST + MoCA)
```text
Objective: Visualize DSST & MoCA distributions and relationships.

Tasks:
1) KPIs: mean/SD DSST by visit; MoCA mean/SD; % MoCA<26.
2) Plots: DSST distribution by visit (violin/box), scatter DSST vs MoCA with linear smoother and r value.
3) Optional: show ICC from precomputed summary if available; otherwise hide element.

Acceptance:
- Unit test: correlation helper returns r and n for filtered data.
- Snapshot test: DSST by visit plot changes when Visit filter toggled.
```

---

## Prompt 9 — Medical domain module
```text
Objective: Summaries for key medical variables (e.g., HbA1c, duration, complications flags).

Tasks:
1) KPIs: HbA1c mean/SD, diabetes duration stats.
2) Plots: HbA1c distribution; complications stacked bars (if binary flags available).
3) Table with medical variables; CSV export (anonymized).

Acceptance:
- Smoke tests for filtering; unit tests for stats helper.
```

---

## Prompt 10 — Physical domain module
```text
Objective: Physical assessments (e.g., gait, BP, BMI) if present in dataset.

Tasks:
1) KPIs: BMI mean/SD; BP mean.
2) Plots: BMI distribution; BP scatter systolic vs diastolic; gait speed if available.
3) Table with physical vars; CSV export (anonymized).

Acceptance:
- Smoke tests ensure charts update with Age filter.
```

---

## Prompt 11 — Adherence domain module
```text
Objective: View self-reported adherence scales or related metrics.

Tasks:
1) KPIs and distributions for adherence scores.
2) Table and export.
3) Optional: show adherence categories (good/moderate/poor) if thresholds are defined in dict.

Acceptance:
- Unit tests for categorization helper; snapshot for histogram.
```

---

## Prompt 12 — Adverse Events (AE) module
```text
Objective: Explore adverse events at the patient level.

Tasks:
1) AE table with date, type, severity; filter by severity and date window.
2) Per-patient AE timeline (plotly) with hover details (no names).
3) AE rate summary per 100 patient-years (simple exposure approximation derived from visit spacing).

Acceptance:
- Unit tests for rate calculator with synthetic fixtures.
- Snapshot test for AE timeline.
```

---

## Prompt 13 — Longitudinal module (paired change)
```text
Objective: Visualize change between visit 1 and 2.

Tasks:
1) Create helper to compute deltas per patient for selected numeric variables (DSST, HbA1c, BMI, MoCA).
2) Plots: paired lines (spaghetti), paired boxplots, delta histogram.
3) KPI: mean change with 95% CI and N (only patients with both visits).

Acceptance:
- Unit tests: delta calculator returns correct Ns and excludes single-visit patients.
- Snapshot: paired plot changes when Retention filter toggled.
```

---

## Prompt 14 — Missingness & QC module
```text
Objective: Provide a quick quality overview and checks.

Tasks:
1) Missingness heatmap (variables vs patients) using ggplot or visdat-style mimic; aggregate missing counts by domain.
2) QC cards: no future dates, age range 18-120, no duplicate (id_client_id, id_visit_no); display PASS/FAIL.
3) Visits distribution by visit_no.

Acceptance:
- Unit tests for QC helpers; snapshot for heatmap on fixture.
```

---

## Prompt 15 — Outliers & data quality
```text
Objective: Flag suspicious points without altering data.

Tasks:
1) Flag rules: DSST outside [0, max plausible], HbA1c <4 or >14, BMI <12 or >60.
2) Outliers table with variable, value, percentile rank, patient id (hashed or masked), visit.
3) Toggle to hide/show flagged rows on charts.

Acceptance:
- Unit test: outlier helper returns expected rows from synthetic fixture.
```

---

## Prompt 16 — Exports (always anonymized)
```text
Objective: Safe exporting of filtered cohorts and visuals.

Tasks:
1) Export filtered cohort as CSV; drop names/PII; ensure id is an obfuscated hash (stable across session).
2) Export plots as PNG/SVG with caption including filter summary and timestamp.
3) “Reproduce selection” button outputs JSON of filters for later reuse.

Acceptance:
- Unit tests for anonymization function (no names; stable hash).
```

---

## Prompt 17 — Settings module (theme, language, formatting, performance)
```text
Objective: Let users tune the experience.

Tasks:
1) Theme toggle (light/dark); font size scale; numeric format (decimal point/comma); date format.
2) Language toggle (EN/HE); persistent across session via options.
3) Performance knobs: enable memoized summaries, limit max N points for scatter (subsample with message).

Acceptance:
- shinytest2: toggles change theme and language; performance knob reduces plotted points.
```

---

## Prompt 18 — Accessibility & keyboard navigation
```text
Objective: AA-level accessibility and keyboard-first UX.

Tasks:
1) Add aria-labels to interactive elements; ensure tab order; implement skip links.
2) Provide “high-contrast” toggle; ensure readable fonts.
3) Ensure hover-only interactions have focus alternatives.

Acceptance:
- Automated a11y check (axe via shinytest2 addin or custom check) has no critical violations (document any unavoidable ones).
```

---

## Prompt 19 — App performance profiling and targeted reactivity
```text
Objective: Keep the app responsive on mid-size datasets.

Tasks:
1) Use profvis on reactive paths; memoise expensive summaries by (filter hash, variable set).
2) Replace reactive() with eventReactive() where appropriate; isolate() where safe.
3) Confirm caches invalidate on filter changes; add cache metrics in Settings.

Acceptance:
- Unit tests for cache invalidation by filter hash; manual profiling notes added to docs.
```

---

## Prompt 20 — Testing strategy with shinytest2 and testthat
```text
Objective: Comprehensive tests without flakiness.

Tasks:
1) Add shinytest2: e2e navigation test; filter smoke; i18n/RTL snapshots; cohort count snapshots.
2) Add unit tests: helpers (correlation, deltas, outliers, anonymization, QC).
3) CI config to run shinytest2 headless (XVFB) and upload snapshots as artifacts.

Acceptance:
- CI green; local tests pass; minimal snapshot churn after minor UI text changes (use i18n keys).
```

---

## Prompt 21 — Deployment packaging (renv + Docker optional)
```text
Objective: Reproducible deploy to shinyapps.io or RStudio Connect; optional Docker.

Tasks:
1) Ensure renv.lock pinned; add app.R entrypoint using run_app().
2) Optional Dockerfile FROM rocker/r-ver; install system deps; renv::restore(); expose 3838; CMD to run app.
3) Document deployment steps in README.

Acceptance:
- Local run via `R -e "sarcDash::run_app()"` works; optional docker build succeeds.
```

---

## Prompt 22 — Final polish and guided tour content
```text
Objective: Wrap up UX details and ensure no orphan code.

Tasks:
1) Ensure every module UI/server is referenced from app_server/app_ui; remove dead code.
2) Guided tour (cicerone) content finalized for EN/HE and RTL; includes tooltips for filters and exports.
3) README: screenshots, features list, known limitations, privacy considerations, contact.

Acceptance:
- Manual walkthrough matches the “User Journey”; no dangling files; lint clean.
```

---

## Prompt 23 — (Optional) Report composer
```text
Objective: Create a mini report generator composing selected plots and KPIs into an Rmd or Quarto document for export.

Tasks:
1) Add a “Compose report” modal with checkboxes for sections; on confirm, render to HTML/PDF with filters metadata.
2) Ensure no PHI leaks; include anonymization notice.

Acceptance:
- Rendered report exists; unit test checks placeholder content structure.
```

---

### Notes on Safety & Privacy baked into prompts
- **No PHI/PII**: Never display or export names or free text; hash IDs when exporting.  
- **Reactivity sanity**: Compute once per filter change; avoid nested observers.  
- **Accessibility**: Support keyboard-only users; ensure aria labeling and meaningful chart titles.  
- **Localization**: Translate all visible strings; support RTL without breaking layout.  
- **Performance**: Memoize summaries; subsample large scatters.

---

### Minimal fixture guidance for tests
- Provide small synthetic `visits_data.rds` / `adverse_events_data.rds` with 8–12 patients, 2 visits, DSST/MoCA/HbA1c/BMI, some missingness, and a handful of AE records.  
- Provide `data_dictionary_cleaned.csv` with prefixes and domains used above.
