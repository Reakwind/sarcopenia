# Code Review Checklist
## Sarcopenia Study - Quality Standards for R Code

**Version:** 1.0
**Last Updated:** October 19, 2025
**Purpose:** Ensure all code meets quality, security, and maintainability standards before commit

---

## How to Use This Checklist

1. **Self-Review:** Developer completes checklist before submitting PR
2. **Peer Review:** Second reviewer validates each item
3. **Scoring:** Each category scored 1-5 (see scoring guide below)
4. **Minimum Passing Score:** 4.0/5.0 average across all categories
5. **Blocking Issues:** Any item marked "CRITICAL" must pass (5/5)

### Scoring Guide
- **5/5:** Excellent - Exceeds standards
- **4/5:** Good - Meets all standards
- **3/5:** Acceptable - Minor improvements needed
- **2/5:** Needs Work - Significant issues
- **1/5:** Fails - Must be fixed before merge

---

## 1. Code Style & Conventions (Weight: 1x)

### Tidyverse Style Guide Compliance

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Variables use snake_case** | ⬜ | `my_variable` not `myVariable` | CRITICAL |
| **Functions use snake_case** | ⬜ | `clean_data()` not `cleanData()` | CRITICAL |
| **Constants use SCREAMING_SNAKE_CASE** | ⬜ | `MAX_FILE_SIZE` | HIGH |
| **Line length ≤ 80 characters** | ⬜ | Break long lines | MEDIUM |
| **Consistent indentation (2 spaces)** | ⬜ | No tabs | CRITICAL |
| **Space after commas** | ⬜ | `c(1, 2, 3)` not `c(1,2,3)` | MEDIUM |
| **Space around operators** | ⬜ | `x <- y + 1` not `x<-y+1` | MEDIUM |
| **Pipe formatting correct** | ⬜ | New line after `%>%` | HIGH |

**Tools:** Run `lintr::lint()` on all R files

**Example - Good:**
```r
clean_patient_data <- function(input_file, output_dir) {
  data <- read_csv(input_file) %>%
    select(patient_id, visit_date, age) %>%
    filter(age >= 18) %>%
    mutate(age_group = cut(age, breaks = c(0, 30, 50, 70, Inf)))

  return(data)
}
```

**Example - Bad:**
```r
cleanPatientData<-function(inputFile,outputDir){
data<-read_csv(inputFile)%>%select(patient_id,visit_date,age)%>%filter(age>=18)%>%mutate(age_group=cut(age,breaks=c(0,30,50,70,Inf)))
return(data)}
```

**Category Score:** _____ / 5

---

## 2. Documentation (Weight: 2x)

### Function Documentation

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **All functions have roxygen2 comments** | ⬜ | `#'` style comments | CRITICAL |
| **@param documented for all parameters** | ⬜ | Including types | CRITICAL |
| **@return documented** | ⬜ | What does function return? | CRITICAL |
| **@examples provided** | ⬜ | Show usage | HIGH |
| **Complex logic explained** | ⬜ | Why, not just what | HIGH |
| **Assumptions documented** | ⬜ | e.g., "Assumes sorted data" | HIGH |
| **Edge cases noted** | ⬜ | How are NAs handled? | HIGH |

**Example - Good:**
```r
#' Convert variable names to clean snake_case format
#'
#' Removes reference numbers, question numbers, and special characters
#' from variable names. Converts to lowercase snake_case.
#'
#' @param name Character vector of variable names to clean
#'
#' @return Character vector of cleaned variable names
#'
#' @examples
#' clean_var_name("15. Number of education years - 230")
#' # Returns: "number_of_education_years"
#'
#' clean_var_name(c("Var1", "Var-2", "VAR_3"))
#' # Returns: c("var1", "var_2", "var_3")
#'
#' @details
#' Assumes input is non-NULL character vector. Returns empty string
#' for whitespace-only input. Multiple underscores are collapsed to one.
clean_var_name <- function(name) {
  # Implementation...
}
```

### Code Comments

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Section headers present** | ⬜ | Use `# ===` style | HIGH |
| **Complex logic explained** | ⬜ | Why this approach? | CRITICAL |
| **TODOs clearly marked** | ⬜ | `# TODO: description` | MEDIUM |
| **No commented-out code** | ⬜ | Delete, don't comment | HIGH |
| **Comments add value** | ⬜ | Explain "why" not "what" | HIGH |

**Category Score:** _____ / 5 (Doubled: _____/10)

---

## 3. Code Quality (Weight: 2x)

### Design Principles

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **DRY principle followed** | ⬜ | No duplicate code | CRITICAL |
| **Single Responsibility Principle** | ⬜ | Functions do one thing | CRITICAL |
| **Functions are pure when possible** | ⬜ | Same input → same output | HIGH |
| **Appropriate abstraction level** | ⬜ | Not too general or specific | MEDIUM |
| **Clear separation of concerns** | ⬜ | Data, logic, presentation separate | HIGH |

### Function Quality

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Functions < 50 lines** | ⬜ | Break up long functions | HIGH |
| **< 4 parameters per function** | ⬜ | Use lists if more needed | MEDIUM |
| **Descriptive function names** | ⬜ | Name describes what it does | CRITICAL |
| **No magic numbers** | ⬜ | Use named constants | HIGH |
| **Default parameters used appropriately** | ⬜ | Sensible defaults | MEDIUM |

### Data Handling

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Proper use of pipes** | ⬜ | `%>%` chains readable | HIGH |
| **Vectorized operations preferred** | ⬜ | Avoid loops when possible | HIGH |
| **No unnecessary data copies** | ⬜ | Memory efficient | MEDIUM |
| **Appropriate use of select/filter** | ⬜ | Tidy principles followed | HIGH |
| **Joins used correctly** | ⬜ | Correct join type | HIGH |

**Category Score:** _____ / 5 (Doubled: _____/10)

---

## 4. Error Handling & Validation (Weight: 2x)

### Input Validation

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **All inputs validated** | ⬜ | Check types, ranges, nulls | CRITICAL |
| **Meaningful error messages** | ⬜ | User can understand & fix | CRITICAL |
| **Stop on invalid input** | ⬜ | Use `stop()` or `stopifnot()` | CRITICAL |
| **Warnings for edge cases** | ⬜ | Use `warning()` appropriately | HIGH |
| **File existence checked** | ⬜ | Before reading files | CRITICAL |

### Error Handling

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Try-catch used where appropriate** | ⬜ | `tryCatch()` for external ops | HIGH |
| **Errors logged** | ⬜ | Not just printed | HIGH |
| **Graceful degradation** | ⬜ | Fails safely | HIGH |
| **No silent failures** | ⬜ | Always notify user of issues | CRITICAL |
| **Rollback on failure** | ⬜ | Cleanup partial operations | MEDIUM |

**Example - Good:**
```r
read_patient_data <- function(file_path) {
  # Validate inputs
  stopifnot(is.character(file_path))
  stopifnot(length(file_path) == 1)

  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Safe file reading with error handling
  tryCatch({
    data <- read_csv(file_path, col_types = cols(.default = "c"))

    # Validate output
    if (nrow(data) == 0) {
      warning("Empty dataset read from: ", file_path)
    }

    return(data)
  },
  error = function(e) {
    stop("Failed to read file ", file_path, ": ", e$message)
  })
}
```

**Category Score:** _____ / 5 (Doubled: _____/10)

---

## 5. Testing (Weight: 2x)

### Test Coverage

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **All functions have unit tests** | ⬜ | testthat tests exist | CRITICAL |
| **Edge cases tested** | ⬜ | NULL, NA, empty, etc. | CRITICAL |
| **Happy path tested** | ⬜ | Normal operation works | CRITICAL |
| **Error conditions tested** | ⬜ | Errors thrown correctly | HIGH |
| **Code coverage ≥ 80%** | ⬜ | Run `covr::package_coverage()` | HIGH |

### Test Quality

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Tests are independent** | ⬜ | Can run in any order | CRITICAL |
| **Tests are repeatable** | ⬜ | Same result every time | CRITICAL |
| **Test names are descriptive** | ⬜ | Describe what's being tested | HIGH |
| **Assertions are specific** | ⬜ | Test one thing per test | HIGH |
| **Test data is realistic** | ⬜ | Represents actual use cases | MEDIUM |

**Category Score:** _____ / 5 (Doubled: _____/10)

---

## 6. Security (Weight: 3x)

### Data Security

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **No hardcoded secrets** | ⬜ | No passwords, keys, etc. | CRITICAL |
| **No PHI in logs/console** | ⬜ | Patient data protected | CRITICAL |
| **Input sanitization** | ⬜ | Prevent injection attacks | CRITICAL |
| **File paths validated** | ⬜ | No path traversal | CRITICAL |
| **Safe file permissions** | ⬜ | Restrictive permissions set | HIGH |

### Code Security

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **No eval() of user input** | ⬜ | Avoid dynamic code execution | CRITICAL |
| **No system() calls** | ⬜ | Or validate carefully | CRITICAL |
| **Dependencies are trusted** | ⬜ | From CRAN only | HIGH |
| **No SQL injection risks** | ⬜ | If using databases | HIGH |
| **Secure random numbers** | ⬜ | Use secure RNG if needed | MEDIUM |

**Category Score:** _____ / 5 (Tripled: _____/15)

---

## 7. Performance (Weight: 1x)

### Efficiency

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Vectorized operations used** | ⬜ | Avoid for loops | HIGH |
| **No unnecessary data copies** | ⬜ | Memory efficient | MEDIUM |
| **Efficient algorithms** | ⬜ | Appropriate complexity | MEDIUM |
| **Progress indicators for long ops** | ⬜ | User feedback | LOW |
| **Large datasets handled** | ⬜ | Chunking if needed | MEDIUM |

### Optimization

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **No premature optimization** | ⬜ | Readable > fast (usually) | MEDIUM |
| **Bottlenecks profiled** | ⬜ | Use `profvis` if slow | LOW |
| **Parallel processing when appropriate** | ⬜ | For large operations | LOW |

**Category Score:** _____ / 5

---

## 8. Maintainability (Weight: 1x)

### Code Organization

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Logical file structure** | ⬜ | Related code together | HIGH |
| **Configuration separate from logic** | ⬜ | Use config files | HIGH |
| **No global variables** | ⬜ | Explicit parameters | HIGH |
| **Consistent naming conventions** | ⬜ | Across entire codebase | HIGH |
| **Version control best practices** | ⬜ | Meaningful commits | MEDIUM |

### Readability

| Item | Score (1-5) | Notes | Priority |
|------|-------------|-------|----------|
| **Code is self-documenting** | ⬜ | Clear variable/function names | HIGH |
| **Appropriate whitespace** | ⬜ | Visual grouping | MEDIUM |
| **Consistent style** | ⬜ | Matches project style | HIGH |
| **No overly clever code** | ⬜ | Straightforward solutions | HIGH |

**Category Score:** _____ / 5

---

## Final Score Calculation

| Category | Weight | Score (/5) | Weighted Score |
|----------|--------|------------|----------------|
| 1. Code Style & Conventions | 1x | _____ | _____ |
| 2. Documentation | 2x | _____ | _____ |
| 3. Code Quality | 2x | _____ | _____ |
| 4. Error Handling & Validation | 2x | _____ | _____ |
| 5. Testing | 2x | _____ | _____ |
| 6. Security | 3x | _____ | _____ |
| 7. Performance | 1x | _____ | _____ |
| 8. Maintainability | 1x | _____ | _____ |
| **Total** | **14x** | | **_____ / 70** |

**Average Score:** _____ / 5.0

### Pass/Fail Criteria

- ✅ **PASS:** Average ≥ 4.0/5.0 AND all CRITICAL items = 5/5
- ⚠️ **CONDITIONAL PASS:** Average ≥ 3.5/5.0, minor issues only
- ❌ **FAIL:** Average < 3.5/5.0 OR any CRITICAL item < 5/5

**Result:** ⬜ PASS | ⬜ CONDITIONAL PASS | ⬜ FAIL

---

## Action Items

### Issues Found (List all items < 4/5)

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Required Changes Before Merge

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Recommended Improvements (Non-blocking)

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

---

## Sign-off

| Role | Name | Date | Signature | Decision |
|------|------|------|-----------|----------|
| **Author** | | | | |
| **Reviewer 1** | | | | ⬜ Approve ⬜ Request Changes |
| **Reviewer 2** | | | | ⬜ Approve ⬜ Request Changes |
| **Lead** | | | | ⬜ Approve ⬜ Reject |

---

## Appendix: Automated Checks

Run these before requesting review:

```r
# Style check
lintr::lint("scripts/01_data_cleaning.R")

# Test coverage
covr::package_coverage()

# Security audit
oysteR::audit_installed_r_pkgs()

# Documentation check
devtools::document()
devtools::check()
```

---

**Document Version:** 1.0
**Review Frequency:** With every pull request
**Last Updated:** October 19, 2025
