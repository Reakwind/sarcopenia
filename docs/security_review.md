# Security Review Checklist
## Sarcopenia Study - Data Cleaning Pipeline

**Last Review Date:** October 19, 2025
**Reviewer:** [To be filled]
**Script Version:** scripts/01_data_cleaning.R
**Review Status:** ⚠️ PENDING INITIAL REVIEW

---

## Security Assessment Summary

| Category | Status | Critical Issues | Recommendations |
|----------|--------|----------------|-----------------|
| Data Privacy (PHI/PII) | ⚠️ REVIEW | TBD | TBD |
| Input Validation | ⚠️ REVIEW | TBD | TBD |
| File System Security | ⚠️ REVIEW | TBD | TBD |
| Dependency Security | ⚠️ REVIEW | TBD | TBD |
| Code Injection Prevention | ⚠️ REVIEW | TBD | TBD |
| Logging & Audit Trail | ⚠️ REVIEW | TBD | TBD |

**Legend:** ✅ PASS | ⚠️ NEEDS REVIEW | ❌ FAIL | 🔄 IN PROGRESS

---

## 1. Data Privacy & PHI/PII Protection

### 1.1 Protected Health Information (PHI) Handling

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **No hardcoded patient identifiers** | ⬜ | Check: No patient IDs in code | Review code for hardcoded values |
| **No PHI in console output** | ⬜ | Review all `cat()` and `print()` statements | Verify no patient data printed |
| **No PHI in error messages** | ⬜ | Check error handling | Sanitize error messages |
| **No PHI in log files** | ⬜ | Review logging practices | Implement privacy-safe logging |
| **No PHI in git commits** | ⬜ | Check .gitignore coverage | Ensure data files excluded |
| **No PHI in variable names** | ⬜ | Review variable naming | Use generic names, not patient info |
| **Audit trail for data access** | ⬜ | Implement access logging | Add logging for who accessed data when |

**Current Assessment:**
```r
# Lines 01_data_cleaning.R:20, 40, 151, etc.
# CONCERN: Script outputs patient counts and data dimensions
# RISK LEVEL: LOW (aggregate data only, no individual PHI)
# ACTION: Document that console output is aggregate only
```

**Recommendations:**
1. Add header comment stating "No PHI is output to console"
2. Implement separate audit log for data access
3. Review all `cat()` statements to ensure no patient-specific data

---

### 1.2 Data De-identification

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Patient IDs are pseudonymous** | ✅ | Using codes like "004-00232" | Verify codes cannot be reverse-engineered |
| **Dates handled appropriately** | ⬜ | Check for date of birth handling | Consider date shifting if needed |
| **Free text fields reviewed** | ⬜ | Check "ae_free_text" field | Implement text sanitization |
| **Location data minimized** | ⬜ | Review address fields | Remove or generalize if not needed |

---

## 2. Input Validation

### 2.1 File Input Validation

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **File path validation** | ❌ | Line 18: `read_csv("Audit report.csv")` | Implement path validation |
| **File existence check** | ❌ | No check before reading | Add `file.exists()` check |
| **File size limits** | ❌ | No size validation | Add max file size check |
| **File type validation** | ❌ | Assumes .csv without verification | Verify file extension & MIME type |
| **Path traversal prevention** | ⬜ | Using relative path | Use `here::here()` for safe paths |

**Current Code:**
```r
# Line 18 - VULNERABILITY
raw <- read_csv("Audit report.csv", col_types = cols(.default = "c"))
# No validation of file path or existence
```

**Recommended Fix:**
```r
# Secure file reading
input_file <- here::here("Audit report.csv")

# Validate file exists
if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}

# Validate file size (max 100MB)
file_size <- file.info(input_file)$size
if (file_size > 100 * 1024^2) {
  stop("File too large: ", file_size, " bytes. Max 100MB.")
}

# Validate file extension
if (!str_detect(tolower(input_file), "\\.csv$")) {
  stop("Invalid file type. Expected .csv file.")
}

raw <- read_csv(input_file, col_types = cols(.default = "c"))
```

---

### 2.2 Data Validation

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Column count validation** | ❌ | No check for expected columns | Add expected column count check |
| **Required columns present** | ❌ | No validation of required fields | Verify key columns exist |
| **Data type validation** | ⚠️ | Reads all as character first (good) | Add post-conversion validation |
| **Range validation** | ❌ | No checks for valid ranges (age, dates) | Add domain-specific validation |
| **Duplicate check** | ❌ | No check for duplicate patient-visits | Add uniqueness validation |

**Recommended Validation Code:**
```r
# Validate expected structure
expected_cols <- c("Org ID", "Client ID", "Gender", "Age", "Visit Date")
missing_cols <- setdiff(expected_cols, names(raw))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# Validate age ranges
if (any(visits_data$id_age < 0 | visits_data$id_age > 120, na.rm = TRUE)) {
  warning("Invalid age values detected")
}

# Validate date ranges
if (any(visits_data$id_visit_date > Sys.Date(), na.rm = TRUE)) {
  warning("Future visit dates detected")
}

# Check for duplicates
duplicates <- visits_data %>%
  group_by(id_client_id, id_visit_no) %>%
  filter(n() > 1)
if (nrow(duplicates) > 0) {
  stop("Duplicate patient-visit combinations found")
}
```

---

### 2.3 SQL/Code Injection Prevention

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **No eval() of user input** | ✅ | No eval() or parse() calls | ✓ Pass |
| **No system() calls** | ✅ | No system command execution | ✓ Pass |
| **Safe regex patterns** | ✅ | All regex patterns are literals | ✓ Pass |
| **No dynamic SQL** | N/A | No database queries | ✓ Not applicable |
| **No unvalidated file operations** | ⚠️ | Need to add path validation | See section 2.1 |

---

## 3. File System Security

### 3.1 File Permissions

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Output files have restricted permissions** | ❌ | No explicit permission setting | Set 0600 (owner read/write only) |
| **No world-readable output** | ⬜ | Check default file permissions | Verify with `ls -la data/` |
| **Temporary files cleaned up** | ✅ | No temp files created | ✓ Pass |
| **Sensitive data not in /tmp** | ✅ | All output in data/ directory | ✓ Pass |

**Recommended Fix:**
```r
# After saving files, set restrictive permissions
Sys.chmod("data/visits_data.rds", mode = "0600")
Sys.chmod("data/adverse_events_data.rds", mode = "0600")
Sys.chmod("data/data_dictionary_cleaned.csv", mode = "0600")
```

---

### 3.2 Directory Traversal Prevention

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **No user-supplied paths** | ✅ | All paths are hardcoded | ✓ Pass |
| **No '../' in paths** | ✅ | Using relative paths from project root | ✓ Pass |
| **Working directory controlled** | ⚠️ | Assumes current directory | Use `here::here()` package |
| **Output directory creation safe** | ✅ | Line 477-479: Safe mkdir | ✓ Pass |

---

## 4. Dependency Security

### 4.1 Package Security

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Tidyverse version documented** | ❌ | No version specified | Add sessionInfo() to docs |
| **Known CVEs checked** | ⬜ | Need to audit dependencies | Run `oysteR` security scan |
| **Dependencies locked** | ❌ | No renv lockfile | Implement `renv` for reproducibility |
| **CRAN packages only** | ✅ | Using official CRAN packages | ✓ Pass |
| **No dev packages in production** | ✅ | No devtools/remotes usage | ✓ Pass |

**Recommended Action:**
```r
# Initialize renv for dependency locking
renv::init()
renv::snapshot()

# Document session info
writeLines(capture.output(sessionInfo()), "docs/session_info.txt")
```

---

### 4.2 Supply Chain Security

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Package integrity verified** | ⬜ | Relies on CRAN verification | Document trust in CRAN |
| **No binary packages from untrusted sources** | ✅ | Installing from CRAN only | ✓ Pass |
| **Dependency tree reviewed** | ⬜ | Need to audit transitive dependencies | List all dependencies |

---

## 5. Logging & Monitoring

### 5.1 Audit Trail

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Script execution logged** | ❌ | No execution logging | Add timestamp + user logging |
| **Data access logged** | ❌ | No audit trail | Implement access logging |
| **Errors logged** | ⚠️ | Errors print to console only | Write to log file |
| **User actions tracked** | ❌ | No user tracking | Add who/when/what logging |

**Recommended Implementation:**
```r
# Add at script start
log_file <- here::here("logs", paste0("cleaning_", Sys.Date(), ".log"))
dir.create(dirname(log_file), showWarnings = FALSE, recursive = TRUE)

log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  user <- Sys.info()["user"]
  log_line <- sprintf("[%s] [%s] [%s] %s\n", timestamp, level, user, msg)
  cat(log_line)
  cat(log_line, file = log_file, append = TRUE)
}

log_message("Data cleaning started")
log_message(paste("Input file:", input_file))
log_message(paste("Output directory:", here::here("data")))
```

---

### 5.2 Error Handling

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Graceful error handling** | ⚠️ | Some functions may fail silently | Add try-catch blocks |
| **No sensitive data in error messages** | ⬜ | Need to review all errors | Sanitize errors |
| **Errors logged, not just printed** | ❌ | Errors go to console only | Implement error logging |

---

## 6. Data Retention & Disposal

| Check Item | Status | Notes | Action Required |
|------------|--------|-------|-----------------|
| **Data retention policy documented** | ❌ | No policy | Create retention policy document |
| **Secure deletion procedure** | ❌ | No secure delete function | Document how to securely delete data |
| **Backup security** | ⬜ | Need to verify backup encryption | Check GitHub repo security settings |
| **Old versions cleaned up** | ⬜ | Git history contains all versions | Document git history management |

---

## 7. Compliance & Regulations

### 7.1 Regulatory Compliance

| Regulation | Applicable | Status | Notes |
|------------|-----------|--------|-------|
| **HIPAA** | Yes (if US data) | ⚠️ | Need to verify compliance |
| **GDPR** | Possible (if EU patients) | ⚠️ | Need to verify |
| **21 CFR Part 11** | Possible (if FDA study) | ⬜ | Determine if applicable |
| **IRB Requirements** | Yes | ⬜ | Verify IRB approval covers data handling |

**Action Required:** Determine regulatory requirements and document compliance measures

---

## 8. Vulnerability Summary

### Critical Vulnerabilities (Fix Immediately)

1. ❌ **No input file validation** (Section 2.1)
   - Missing file existence/size/type checks
   - Risk: Script could fail or behave unexpectedly
   - Fix: Add comprehensive validation (see recommended code)

2. ❌ **No output file permissions set** (Section 3.1)
   - Output files may be world-readable
   - Risk: PHI exposure on shared systems
   - Fix: Set mode 0600 on all output files

3. ❌ **No audit logging** (Section 5.1)
   - No record of who accessed data when
   - Risk: Cannot track data access for compliance
   - Fix: Implement logging system

### High Priority (Fix Soon)

4. ⚠️ **No dependency locking** (Section 4.1)
   - Script behavior may change with package updates
   - Risk: Reproducibility and potential security issues
   - Fix: Implement renv

5. ⚠️ **Limited error handling** (Section 5.2)
   - Some operations may fail silently
   - Risk: Data corruption or incomplete processing
   - Fix: Add try-catch blocks and validation

### Medium Priority (Address in Next Update)

6. ⚠️ **No data validation** (Section 2.2)
   - No checks for valid ranges or required fields
   - Risk: Processing invalid data
   - Fix: Add domain-specific validation

---

## 9. Security Recommendations

### Immediate Actions

1. **Add Input Validation:**
   ```r
   # Add to beginning of script
   source("scripts/validate_input.R")
   validate_input_file("Audit report.csv")
   ```

2. **Set File Permissions:**
   ```r
   # Add after each saveRDS()
   Sys.chmod(output_file, mode = "0600")
   ```

3. **Implement Logging:**
   ```r
   source("scripts/audit_logger.R")
   log_data_access("01_data_cleaning.R", "started")
   ```

### Long-term Improvements

1. Implement `renv` for dependency management
2. Create secure data deletion procedure
3. Add automated security scanning to CI/CD
4. Conduct regular security audits
5. Document data retention and disposal policies

---

## 10. Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| **Developer** | | | |
| **Security Reviewer** | | | |
| **Data Privacy Officer** | | | |
| **Principal Investigator** | | | |

---

## Appendix A: Security Testing Commands

```r
# Check file permissions
system("ls -la data/")

# Audit R package versions
sessionInfo()

# Check for known vulnerabilities
install.packages("oysteR")
oysteR::audit_installed_r_pkgs()

# Test input validation
testthat::test_file("tests/testthat/test-security.R")
```

---

## Appendix B: Incident Response

If a security incident is discovered:

1. **Immediately:**
   - Stop the script
   - Document the issue
   - Notify the security team

2. **Within 24 hours:**
   - Assess impact
   - Determine if PHI was exposed
   - Notify appropriate parties (IRB, DPO)

3. **Within 72 hours:**
   - Implement fix
   - Test fix
   - Document remediation
   - Update security review

---

**Review Frequency:** Quarterly or after any major code changes
**Next Review Due:** January 19, 2026
**Document Version:** 1.0
