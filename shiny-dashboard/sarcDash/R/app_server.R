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

  # PHI Warning banner with last-updated info
  output$phi_banner <- renderUI({
    # Get data status (with error handling)
    status <- tryCatch({
      data_dir <- here::here("data")
      ds_status(data_dir, connect = FALSE)
    }, error = function(e) {
      NULL
    })

    # Format last updated time
    last_updated_text <- if (!is.null(status) && !is.null(status$last_modified)) {
      formatted_time <- format(status$last_modified, "%Y-%m-%d %H:%M")
      paste0(
        i18n$t("Last updated"),
        ": ",
        formatted_time
      )
    } else {
      ""
    }

    div(
      class = "alert alert-warning alert-dismissible fade show",
      role = "alert",
      tags$strong(i18n$t("PHI Warning")),
      " ",
      i18n$t("This dashboard contains protected health information. Do not share screenshots or exports."),
      if (nchar(last_updated_text) > 0) {
        tagList(
          tags$br(),
          tags$small(
            class = "text-muted",
            last_updated_text
          )
        )
      },
      tags$button(
        type = "button",
        class = "btn-close",
        `data-bs-dismiss` = "alert",
        `aria-label` = i18n$t("Close")
      )
    )
  })
}
