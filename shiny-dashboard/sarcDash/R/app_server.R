#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Enable thematic for auto theming of plots
  thematic::thematic_shiny()

  # Initialize translator
  i18n <- init_i18n()

  # Reactive language value
  current_language <- reactiveVal("en")

  # Observe language changes
  observeEvent(input$language, {
    req(input$language)

    # Update translator
    i18n$set_translation_language(input$language)

    # Update reactive value
    current_language(input$language)

    # Update HTML lang and dir attributes
    js_code <- update_html_attrs(input$language)
    session$sendCustomMessage(type = "eval", message = js_code)
  }, ignoreInit = FALSE)

  # Make i18n available to modules
  session$userData$i18n <- reactive({ i18n })
  session$userData$current_language <- current_language

  # Call home module server
  mod_home_server("home", i18n = reactive({ i18n }), parent_session = session)

  # Call dictionary module server
  mod_dictionary_server("dictionary", i18n = reactive({ i18n }))
}
