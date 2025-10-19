# Prompt Plan — Test-Driven, Incremental Build

Below are the sequenced prompts for a code‑generation LLM. Feed them **one by one**, waiting for tests to go green at each step before proceeding. Prompts are separated and each is tagged as `text`.

---

## Prompt 1 — Project scaffold & minimal tests
```text
You are creating an R project scaffold for a data-cleaning pipeline. Implement:

1) Create directories:
- scripts/, tests/testthat/, tests/fixtures/, docs/, .github/workflows/, data/ (gitignored).

2) Add tests/testthat.R that runs testthat::test_dir("tests/testthat").

3) Add tests/testthat/test-smoke.R with a single smoke test (expect_true(TRUE)).

4) Add tests/fixtures/sample_raw_data.csv with 5 patients × up to 3 visits and representative columns that will exercise:
   - identifiers (Org ID, Client ID, Client Name, Gender, Age, Visit date)
   - cognitive (Raw DSS Score, DSST Score)
   - demographic, medical, physical, adherence, adverse events markers sufficient for unit/integration/E2E tests
   Use only synthetic IDs and names (no PHI). Keep the file small.

5) Add a minimal README.md with instructions to run tests locally:
   Rscript -e "testthat::test_dir('tests/testthat')"

Ensure all files are created and the test suite passes (1 test).
```

---

## Prompt 2 — Implement `clean_var_name()` via tests first
```text
Create tests in tests/testthat/test-clean-var-name.R covering:
- Removes trailing reference numbers: "15. Number of education years - 230" -> "number_of_education_years"
- Removes leading question numbers: "12. BMI" -> "bmi"
- Removes sub-field numbers: "BMI - 0. Height" -> "bmi_height"
- Collapses whitespace/newlines and lowercases
- Replaces non-alphanumerics with underscores
- Trims leading/trailing/multiple underscores
- Idempotency: already_clean_variable_name -> itself
- Error on NULL input

Then implement scripts/helpers_cleaning.R exporting:
clean_var_name <- function(name) { ... } as a pure function (no side effects).
Run tests and make them pass.
```

---

## Prompt 3 — Implement `safe_numeric()` with edge cases
```text
Add tests in tests/testthat/test-safe-numeric.R:
- "123"->123, "45.67"->45.67
- "36/41"->36 (extract leading number)
- "100 units"->100
- "Score: 75"->NA (no leading number)
- NA->NA; NULL raises descriptive error
- Vectorization over a character vector

Implement scripts/helpers_cast.R with:
safe_numeric(x) enforcing NULL check and leading-number extraction using regex; returns numeric; pure.
All tests green.
```

---

## Prompt 4 — Implement `safe_date()` with 3 formats + vectorization
```text
Add tests in tests/testthat/test-safe-date.R:
- "2025-04-20" -> Date(2025-04-20)
- "20/04/2025" -> same
- "04/20/2025" -> same
- Vectorized input returns same-length Date vector with correct values
- NA->NA; NULL raises error

Implement safe_date(x) in scripts/helpers_cast.R (same file), trying formats in order: "%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y", suppress warnings. Pure & vectorized. All tests green.
```

---

## Prompt 5 — Binary coercion helper
```text
Add tests in tests/testthat/test-binary-coerce.R for coercion to logical:
- yes/true/1 -> TRUE; no/false/0 -> FALSE (case-insensitive; trims whitespace)
- Non-matching strings -> NA
- NA -> NA; NULL -> error
- Vectorized behavior

Implement to_logical(x) in scripts/helpers_cast.R using case_when with normalized lowercase and trimws. All tests green.
```

---

## Prompt 6 — Import & input validation (file existence/size), character-only read
```text
Add tests in tests/testthat/test-import.R:
- When file missing: expect error "Input file not found"
- When file too large (>100 MB): simulate via a stub size checker; expect error "Input file too large"
- On valid file: read CSV as all-character columns; assert dimensions match fixture; confirm no factors.

Implement scripts/step01_import.R:
- validate_input(file_path, max_size_bytes = 100*1024^2)
- read_raw_character_tibble(file_path) using readr with col_types=cols(.default="c")
Export these functions; ensure tests pass.
```

---

## Prompt 7 — Remove section markers
```text
Add a test in tests/testthat/test-sections.R that verifies exactly 6 artifact "section marker" columns are removed from the imported tibble (use known names you placed in the fixture).

Implement scripts/step02_sections.R:
- remove_section_markers(df, marker_names) -> df without those columns; pure function.
Wire a small integration in a helper test to import -> remove -> assert column count decreased by 6. All green.
```

---

## Prompt 8 — Build variable mapping (classification + prefixing + dedup) and write CSV
```text
Create tests in tests/testthat/test-mapping.R:
- Given representative raw column names, classification assigns expected domains (identifier/demographic/cognitive/medical/physical/adherence/adverse_events).
- Prefix rules applied (id_/demo_/cog_/med_/phys_/adh_/ae_); names cleaned via clean_var_name().
- Dedup: if collision, append _2, _3 deterministically.
- Persist mapping to data/data_dictionary_cleaned.csv; file exists after run.

Implement scripts/step03_mapping.R:
- classify_section(name, position) per patterns and position rules
- build_variable_mapping(df) -> tibble(original_name, position, section, new_name)
- write_mapping_csv(mapping, path)
Ensure tests green.
```

---

## Prompt 9 — Apply cleaned names with uniqueness enforcement
```text
Add tests in tests/testthat/test-rename.R:
- apply_clean_names(df, mapping) returns df with unique, prefixed, snake_case names that match mapping$new_name.
- Assert no reserved words used; assert all prefixes present where required.

Implement scripts/step04_rename.R with apply_clean_names(); pure; uses mapping; throws descriptive error on mismatches. Tests pass.
```

---

## Prompt 10 — Split into visits vs adverse events; dedupe identifiers
```text
Add tests in tests/testthat/test-split.R:
- split_visits_and_ae(df) returns list(visits=..., ae=...).
- Identifier fields duplicated are removed from AE or Visits as per spec so each table has appropriate keys.
- Assert expected representative columns land in the right table.

Implement scripts/step06_split.R with split_visits_and_ae(); pure. Tests green.
```

---

## Prompt 11 — Vectorized type conversion for Visits
```text
Add tests in tests/testthat/test-types-visits.R to check:
- Dates columns are Date
- Numeric columns parse "36/41"
- Binary columns to TRUE/FALSE/NA
- Non-target columns remain character where appropriate

Implement scripts/step07_types_visits.R:
- convert_types_visits(df, date_vars, numeric_vars, binary_vars) using mutate(across()) and safe_* helpers.
Tests pass.
```

---

## Prompt 12 — Vectorized type conversion for AE
```text
Mirror the previous step with tests in tests/testthat/test-types-ae.R and implement scripts/step08_types_ae.R:
- convert_types_ae(df, date_vars, numeric_vars, binary_vars)
All tests green.
```

---

## Prompt 13 — Patient-level filling (time-invariant vars) with statistics
```text
Add integration tests in tests/testthat/test-patient-fill.R:
- Forward fill, backward fill, bidirectional fill, true missingness preserved, multi-patient independence (P001 vs P002).
- Verify no change occurs for time-variant fields.

Implement scripts/step09_fill.R:
- fill_time_invariant(visits_df, patient_id_col="id_client_id", visit_no_col="id_visit_no", time_invariant_cols)
  uses arrange/group_by/fill(.direction="downup")/ungroup.
- report_fill_stats(visits_df, time_invariant_cols) returns a tibble summary (no printing).
All tests green.
```

---

## Prompt 14 — Quality checks module
```text
Add tests in tests/testthat/test-quality.R:
- No future visit dates
- Age between 18 and 120 (when present)
- No duplicate (id_client_id, id_visit_no) combinations
- DSST cognitive variables detected by pattern
- Visit distribution table returns counts

Implement scripts/step10_quality.R with:
- qc_no_future_dates(df, date_col)
- qc_age_range(df, age_col, min=18, max=120)
- qc_no_duplicate_keys(df, keys=c("id_client_id","id_visit_no"))
- detect_dsst_vars(df) returns vector of names
All green.
```

---

## Prompt 15 — Persist outputs with secure permissions and summary stats
```text
Add tests in tests/testthat/test-persist.R:
- After save_outputs(...), files exist:
  data/visits_data.rds, data/adverse_events_data.rds, data/data_dictionary_cleaned.csv (from earlier), data/summary_statistics.rds
- Files have permissions 0600
- Re-running save_outputs produces identical content for idempotence

Implement scripts/step11_persist.R:
- save_outputs(visits, ae, mapping, stats, paths=list(...))
- chmod_0600(path) helper (platform-guarded for Windows; test by skipping perms assertion if Windows)
Implement scripts/step12_summary.R:
- build_summary_statistics(visits, mapping) returns named list per spec.
All tests green.
```

---

## Prompt 16 — Wire the main pipeline and add E2E tests
```text
Create tests in tests/testthat/test-e2e.R (single suite):
- Source scripts/01_data_cleaning.R which orchestrates:
  import -> remove sections -> mapping -> rename -> split -> type conversions -> fill -> qc -> summary -> save
- After run, assert:
  - files exist (RDS/CSV)
  - visits has id_* and domain prefixes present
  - types: id_visit_date is Date; id_age numeric; id_client_id character
  - qc: no duplicate keys; no future dates

Implement scripts/01_data_cleaning.R composing previously implemented modules. Keep it side-effect-free except for intended file I/O and chmod; no console prints. E2E tests pass.
```

---

## Prompt 17 — Pre-commit hook (PHI/PII, secrets, lint, unit tests) + docs check
```text
Add scripts/pre-commit and scripts/install_hooks.sh.

pre-commit should:
- PHI/PII grep for known patterns (e.g., "004-[0-9]{5}") on staged files; fail if found.
- Secrets grep: password|api_key|secret|token; warn/fail appropriately.
- Lint staged R files via lintr; fail on lints.
- Run a fast test subset (unit + integration) via testthat; fail on test errors.
- Warn if scripts/01_data_cleaning.R changed but docs/cleaning_report.md not updated.

Add tests that simulate a debug string or PHI in a temp staged file and assert the script would fail (documented test plan rather than executing the hook in CI). Provide README section on installing hooks.

Implement both scripts with portable bash. No interactive prompts.
```

---

## Prompt 18 — GitHub Actions CI with coverage gate
```text
Create .github/workflows/test.yml with:
- Triggers: push PR to main/develop; nightly
- Matrix: ubuntu-latest; R 4.3 and release
- Steps: checkout, setup R, install deps, run lintr (non-blocking), run tests (blocking), compute covr coverage, fail if <80%, upload coverage artifact; run oysteR security audit (informational).

Update README with CI badges placeholders and instructions. Ensure workflow uses --vanilla and minimal caching for reproducibility.
```

---

## Prompt 19 — Final wiring + README completion (usage & troubleshooting)
```text
Update README.md to include:
- System requirements
- Install packages
- Run pipeline (source('scripts/01_data_cleaning.R'))
- Outputs and their schemas
- How to run tests and generate coverage
- Troubleshooting for common issues (file not found, permissions, memory)
Link to docs/: cleaning_report.md, testing_guide.md, security_review.md, code_review_checklist.md.

Ensure no TODOs remain and no orphaned code/files exist. Re-run full test suite locally.
```
