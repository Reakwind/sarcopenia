#' Internationalization Helpers
#'
#' @description
#' Functions to manage bilingual UI (English/Hebrew) with RTL support.
#'
#' @name i18n_helpers
NULL

#' Initialize i18n translator
#'
#' @description
#' Creates a shiny.i18n::Translator object configured for EN/HE translations.
#'
#' @return A Translator object
#' @export
#'
#' @examples
#' \dontrun{
#' i18n <- init_i18n()
#' i18n$set_translation_language("he")
#' i18n$t("Home")  # Returns "בית"
#' }
init_i18n <- function() {
  translation_json_path <- system.file("i18n/translations.json", package = "sarcDash")

  if (!file.exists(translation_json_path) || translation_json_path == "") {
    # Fallback to relative path for development
    translation_json_path <- "inst/i18n/translations.json"
  }

  if (!file.exists(translation_json_path)) {
    # Try from tests directory
    translation_json_path <- "../../inst/i18n/translations.json"
  }

  if (!file.exists(translation_json_path)) {
    stop("Translation file not found. Expected at: inst/i18n/translations.json",
         call. = FALSE)
  }

  shiny.i18n::Translator$new(translation_json_path = translation_json_path)
}

#' Translation wrapper function
#'
#' @description
#' Convenience wrapper around i18n$t() for cleaner code.
#' This function should be used within reactive contexts where
#' the i18n object is available.
#'
#' @param key Character string key to translate
#' @param i18n Translator object (optional, can be pulled from session)
#'
#' @return Translated string
#' @export
#'
#' @examples
#' \dontrun{
#' # In UI
#' t_("Home", i18n)
#'
#' # With reactive translator
#' output$text <- renderText({
#'   t_("Welcome", i18n())
#' })
#' }
t_ <- function(key, i18n = NULL) {
  if (is.null(i18n)) {
    # Try to get from calling environment
    i18n <- tryCatch(
      get("i18n", envir = parent.frame()),
      error = function(e) NULL
    )
  }

  if (is.null(i18n)) {
    # Fallback to English
    return(key)
  }

  # Use the translator
  i18n$t(key)
}

#' Get RTL direction for language
#'
#' @description
#' Returns whether a language code uses RTL (right-to-left) direction.
#'
#' @param lang_code Character language code (e.g., "en", "he")
#'
#' @return Logical TRUE if RTL, FALSE otherwise
#' @export
#'
#' @examples
#' is_rtl("he")  # TRUE
#' is_rtl("en")  # FALSE
is_rtl <- function(lang_code) {
  rtl_languages <- c("he", "ar", "fa", "ur", "yi")
  tolower(lang_code) %in% rtl_languages
}

#' Get language display name
#'
#' @description
#' Returns the display name for a language code in that language.
#'
#' @param lang_code Character language code
#'
#' @return Character display name
#' @export
#'
#' @examples
#' get_language_name("en")  # "English"
#' get_language_name("he")  # "עברית"
get_language_name <- function(lang_code) {
  names <- list(
    en = "English",
    he = "עברית"
  )

  names[[lang_code]] %or% lang_code
}

#' Null coalescing operator
#'
#' @param x Value to check
#' @param y Default value if x is NULL
#' @return x if not NULL, otherwise y
#' @keywords internal
`%or%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Create language selector UI
#'
#' @description
#' Creates a dropdown selector for language choice with proper styling.
#'
#' @param inputId Input ID for the selector
#' @param selected Initially selected language code
#' @param i18n Translator object for label translation
#'
#' @return Shiny UI element (selectInput)
#' @export
#'
#' @examples
#' \dontrun{
#' language_selector_ui("lang", selected = "en", i18n = i18n)
#' }
language_selector_ui <- function(inputId, selected = "en", i18n = NULL) {
  choices <- list(
    "English" = "en",
    "עברית" = "he"
  )

  label <- if (!is.null(i18n)) i18n$t("Language") else "Language"

  shiny::selectInput(
    inputId = inputId,
    label = label,
    choices = choices,
    selected = selected,
    width = "150px"
  )
}

#' Create RTL toggle UI
#'
#' @description
#' Creates a switch/checkbox for toggling RTL layout.
#' Note: This is primarily for debugging. RTL should automatically
#' activate when Hebrew is selected.
#'
#' @param inputId Input ID for the toggle
#' @param label Label text
#' @param value Initial value (TRUE/FALSE)
#'
#' @return Shiny UI element (checkboxInput)
#' @keywords internal
rtl_toggle_ui <- function(inputId, label = "RTL Mode", value = FALSE) {
  shiny::checkboxInput(
    inputId = inputId,
    label = label,
    value = value
  )
}

#' Get RTL CSS styles
#'
#' @description
#' Returns CSS rules for RTL layout support.
#'
#' @return Character string of CSS
#' @export
#'
#' @examples
#' get_rtl_css()
get_rtl_css <- function() {
  "
  /* RTL Layout Adjustments */
  html[dir='rtl'] {
    direction: rtl;
  }

  html[dir='rtl'] body {
    text-align: right;
  }

  /* Navbar RTL */
  html[dir='rtl'] .navbar-nav {
    flex-direction: row-reverse;
  }

  html[dir='rtl'] .navbar-brand {
    margin-right: 0;
    margin-left: 1rem;
  }

  /* Sidebar RTL */
  html[dir='rtl'] .sidebar {
    border-right: none;
    border-left: 1px solid #dee2e6;
  }

  /* Buttons and Icons RTL */
  html[dir='rtl'] .btn {
    text-align: right;
  }

  html[dir='rtl'] .btn i,
  html[dir='rtl'] .btn svg {
    margin-left: 0.5rem;
    margin-right: 0;
  }

  /* Form controls RTL */
  html[dir='rtl'] .form-control,
  html[dir='rtl'] .form-select {
    text-align: right;
  }

  /* Tables RTL */
  html[dir='rtl'] table {
    direction: rtl;
    text-align: right;
  }

  html[dir='rtl'] th,
  html[dir='rtl'] td {
    text-align: right;
  }

  /* Cards RTL */
  html[dir='rtl'] .card {
    text-align: right;
  }

  /* Alerts RTL */
  html[dir='rtl'] .alert {
    text-align: right;
  }

  /* Flexbox RTL */
  html[dir='rtl'] .d-flex {
    flex-direction: row-reverse;
  }

  /* Padding/Margin RTL swaps */
  html[dir='rtl'] .ps-1 { padding-left: 0 !important; padding-right: 0.25rem !important; }
  html[dir='rtl'] .ps-2 { padding-left: 0 !important; padding-right: 0.5rem !important; }
  html[dir='rtl'] .ps-3 { padding-left: 0 !important; padding-right: 1rem !important; }
  html[dir='rtl'] .pe-1 { padding-right: 0 !important; padding-left: 0.25rem !important; }
  html[dir='rtl'] .pe-2 { padding-right: 0 !important; padding-left: 0.5rem !important; }
  html[dir='rtl'] .pe-3 { padding-right: 0 !important; padding-left: 1rem !important; }

  html[dir='rtl'] .ms-1 { margin-left: 0 !important; margin-right: 0.25rem !important; }
  html[dir='rtl'] .ms-2 { margin-left: 0 !important; margin-right: 0.5rem !important; }
  html[dir='rtl'] .ms-3 { margin-left: 0 !important; margin-right: 1rem !important; }
  html[dir='rtl'] .me-1 { margin-right: 0 !important; margin-left: 0.25rem !important; }
  html[dir='rtl'] .me-2 { margin-right: 0 !important; margin-left: 0.5rem !important; }
  html[dir='rtl'] .me-3 { margin-right: 0 !important; margin-left: 1rem !important; }

  /* Plotly RTL */
  html[dir='rtl'] .plotly .gtitle {
    text-anchor: end;
  }

  /* Reactable RTL */
  html[dir='rtl'] .reactable {
    direction: rtl;
  }

  html[dir='rtl'] .reactable-header,
  html[dir='rtl'] .reactable-cell {
    text-align: right;
  }
  "
}

#' Insert RTL CSS into app
#'
#' @description
#' Creates a tags$style element with RTL CSS rules.
#'
#' @return Shiny tags$style element
#' @export
#'
#' @examples
#' \dontrun{
#' # In app_ui
#' shiny::tags$head(
#'   rtl_css_tag()
#' )
#' }
rtl_css_tag <- function() {
  shiny::tags$style(shiny::HTML(get_rtl_css()))
}

#' Update HTML lang and dir attributes
#'
#' @description
#' JavaScript code to update the html lang and dir attributes dynamically.
#' This should be called when language changes.
#'
#' @param lang_code Language code (e.g., "en", "he")
#'
#' @return Character string of JavaScript code
#' @export
#'
#' @examples
#' \dontrun{
#' # In observer
#' observeEvent(input$language, {
#'   shinyjs::runjs(update_html_attrs(input$language))
#' })
#' }
update_html_attrs <- function(lang_code) {
  is_rtl_lang <- is_rtl(lang_code)
  dir_value <- if (is_rtl_lang) "rtl" else "ltr"

  sprintf(
    "document.documentElement.setAttribute('lang', '%s');
     document.documentElement.setAttribute('dir', '%s');",
    lang_code,
    dir_value
  )
}
