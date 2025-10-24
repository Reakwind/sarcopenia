# ============================================================================
# REPORTS TAB SHINY MODULE
# ============================================================================
#
# Shiny module for report generation tab
# Provides UI and server logic for generating and downloading reports
#
# SAFE TO MODIFY - Module pattern keeps code organized
# ============================================================================

#' Reports Module UI
#'
#' Creates the UI for the reports tab
#'
#' @param id Module namespace ID
#' @return Shiny UI
#' @export
mod_reports_ui <- function(id) {
  ns <- NS(id)

  # TODO: Build reports tab UI
  # Example structure:
  tagList(
    card(
      card_header("Report Generation"),
      p("Report generation features will be added here"),
      p("Use functions from fct_reports.R")
    )
  )
}


#' Reports Module Server
#'
#' Server logic for reports tab
#'
#' @param id Module namespace ID
#' @param cleaned_data Reactive value containing cleaned data
#' @export
mod_reports_server <- function(id, cleaned_data) {
  moduleServer(id, function(input, output, session) {

    # TODO: Implement report generation logic
    # Access cleaned data with: cleaned_data()$visits_data

    # Example placeholder
    observe({
      req(cleaned_data())
      message("Reports module: Data available with ",
              nrow(cleaned_data()$visits_data), " rows")
    })

  })
}
