# ============================================================================
# INSTRUMENT ANALYSIS TAB - SHINY MODULE
# ============================================================================
#
# Shiny module for cross-patient instrument analysis
# - Instrument selector (cognitive + physical assessments)
# - Patient-level comparison table (rows = patients, columns = variables)
# - First visit data only
#
# SAFE TO MODIFY - Module pattern keeps code organized
# ============================================================================

#' Instrument Analysis Module UI
#'
#' Creates the UI for cross-patient instrument comparison
#'
#' @param id Module namespace ID
#' @return Shiny UI
#' @export
mod_instrument_analysis_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # ========================================================================
    # INSTRUMENT SELECTOR WITH LEGEND
    # ========================================================================
    card_body(
      p(class = "text-muted",
        "Select a questionnaire or test to view first-visit data across all patients."
      ),

      # Instrument selector (grouped dropdown)
      tags$div(
        title = "Choose a cognitive or physical test to compare all patients at their first visit",
        selectInput(
          ns("selected_instrument"),
          "Select a test or assessment:",
          choices = NULL,
          width = "100%"
        )
      ),
      helpText(class = "text-muted", style = "margin-top: -10px; margin-bottom: 15px; font-size: 0.85em;",
              "Compare patients on the same test at their baseline visit"),

      # COLLAPSIBLE COLOR LEGEND
      hr(),
      tags$div(
        tags$div(
          id = ns("legend_header"),
          onclick = sprintf("$('#%s').slideToggle(300);", ns("legend_content")),
          style = "cursor: pointer; padding: 10px; background-color: #f8f9fa; border-radius: 5px; border: 1px solid #dee2e6; margin-bottom: 5px;",
          tags$h6(
            icon("chevron-down", style = "margin-right: 8px;"),
            "Data Quality Indicators",
            style = "margin: 0; font-weight: bold; display: inline;"
          ),
          tags$small(" (click to expand/collapse)", style = "color: #6c757d; margin-left: 8px;")
        ),
        tags$div(
          id = ns("legend_content"),
          style = "padding: 15px; background-color: #f8f9fa; border-radius: 5px; border: 1px solid #dee2e6; display: none;",
          tags$div(
            style = "display: flex; flex-wrap: wrap; gap: 15px;",

            # Missing data (light gray)
            tags$div(
              style = "display: flex; align-items: center;",
              tags$span(
                style = "display: inline-block; width: 20px; height: 20px; background-color: #e9ecef; border: 1px solid #999; margin-right: 6px; border-radius: 3px;"
              ),
              tags$span("Missing Data (NA)", style = "font-size: 13px;")
            ),

            # Statistical outlier (light blue)
            tags$div(
              style = "display: flex; align-items: center;",
              tags$span(
                style = "display: inline-block; width: 20px; height: 20px; background-color: #cfe2ff; border: 1px solid #999; margin-right: 6px; border-radius: 3px;"
              ),
              tags$span("Statistical Outlier (IQR)", style = "font-size: 13px;")
            ),

            # Clinical outlier (light yellow)
            tags$div(
              style = "display: flex; align-items: center;",
              tags$span(
                style = "display: inline-block; width: 20px; height: 20px; background-color: #fff3cd; border: 1px solid #999; margin-right: 6px; border-radius: 3px;"
              ),
              tags$span("Clinical Outlier", style = "font-size: 13px;")
            ),

            # Both types (light red)
            tags$div(
              style = "display: flex; align-items: center;",
              tags$span(
                style = "display: inline-block; width: 20px; height: 20px; background-color: #f8d7da; border: 1px solid #999; margin-right: 6px; border-radius: 3px;"
              ),
              tags$span("Both IQR + Clinical", style = "font-size: 13px;")
            )
          )
        )
      ),

      hr(),

      # ========================================================================
      # DATA TABLE SECTION
      # ========================================================================
      tags$h5(icon("table"), " Patient Comparison", style = "margin-top: 20px; margin-bottom: 10px;"),
      p(class = "text-muted",
        "Rows = patients, columns = variables. Scroll horizontally to see all variables."
      ),

      reactable::reactableOutput(ns("instrument_data_table"), height = "700px")
    )
  )
}


#' Instrument Analysis Module Server
#'
#' Server logic for cross-patient instrument comparison
#'
#' @param id Module namespace ID
#' @param cleaned_data Reactive value containing cleaned data
#' @param data_dict Data dictionary dataframe
#' @export
mod_instrument_analysis_server <- function(id, cleaned_data, data_dict) {
  moduleServer(id, function(input, output, session) {

    # ======================================================================
    # POPULATE INSTRUMENT DROPDOWN
    # ======================================================================
    observe({
      if (is.null(cleaned_data())) {
        # Empty state - no data loaded
        updateSelectInput(session, "selected_instrument",
                         choices = c("(Upload and process data first)" = ""))
        return()
      }

      req(data_dict)

      # Get instrument list (grouped by cognitive/physical)
      # Pattern: Call pure function, update UI with result
      instrument_list <- get_instrument_list(data_dict)

      if (length(instrument_list) == 0) {
        updateSelectInput(session, "selected_instrument",
                         choices = c("(No instruments found in data dictionary)" = ""))
        return()
      }

      # Update dropdown with grouped choices
      updateSelectInput(session, "selected_instrument",
                       choices = instrument_list)
    })

    # ======================================================================
    # RENDER INSTRUMENT DATA TABLE
    # ======================================================================
    output$instrument_data_table <- reactable::renderReactable({
      if (is.null(cleaned_data()) || is.null(input$selected_instrument) || input$selected_instrument == "") {
        # Empty state
        return(reactable::reactable(
          data.frame(
            Message = "Select an instrument from the dropdown above to view patient comparison data"
          ),
          defaultColDef = reactable::colDef(
            style = list(textAlign = "center", color = "#6c757d", fontSize = "1.1em")
          )
        ))
      }

      # Extract tibble from reactive list
      # Pattern: Use [[]] to access list element
      visits_data <- cleaned_data()[["visits_data"]]

      # Get instrument data table
      # Pattern: Pass tibble to pure function
      instrument_table <- get_instrument_table(
        data = visits_data,
        instrument_name = input$selected_instrument,
        dict = data_dict
      )

      if (is.null(instrument_table) || nrow(instrument_table) == 0) {
        return(reactable::reactable(
          data.frame(Message = "No data available for this instrument"),
          defaultColDef = reactable::colDef(
            style = list(textAlign = "center", color = "#6c757d", fontSize = "1.1em")
          )
        ))
      }

      # Identify data columns (excluding metadata columns)
      data_cols <- names(instrument_table)[!grepl("_is_missing$|_outlier_type$", names(instrument_table))]

      # Identify instrument-specific columns (exclude ID columns)
      id_cols <- c("id_client_id", "id_client_name", "id_visit_date")
      instrument_data_cols <- data_cols[!data_cols %in% id_cols]

      # Create column definitions
      columns_list <- list(
        id_client_id = reactable::colDef(
          name = "Patient ID",
          minWidth = 120,
          sticky = "left",
          style = list(fontWeight = "bold", backgroundColor = "#f9f9f9")
        ),
        id_client_name = reactable::colDef(
          name = "Patient Name",
          minWidth = 150,
          sticky = "left",
          style = list(backgroundColor = "#f9f9f9")
        ),
        id_visit_date = reactable::colDef(
          name = "Visit Date",
          minWidth = 120,
          format = reactable::colFormat(date = TRUE, locales = "en-US")
        )
      )

      # Factory function to create column definition with proper closure
      create_styled_column <- function(col_name, data_table) {

        # Create local copies in this function's environment
        missing_col <- paste0(col_name, "_is_missing")
        outlier_col <- paste0(col_name, "_outlier_type")

        # Get metadata vectors (captured in THIS function's closure)
        missing_vec <- if (missing_col %in% names(data_table)) {
          data_table[[missing_col]]
        } else {
          rep(FALSE, nrow(data_table))
        }

        outlier_vec <- if (outlier_col %in% names(data_table)) {
          data_table[[outlier_col]]
        } else {
          rep(NA_character_, nrow(data_table))
        }

        # Return colDef with style function that captures THIS function's variables
        reactable::colDef(
          name = col_name,
          minWidth = 120,
          style = function(value, index) {
            # These variables are properly captured from create_styled_column's environment
            is_missing <- missing_vec[index]
            outlier_type <- outlier_vec[index]

            if (is_missing) {
              # Light gray for missing data
              list(backgroundColor = "#e9ecef", color = "#495057", fontWeight = "bold")
            } else if (!is.na(outlier_type)) {
              # 4-color scheme with neutral palette
              if (outlier_type == "both") {
                # Light red for both IQR + clinical
                list(backgroundColor = "#f8d7da", color = "#721c24", fontWeight = "bold")
              } else if (outlier_type == "clinical") {
                # Light yellow for clinical outlier
                list(backgroundColor = "#fff3cd", color = "#856404", fontWeight = "bold")
              } else if (outlier_type == "iqr") {
                # Light blue for IQR outlier
                list(backgroundColor = "#cfe2ff", color = "#084298", fontWeight = "bold")
              } else {
                # Normal (should not happen)
                list()
              }
            } else {
              # Normal - no styling
              list()
            }
          }
        )
      }

      # Add color-coded columns for each instrument variable using factory function
      # Use actual column names from data (resolved with suffixes)
      for (col in instrument_data_cols) {
        # Call factory function - creates fresh closure for THIS column
        columns_list[[col]] <- create_styled_column(col, instrument_table)
      }

      # Filter to only display data columns (hide metadata)
      display_data <- instrument_table %>%
        dplyr::select(tidyselect::all_of(data_cols))

      # Render table with color-coded columns
      reactable::reactable(
        display_data,
        columns = columns_list,
        searchable = TRUE,
        filterable = FALSE,
        defaultPageSize = 20,
        striped = FALSE,
        highlight = TRUE,
        compact = TRUE,
        wrap = FALSE,
        resizable = TRUE,
        defaultColDef = reactable::colDef(
          align = "left",
          headerStyle = list(background = "#f7f7f7", fontWeight = "bold", fontSize = "13px")
        ),
        theme = reactable::reactableTheme(
          borderColor = "#dfe2e5",
          highlightColor = "#f0f5f9"
        )
      )
    })

  })
}
