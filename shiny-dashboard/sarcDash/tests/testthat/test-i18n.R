# Unit tests for i18n_helpers.R

# Load the i18n helpers
source("../../R/i18n_helpers.R")

# Test 1: is_rtl function
test_that("is_rtl correctly identifies RTL languages", {
  expect_true(is_rtl("he"))
  expect_true(is_rtl("ar"))
  expect_true(is_rtl("fa"))
  expect_true(is_rtl("HE"))  # Case insensitive

  expect_false(is_rtl("en"))
  expect_false(is_rtl("fr"))
  expect_false(is_rtl("es"))
  expect_false(is_rtl("EN"))
})

# Test 2: get_language_name function
test_that("get_language_name returns correct display names", {
  expect_equal(get_language_name("en"), "English")
  expect_equal(get_language_name("he"), "עברית")

  # Unknown language returns the code itself
  expect_equal(get_language_name("unknown"), "unknown")
})

# Test 3: Translation file exists
test_that("Translation file exists and is valid JSON", {
  json_path <- "../../inst/i18n/translations.json"

  expect_true(file.exists(json_path))

  # Try to read and parse JSON
  json_content <- jsonlite::read_json(json_path)

  expect_type(json_content, "list")
  expect_true("languages" %in% names(json_content))
  expect_true("translation" %in% names(json_content))

  # Check languages
  expect_true("en" %in% json_content$languages)
  expect_true("he" %in% json_content$languages)

  # Check translations structure
  expect_true(length(json_content$translation) > 0)

  # Each translation should have "en" and "he" keys
  first_translation <- json_content$translation[[1]]
  expect_true("en" %in% names(first_translation))
  expect_true("he" %in% names(first_translation))
})

# Test 4: Key translations exist
test_that("Essential UI string keys exist in translations", {
  json_path <- "../../inst/i18n/translations.json"
  json_content <- jsonlite::read_json(json_path)

  # Extract all EN strings
  en_strings <- sapply(json_content$translation, function(x) x$en)

  # Check for essential keys
  essential_keys <- c(
    "Home",
    "Data Dictionary",
    "Cohort Builder",
    "Demographics",
    "Cognitive",
    "Medical",
    "Physical",
    "Adherence",
    "Adverse Events",
    "Longitudinal",
    "Quality Checks",
    "Settings",
    "Language",
    "English",
    "Hebrew",
    "Loading...",
    "Search",
    "Filter",
    "Export"
  )

  for (key in essential_keys) {
    expect_true(
      key %in% en_strings,
      info = paste("Key missing:", key)
    )
  }
})

# Test 5: Hebrew translations are present
test_that("Hebrew translations exist for all English strings", {
  json_path <- "../../inst/i18n/translations.json"
  json_content <- jsonlite::read_json(json_path)

  # Check each translation has both languages
  for (i in seq_along(json_content$translation)) {
    translation <- json_content$translation[[i]]

    expect_true(
      !is.null(translation$en) && nchar(translation$en) > 0,
      info = paste("Missing EN for translation", i)
    )

    expect_true(
      !is.null(translation$he) && nchar(translation$he) > 0,
      info = paste("Missing HE for translation", i)
    )
  }
})

# Test 6: get_rtl_css returns valid CSS
test_that("get_rtl_css returns CSS string", {
  css <- get_rtl_css()

  expect_type(css, "character")
  expect_true(nchar(css) > 0)

  # Check for key RTL selectors
  expect_match(css, "html\\[dir='rtl'\\]")
  expect_match(css, "direction: rtl")
  expect_match(css, "text-align: right")
})

# Test 7: rtl_css_tag creates proper Shiny tag
test_that("rtl_css_tag creates a tags$style element", {
  css_tag <- rtl_css_tag()

  expect_s3_class(css_tag, "shiny.tag")
  expect_equal(css_tag$name, "style")

  # Check content includes RTL CSS
  css_content <- as.character(css_tag$children[[1]])
  expect_match(css_content, "html\\[dir='rtl'\\]")
})

# Test 8: update_html_attrs generates correct JavaScript
test_that("update_html_attrs generates JavaScript for lang/dir", {
  # Test English (LTR)
  js_en <- update_html_attrs("en")

  expect_type(js_en, "character")
  expect_match(js_en, "setAttribute\\('lang', 'en'\\)")
  expect_match(js_en, "setAttribute\\('dir', 'ltr'\\)")

  # Test Hebrew (RTL)
  js_he <- update_html_attrs("he")

  expect_match(js_he, "setAttribute\\('lang', 'he'\\)")
  expect_match(js_he, "setAttribute\\('dir', 'rtl'\\)")
})

# Test 9: language_selector_ui creates proper input
test_that("language_selector_ui creates a selectInput", {
  # Without i18n
  selector <- language_selector_ui("test_lang", selected = "en")

  expect_s3_class(selector, "shiny.tag")

  # Check it's a select input
  html_str <- as.character(selector)
  expect_match(html_str, "select")
  expect_match(html_str, "test_lang")
})

# Test 10: init_i18n function
test_that("init_i18n creates a Translator object", {
  # Skip if shiny.i18n is not installed
  skip_if_not_installed("shiny.i18n")

  translator <- init_i18n()

  expect_s3_class(translator, "Translator")

  # Check languages
  available_langs <- translator$get_languages()
  expect_true("en" %in% available_langs)
  expect_true("he" %in% available_langs)
})

# Test 11: t_ function with translator
test_that("t_ wrapper function works", {
  skip_if_not_installed("shiny.i18n")

  # Create translator
  i18n <- init_i18n()
  i18n$set_translation_language("en")

  # Test with translator
  result <- t_("Home", i18n)
  expect_equal(result, "Home")

  # Change to Hebrew
  i18n$set_translation_language("he")
  result_he <- t_("Home", i18n)
  expect_equal(result_he, "בית")
})

# Test 12: t_ fallback without translator
test_that("t_ falls back gracefully without translator", {
  # Without i18n object, should return key
  result <- t_("Some Key")
  expect_equal(result, "Some Key")
})

# Test 13: Translations are not empty
test_that("No empty translations", {
  json_path <- "../../inst/i18n/translations.json"
  json_content <- jsonlite::read_json(json_path)

  for (i in seq_along(json_content$translation)) {
    translation <- json_content$translation[[i]]

    expect_false(
      is.null(translation$en) || translation$en == "",
      info = paste("Empty EN translation at index", i)
    )

    expect_false(
      is.null(translation$he) || translation$he == "",
      info = paste("Empty HE translation at index", i)
    )
  }
})

# Test 14: No duplicate keys
test_that("No duplicate English keys", {
  json_path <- "../../inst/i18n/translations.json"
  json_content <- jsonlite::read_json(json_path)

  en_strings <- sapply(json_content$translation, function(x) x$en)

  duplicates <- en_strings[duplicated(en_strings)]

  expect_equal(
    length(duplicates),
    0,
    info = paste("Duplicate keys found:", paste(duplicates, collapse = ", "))
  )
})

# Test 15: RTL CSS covers key components
test_that("RTL CSS includes key component selectors", {
  css <- get_rtl_css()

  # Key components that need RTL support
  components <- c(
    "navbar",
    "sidebar",
    "btn",
    "form-control",
    "table",
    "card",
    "alert",
    "plotly",
    "reactable"
  )

  for (component in components) {
    expect_match(
      css,
      component,
      info = paste("RTL CSS missing for:", component)
    )
  }
})

# Test 16: Accessibility - lang and dir attributes
test_that("HTML attributes update includes both lang and dir", {
  js_code <- update_html_attrs("he")

  # Should set both attributes
  expect_match(js_code, "setAttribute\\('lang'")
  expect_match(js_code, "setAttribute\\('dir'")

  # Should target documentElement (html tag)
  expect_match(js_code, "documentElement")
})

# Test 17: %or% operator works
test_that("%or% null coalescing operator works", {
  expect_equal(NULL %or% "default", "default")
  expect_equal("value" %or% "default", "value")
  expect_equal(0 %or% "default", 0)
  expect_equal(FALSE %or% "default", FALSE)
})

# Test 18: Translation count
test_that("Sufficient translations provided", {
  json_path <- "../../inst/i18n/translations.json"
  json_content <- jsonlite::read_json(json_path)

  # Should have at least 100 translations for comprehensive coverage
  expect_gte(
    length(json_content$translation),
    100
  )
})
