# Deployment Guide - Sarcopenia Shiny App

**Last Updated:** 2025-11-02
**Target Platform:** Shinyapps.io

---

## 📋 Pre-Deployment Checklist

Before deploying to shinyapps.io, verify:

### ✅ Required Files Present

```bash
# Check essential files exist
ls -1 app.R
ls -1 data_dictionary_enhanced.csv
ls -1 inst/extdata/instrument_valid_ranges.csv
ls -1 www/custom.css
ls R/*.R
```

**Expected output:**
- `app.R` ✓
- `data_dictionary_enhanced.csv` ✓
- `inst/extdata/instrument_valid_ranges.csv` ✓
- `www/custom.css` ✓
- `R/fct_*.R`, `R/mod_*.R`, `R/utils*.R` ✓

### ❌ Test Files NOT Present

```bash
# These should NOT exist (moved to ../sarcopenia-tests-archive/)
ls test*.R 2>&1
ls -d tests/ 2>&1
```

**Expected output:**
- `No such file or directory` (this is good!)

### ✅ App Runs Locally

```bash
# Test the app locally first
Rscript -e 'shiny::runApp(port = 3838, launch.browser = FALSE)'
```

**Expected:** App should start without errors

---

## 🚀 Deployment Steps

### Option 1: Deploy from RStudio (Recommended)

1. **Open the project in RStudio**
   ```r
   # Open sarcopenia-app/app.R in RStudio
   ```

2. **Click the "Publish" button**
   - Look for blue publish icon in top-right of editor pane
   - Or go to File → Publish → Application

3. **Select Shinyapps.io**
   - Choose "Shinyapps.io" from deployment options
   - If first time, you'll need to authorize your account

4. **Configure deployment**
   - App name: `sarcopenia-app` (or your preferred name)
   - Account: Your shinyapps.io account
   - Files: rsconnect will automatically detect files using `.rscignore`

5. **Deploy!**
   - Click "Publish"
   - Wait for deployment to complete (~2-5 minutes)

### Option 2: Deploy from R Console

```r
# Load rsconnect library
library(rsconnect)

# Set account info (first time only)
rsconnect::setAccountInfo(
  name = "your-account-name",
  token = "your-token",
  secret = "your-secret"
)

# Deploy the app
rsconnect::deployApp(
  appDir = ".",
  appName = "sarcopenia-app",
  forceUpdate = TRUE
)
```

---

## 🔍 Verification After Deployment

### Check Deployed Files

After deployment, verify these files were included:

```r
# View deployment logs
rsconnect::showLogs()
```

Look for these in the deployment bundle:
- ✅ `app.R`
- ✅ `R/*.R` (all module and function files)
- ✅ `data_dictionary_enhanced.csv`
- ✅ `inst/extdata/instrument_valid_ranges.csv`
- ✅ `www/custom.css`

### Test the Live App

1. Open the deployment URL (e.g., `https://your-account.shinyapps.io/sarcopenia-app/`)
2. Upload a test CSV file
3. Click "Process Data"
4. Verify all three dashboard sections appear
5. Test patient selector dropdown
6. Test instrument selector dropdown
7. Download CSV files to verify functionality

---

## 🐛 Troubleshooting Common Issues

### Error: "Paths should be to files within the project directory"

**Cause:** Test files with absolute paths are being included in deployment

**Solution:**
```bash
# Verify test files are NOT in app directory
ls test*.R  # Should return "No such file or directory"
ls -d tests/  # Should return "No such file or directory"

# If they exist, move them to archive
mv test*.R ../sarcopenia-tests-archive/
mv tests/ ../sarcopenia-tests-archive/
```

### Error: "Module not found" or "Function not defined"

**Cause:** R/ directory is being excluded

**Solution:**
```bash
# Check .rscignore does NOT exclude R/
grep "^R/$" .rscignore

# Should return nothing
# If it returns a match, remove that line from .rscignore
```

### Error: "Data dictionary not found"

**Cause:** CSV file missing or excluded

**Solution:**
```bash
# Verify file exists
ls data_dictionary_enhanced.csv

# Check it's not excluded in .rscignore
grep "data_dictionary_enhanced.csv" .rscignore

# Should return nothing (file should NOT be excluded)
```

### Deployment Hangs or Times Out

**Cause:** Too many files or large files being uploaded

**Solution:**
```r
# Clear rsconnect cache
rsconnect::forgetDeployment()

# Try again with clean slate
rsconnect::deployApp(appDir = ".", forceUpdate = TRUE)
```

### App Crashes on Shinyapps.io

**Check logs:**
```r
# View application logs
rsconnect::showLogs()
```

**Common fixes:**
1. Verify all required packages are installed (check logs for "package not found")
2. Check data file paths are relative, not absolute
3. Ensure no `setwd()` calls in code
4. Verify no references to local file system paths

---

## 📁 File Organization

### Production Files (in `sarcopenia-app/`)

```
sarcopenia-app/
├── app.R                           # Main app file
├── .rscignore                      # Deployment exclusions
├── data_dictionary_enhanced.csv    # Required data
├── R/
│   ├── fct_cleaning.R             # Data cleaning functions
│   ├── fct_analysis.R             # Analysis functions
│   ├── fct_instrument_analysis.R  # Instrument functions
│   ├── fct_reports.R              # Report generation
│   ├── fct_visualization.R        # Visualization functions
│   ├── mod_analysis.R             # Patient surveillance module
│   ├── mod_instrument_analysis.R  # Instrument analysis module
│   ├── mod_reports.R              # Reports module
│   ├── mod_visualization.R        # Visualization module
│   ├── utils.R                    # Utility functions
│   └── utils_data_pipeline.R      # Data pipeline utils
├── inst/extdata/
│   └── instrument_valid_ranges.csv  # Clinical ranges
├── www/
│   └── custom.css                   # Custom styling
└── DEPLOYMENT.md                    # This file!
```

### Development Files (in `../sarcopenia-tests-archive/`)

```
sarcopenia-tests-archive/
├── test_*.R                  # All test scripts
├── tests/                    # Test directory
├── DIAGNOSTIC_INSTRUCTIONS.md
├── enhance_data_dictionary.R
├── fix_data_dictionary.R
├── diagnostic_column_comparison.R
├── data_dictionary_*_BACKUP.csv
└── data_dictionary_cleaned.csv
```

**Why separate?** Test files contain absolute paths (`/Users/...`) that break deployment. Moving them outside the app directory ensures they're never scanned during deployment.

---

## 🛡️ Future-Proofing Rules

**CRITICAL:** Follow these rules to prevent deployment issues:

### Rule 1: No Absolute Paths in App Directory

❌ **NEVER do this in any file within `sarcopenia-app/`:**
```r
data <- read_csv("/Users/etaycohen/Documents/Sarcopenia/data.csv")
source("/Users/etaycohen/Documents/Sarcopenia/script.R")
```

✅ **ALWAYS use relative paths or here::here():**
```r
data <- read_csv("data.csv")  # If in same directory as app.R
data <- read_csv(here::here("data", "data.csv"))  # Using here package
source("R/functions.R")  # Relative to app.R
```

### Rule 2: Test Files Go in Archive Directory

❌ **NEVER create test files in `sarcopenia-app/`:**
```bash
# BAD - will break deployment
sarcopenia-app/test_new_feature.R
```

✅ **ALWAYS create test files in archive:**
```bash
# GOOD - won't affect deployment
../sarcopenia-tests-archive/test_new_feature.R
```

### Rule 3: Update .rscignore for New File Types

When adding new file types (e.g., `.xlsx`, `.sqlite`, etc.):

1. **Test locally first**
2. **Add exclusion to .rscignore if not needed for deployment**
3. **Test deployment to staging environment**
4. **Then deploy to production**

### Rule 4: Verify Before Every Deployment

**Pre-deployment command:**
```bash
# Run this checklist before EVERY deployment
./pre-deploy-check.sh  # (create this script - see below)
```

**Create `pre-deploy-check.sh`:**
```bash
#!/bin/bash
echo "🔍 Pre-Deployment Check"
echo ""

# Check for test files
if ls test*.R 1> /dev/null 2>&1; then
    echo "❌ FAIL: test*.R files found in app directory"
    exit 1
fi

if [ -d "tests" ]; then
    echo "❌ FAIL: tests/ directory found in app directory"
    exit 1
fi

# Check for absolute paths
if grep -r "/Users/" --include="*.R" --exclude-dir=".git" . 2>/dev/null; then
    echo "❌ FAIL: Absolute paths found in R files"
    exit 1
fi

# Check essential files exist
if [ ! -f "app.R" ]; then
    echo "❌ FAIL: app.R not found"
    exit 1
fi

if [ ! -f "data_dictionary_enhanced.csv" ]; then
    echo "❌ FAIL: data_dictionary_enhanced.csv not found"
    exit 1
fi

echo "✅ PASS: All pre-deployment checks passed!"
echo "✅ Safe to deploy to shinyapps.io"
```

---

## 🔄 Updating the Deployed App

### Small Changes (Code Only)

```r
# Make your changes to app.R or R/*.R files
# Test locally
# Then redeploy
rsconnect::deployApp(appDir = ".", forceUpdate = TRUE)
```

### Large Changes (New Dependencies)

```r
# Update manifest if adding new packages
rsconnect::writeManifest()

# Then deploy
rsconnect::deployApp(appDir = ".", forceUpdate = TRUE)
```

### Data Dictionary Updates

```r
# Replace data_dictionary_enhanced.csv
# Test locally first!
# Then deploy with forceUpdate
rsconnect::deployApp(appDir = ".", forceUpdate = TRUE)
```

---

## 📞 Support & Resources

### Official Documentation
- Shinyapps.io User Guide: https://docs.posit.co/shinyapps.io/
- rsconnect Package: https://github.com/rstudio/rsconnect

### Common Commands Reference

```r
# View current deployments
rsconnect::deployments()

# Show deployment logs
rsconnect::showLogs()

# Remove a deployment
rsconnect::terminateApp("app-name")

# Forget deployment (reset)
rsconnect::forgetDeployment()

# Check app dependencies
rsconnect::appDependencies()
```

---

## ✅ Deployment Success Checklist

After deployment, verify:

- [ ] App loads without errors
- [ ] File upload works
- [ ] "Process Data" button functions
- [ ] Dashboard sections appear after processing
- [ ] Patient selector dropdown populated
- [ ] Instrument selector dropdown populated
- [ ] Tables display correctly with color coding
- [ ] Collapsible legends work
- [ ] Download buttons work
- [ ] "Start Over" button resets app
- [ ] No console errors in browser

---

**Last deployed:** [Add date here]
**Deployed by:** [Add name here]
**Deployment URL:** [Add URL here]

---

## 🔐 Security Notes

- Never commit API keys or secrets to git
- Use environment variables for sensitive data
- Review `.gitignore` to ensure secrets are excluded
- Shinyapps.io has built-in authentication if needed

---

**Remember:** Every change to the app should consider the deployment process!
