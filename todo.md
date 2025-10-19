# TODO — Sarcopenia Data Cleaning Pipeline (TDD, Incremental, Safe-by-Default)

Use this checklist end‑to‑end. Every box should be checked with evidence (commit hashes, test output). Keep a running decision log in `docs/decision_log.md`.

---

## 0) Meta & Assumptions (be skeptical)
- [ ] Confirm spec version and location (e.g., `spec.md`) and record SHA in `docs/decision_log.md`.
- [ ] List explicit assumptions (date formats, domain patterns, time‑invariant field list) and plan tests to try to **break** them.
- [ ] Define **Definition of Done** (DoD): tests ≥80% coverage, idempotent pipeline, secure outputs (0600), CI green.
- [ ] Create `docs/decision_log.md` with sections: Context, Decision, Alternatives, Consequences.

---

## 1) Environment & Tooling
- [ ] Ensure R ≥ 4.3; install packages: `tidyverse`, `here`, `readr`, `dplyr`, `testthat`, `covr`, `lintr`.
- [ ] Initialize Git repository; set default branch (`main` or `develop`).
- [ ] Add `.gitignore` (e.g., `data/*.rds`, `data/*.csv`, `.Rhistory`, `.Rproj.user`, large tmp files).
- [ ] Verify no secrets in ENV or history (`git log -p | grep -i 'api_key\|token\|password'` should be empty).

---

## 2) Repository Scaffold (M1)
- [ ] Create directories: `scripts/`, `tests/testthat/`, `tests/fixtures/`, `docs/`, `.github/workflows/`, `data/`.
- [ ] Add `tests/testthat.R` invoking `testthat::test_dir("tests/testthat")`.
- [ ] Add `tests/testthat/test-smoke.R` (single passing smoke test).
- [ ] Add minimal `README.md` with “Run tests” command.
- [ ] Commit: “scaffold repo + smoke test”.

---

## 3) Synthetic Fixtures (No PHI)
- [ ] Build `tests/fixtures/sample_raw_data.csv` (5 patients × ≤3 visits) with representative columns:
      identifiers, cognitive, demographic, medical, physical, adherence, adverse events, and 6 **section markers**.
- [ ] Confirm all fixture values are synthetic (no real IDs/names).
- [ ] Commit: “add representative fixture csv”.

---

## 4) Helper Functions (M2)
**clean_var_name**
- [ ] Write unit tests (remove numbering, punctuation, collapse spaces, snake_case, idempotency, NULL error).
- [ ] Implement `clean_var_name()` in `scripts/helpers_cleaning.R` (pure).
- [ ] Green tests.

**safe_numeric**
- [ ] Tests: numbers, decimals, “36/41”→36, text suffix/prefix, NA, NULL error, vectorization.
- [ ] Implement `safe_numeric()` in `scripts/helpers_cast.R` (pure).
- [ ] Green tests.

**safe_date**
- [ ] Tests: `%Y-%m-%d`, `%d/%m/%Y`, `%m/%d/%Y`, NA, NULL error, vectorization.
- [ ] Implement `safe_date()` (pure, tries three formats, suppress warnings).
- [ ] Green tests.

**to_logical**
- [ ] Tests: yes/true/1→TRUE; no/false/0→FALSE; whitespace/case variants; non‑match→NA; NA; NULL error; vectorization.
- [ ] Implement `to_logical()` (pure) in `scripts/helpers_cast.R`.
- [ ] Green tests.

---

## 5) Import & Input Validation (M3)
- [ ] Tests: missing file error; oversized file (>100MB) error; valid file import as **all character**; correct dims; no factors.
- [ ] Implement `validate_input()` and `read_raw_character_tibble()` in `scripts/step01_import.R`.
- [ ] Green tests.

---

## 6) Remove Section Markers (M3→M4 bridge)
- [ ] Tests: exactly 6 known marker columns removed; integration import→remove count check.
- [ ] Implement `remove_section_markers()` in `scripts/step02_sections.R`.
- [ ] Green tests.

---

## 7) Variable Mapping (Classification + Prefix + Dedup) (M4)
- [ ] Tests: representative names mapped to sections: identifier, demographic, cognitive, medical, physical, adherence, adverse_events.
- [ ] Tests: prefixes applied: `id_`, `demo_`, `cog_`, `med_`, `phys_`, `adh_`, `ae_`.
- [ ] Tests: deterministic dedup suffixes `_2`, `_3` etc.
- [ ] Implement `classify_section()`, `build_variable_mapping()`, `write_mapping_csv()` → `data/data_dictionary_cleaned.csv`.
- [ ] Manually spot‑check 10 mappings; log edge cases in `docs/decision_log.md`.
- [ ] Green tests.

---

## 8) Apply Cleaned Names (M5)
- [ ] Tests: after renaming, all names unique, prefixed, snake_case; mapping alignment enforced; reserved words avoided.
- [ ] Implement `apply_clean_names()` in `scripts/step04_rename.R`.
- [ ] Green tests.

---

## 9) Split Visits vs Adverse Events (M6)
- [ ] Tests: `split_visits_and_ae()` returns both tibbles with expected columns.
- [ ] Tests: identifier deduplication across tables (no duplicated identifier fields where not needed).
- [ ] Implement `scripts/step06_split.R`.
- [ ] Green tests.

---

## 10) Type Conversions — Visits (M7)
- [ ] Identify date/numeric/binary columns for visits (record list in `docs/decision_log.md`).
- [ ] Tests: dates parsed; numerics handle “36/41”; binaries normalized; non‑targets unchanged.
- [ ] Implement `convert_types_visits()` in `scripts/step07_types_visits.R` using helpers and `across()`.
- [ ] Green tests.

---

## 11) Type Conversions — Adverse Events (M7 mirror)
- [ ] Identify AE date/numeric/binary columns (record in log).
- [ ] Tests mirror visits; implement `convert_types_ae()` in `scripts/step08_types_ae.R`.
- [ ] Green tests.

---

## 12) Patient-Level Fill (Time‑Invariant) (M8)
- [ ] Confirm **time‑invariant** field list (target ~54 vars) with clinicians; document list and rationale.
- [ ] Tests: forward, backward, bidirectional fill; true missingness preserved; multi‑patient isolation; time‑variant unaffected.
- [ ] Implement `fill_time_invariant()` and `report_fill_stats()` in `scripts/step09_fill.R`.
- [ ] Green tests.

---

## 13) Quality Checks Module (M9)
- [ ] Tests: no future dates; age range 18–120; no duplicate `(id_client_id, id_visit_no)`; DSST variable detection; visit distribution table.
- [ ] Implement in `scripts/step10_quality.R`:
      `qc_no_future_dates()`, `qc_age_range()`, `qc_no_duplicate_keys()`, `detect_dsst_vars()`.
- [ ] Green tests.

---

## 14) Summary Statistics (M10)
- [ ] Define required summaries per domain (counts, ranges, distributions, missingness) in `docs/decision_log.md`.
- [ ] Implement `build_summary_statistics()` in `scripts/step12_summary.R`.
- [ ] Add tests that assert key elements exist and are plausible (counts sum to N, etc.).
- [ ] Green tests.

---

## 15) Persist Outputs with Secure Permissions (M10)
- [ ] Tests: output files exist after save: `data/visits_data.rds`, `data/adverse_events_data.rds`, `data/data_dictionary_cleaned.csv`, `data/summary_statistics.rds`.
- [ ] Tests: POSIX permissions `0600` (skip perms assertion on Windows).
- [ ] Tests: idempotence (re‑run yields identical content).
- [ ] Implement `save_outputs()` and `chmod_0600()` in `scripts/step11_persist.R`.
- [ ] Green tests.

---

## 16) End‑to‑End Orchestration (M11)
- [ ] Implement `scripts/01_data_cleaning.R` orchestrating: import → remove sections → mapping → rename → split → types → fill → QC → summary → save.
- [ ] E2E tests (`tests/testthat/test-e2e.R`):
      files exist; key prefixes present; types (Date/numeric/character) as expected; no duplicate keys; no future dates.
- [ ] Green tests.

---

## 17) Pre‑commit Hooks (Security + Quality) (M12)
- [ ] Add `scripts/pre-commit` and `scripts/install_hooks.sh` (portable bash).
- [ ] Hook actions (on staged files):
      - PHI/PII grep for patterns (e.g., `004-[0-9]{5}`) → **fail** if found.
      - Secrets grep (`password|api_key|secret|token`) → warn/fail as policy.
      - Run `lintr` on staged R files → fail on lints.
      - Run unit+integration tests (fast set) → fail on test errors.
      - Warn if `scripts/01_data_cleaning.R` changed but `docs/cleaning_report.md` not updated.
- [ ] Document install steps in README.
- [ ] (Optional) Add a dry‑run test plan verifying hook behavior.
- [ ] Commit: “pre‑commit hooks for security/quality”.

---

## 18) CI/CD — GitHub Actions (M12)
- [ ] Workflow `.github/workflows/test.yml`:
      triggers push/PR; nightly; matrix ubuntu-latest with R 4.3 & release.
- [ ] Steps: checkout, setup R, install deps, run `lintr` (non‑blocking), run tests (blocking), `covr` coverage, **fail <80%**, upload coverage artifact; optional `oysteR` audit (informational).
- [ ] Add README CI badge placeholder and instructions.
- [ ] Verify CI green on PR.

---

## 19) Documentation
- [ ] `docs/cleaning_report.md` (what the pipeline does, inputs→outputs, schemas).
- [ ] `docs/testing_guide.md` (how to run tests, coverage, E2E scope).
- [ ] `docs/security_review.md` (PHI/PII threats, mitigations, hook patterns, perms).
- [ ] `docs/code_review_checklist.md` (naming, purity, tests, logs, PHI, idempotence).
- [ ] Update main `README.md` (requirements, how to run pipeline, outputs, troubleshooting).
- [ ] Commit docs.

---

## 20) Security & Privacy Verification
- [ ] Repo‑wide grep confirms no PHI, secrets, or patient identifiers in code, fixtures, or docs.
- [ ] Confirm outputs are permissioned as `0600` on POSIX.
- [ ] Verify logs/prints don’t include IDs or names (none should exist).
- [ ] Record verification steps in `docs/security_review.md`.

---

## 21) Release Candidate Checklist
- [ ] All unit/integration/E2E tests pass locally.
- [ ] Coverage ≥80% (target ~90%).
- [ ] CI green on default branch.
- [ ] Reproducible run on a clean clone (document exact commands).
- [ ] Archive artifact versions (R version, package lock/renv, workflow run ID).
- [ ] Tag release and generate CHANGELOG entry.

---

## 22) Post‑Release (Hardening)
- [ ] Add golden tests for variable mapping to catch name drift.
- [ ] Add fuzz tests for date/numeric parsing.
- [ ] Add runtime guardrails (row/col count sanity; abort on unexpected deltas).
- [ ] Schedule periodic PHI/secret scans and coverage reports.

---

## Definition of Done (reconfirm before sign‑off)
- [ ] Pipeline is deterministic and idempotent.
- [ ] All outputs generated with secure perms and validated schemas.
- [ ] No PHI/PII in repo or logs.
- [ ] Tests comprehensive; coverage gate enforced by CI.
- [ ] Documentation complete and current.
