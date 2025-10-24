# ============================================================================
# EXPLORATORY DATA ANALYSIS (EDA) SHINY MODULE
# ============================================================================
#
# Shiny module for exploratory data analysis
# - Missingness visualization (respects patient-level "" vs NA logic)
# - Outlier detection (coming in Phase 2)
#
# SAFE TO MODIFY - Module pattern keeps code organized
# Uses functions from fct_visualization.R and fct_analysis.R
# ============================================================================

#' Visualization Module UI
#'
#' Creates the UI for the EDA/visualization tab
#'
#' @param id Module namespace ID
#' @return Shiny UI
#' @export
mod_visualization_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Control Panel Card
    card(
      card_header(icon("sliders"), "Analysis Controls"),
      layout_columns(
        col_widths = c(3, 3, 3, 3),

        # View type selector
        selectInput(
          ns("view_type"),
          "Analysis Type:",
          choices = c(
            "Missingness Overview" = "miss_overview",
            "Missingness Heatmap" = "miss_heatmap",
            "Visit Timeline" = "miss_timeline",
            "Patient Profile" = "patient_profile"
          ),
          selected = "miss_overview"
        ),

        # Instrument filter
        selectInput(
          ns("instrument_filter"),
          "Instrument:",
          choices = c("All Instruments" = "all"),
          selected = "all"
        ),

        # Section filter
        selectInput(
          ns("section_filter"),
          "Section:",
          choices = c(
            "All Sections" = "all",
            "Cognitive" = "cognitive",
            "Physical" = "physical",
            "Demographic" = "demographic",
            "Medical" = "medical"
          ),
          selected = "all"
        ),

        # Patient filter
        selectInput(
          ns("patient_filter"),
          "Patient:",
          choices = c("All Patients" = "all"),
          selected = "all",
          multiple = FALSE
        )
      )
    ),

    # Main visualization area - conditional panels

    # Panel 1: Missingness Overview
    conditionalPanel(
      condition = "input.view_type == 'miss_overview'",
      ns = ns,

      card(
        card_header(icon("table"), "Missingness Summary by Instrument"),
        card_body(
          uiOutput(ns("miss_summary_info")),
          reactable::reactableOutput(ns("miss_summary_table"))
        )
      ),

      card(
        card_header(icon("chart-column"), "Top Missing Variables"),
        card_body(
          reactable::reactableOutput(ns("top_missing_table"))
        )
      )
    ),

    # Panel 2: Missingness Heatmap
    conditionalPanel(
      condition = "input.view_type == 'miss_heatmap'",
      ns = ns,

      card(
        card_header(icon("table-cells"), "Variable Selection"),
        card_body(
          p("Select variables to display in heatmap:"),
          selectInput(
            ns("heatmap_vars"),
            "Variables:",
            choices = NULL,
            selected = NULL,
            multiple = TRUE,
            selectize = FALSE,
            size = 10
          ),
          actionButton(
            ns("select_all_vars"),
            "Select First 20",
            class = "btn-sm btn-outline-primary"
          ),
          actionButton(
            ns("clear_vars"),
            "Clear",
            class = "btn-sm btn-outline-secondary"
          )
        )
      ),

      card(
        card_header(icon("grip-horizontal"), "Missingness Heatmap"),
        card_body(
          uiOutput(ns("heatmap_info")),
          plotly::plotlyOutput(ns("miss_heatmap"), height = "600px")
        )
      )
    ),

    # Panel 3: Visit Timeline
    conditionalPanel(
      condition = "input.view_type == 'miss_timeline'",
      ns = ns,

      card(
        card_header(icon("chart-line"), "Completion Over Time"),
        card_body(
          uiOutput(ns("timeline_info")),
          plotly::plotlyOutput(ns("miss_timeline"), height = "500px")
        )
      )
    ),

    # Panel 4: Patient Profile
    conditionalPanel(
      condition = "input.view_type == 'patient_profile'",
      ns = ns,

      card(
        card_header(icon("user"), "Patient Missingness Profile"),
        card_body(
          uiOutput(ns("patient_profile_summary")),
          reactable::reactableOutput(ns("patient_profile_table"))
        )
      )
    )
  )
}


#' Visualization Module Server
#'
#' Server logic for EDA/visualization tab
#'
#' @param id Module namespace ID
#' @param cleaned_data Reactive value containing cleaned data
#' @param dict_data Data dictionary (non-reactive)
#' @export
mod_visualization_server <- function(id, cleaned_data, dict_data) {
  moduleServer(id, function(input, output, session) {

    # =========================================================================
    # REACTIVE DATA ANALYSIS
    # =========================================================================

    # Analyze missingness when data is loaded
    missingness_analysis <- reactive({
      req(cleaned_data())
      message("[MOD_VIZ] Analyzing missingness...")

      result <- analyze_missingness(
        cleaned_data()$visits_data,
        dict_data
      )

      message("[MOD_VIZ] Missingness analysis complete: ", nrow(result), " variables")
      result
    })

    # Instrument summary
    instrument_summary <- reactive({
      req(missingness_analysis())
      summarize_missingness_by_instrument(missingness_analysis())
    })

    # Get available instruments for filter
    observe({
      req(instrument_summary())

      instruments <- instrument_summary()$instrument
      choices <- c("All Instruments" = "all", setNames(instruments, instruments))

      updateSelectInput(session, "instrument_filter", choices = choices)
    })

    # Get available patients for filter
    observe({
      req(cleaned_data())

      patients <- sort(unique(cleaned_data()$visits_data$id_client_id))
      choices <- c("All Patients" = "all", setNames(patients, patients))

      updateSelectInput(session, "patient_filter", choices = choices)
    })

    # Filtered missingness analysis based on instrument/section
    filtered_missingness <- reactive({
      req(missingness_analysis())

      result <- missingness_analysis()

      # Filter by instrument
      if (input$instrument_filter != "all") {
        result <- result[result$instrument == input$instrument_filter &
                          !is.na(result$instrument), ]
      }

      # Filter by section
      if (input$section_filter != "all") {
        result <- result[result$section == input$section_filter &
                          !is.na(result$section), ]
      }

      result
    })

    # Update heatmap variable choices based on filters
    observe({
      req(filtered_missingness())

      vars <- filtered_missingness()$variable

      updateSelectInput(
        session,
        "heatmap_vars",
        choices = vars,
        selected = head(vars, 20)  # Default to first 20
      )
    })

    # Select first 20 variables button
    observeEvent(input$select_all_vars, {
      req(filtered_missingness())
      vars <- filtered_missingness()$variable
      updateSelectInput(session, "heatmap_vars", selected = head(vars, 20))
    })

    # Clear variable selection button
    observeEvent(input$clear_vars, {
      updateSelectInput(session, "heatmap_vars", selected = character(0))
    })


    # =========================================================================
    # OUTPUT: MISSINGNESS OVERVIEW
    # =========================================================================

    output$miss_summary_info <- renderUI({
      req(instrument_summary())

      n_instruments <- nrow(instrument_summary())

      tagList(
        p(
          strong("Dataset: "),
          nrow(cleaned_data()$visits_data), " observations, ",
          length(unique(cleaned_data()$visits_data$id_client_id)), " patients"
        ),
        p(
          strong("Instruments analyzed: "), n_instruments
        )
      )
    })

    output$miss_summary_table <- reactable::renderReactable({
      req(instrument_summary())

      reactable::reactable(
        instrument_summary(),
        columns = list(
          instrument = reactable::colDef(name = "Instrument", minWidth = 150),
          n_variables = reactable::colDef(name = "# Variables", width = 100),
          avg_pct_data = reactable::colDef(
            name = "Avg % Complete",
            width = 120,
            format = reactable::colFormat(suffix = "%"),
            style = function(value) {
              if (value >= 80) {
                color <- "#2ecc71"  # Green
              } else if (value >= 50) {
                color <- "#f39c12"  # Yellow
              } else {
                color <- "#e74c3c"  # Red
              }
              list(fontWeight = "bold", color = color)
            }
          ),
          avg_pct_empty = reactable::colDef(
            name = "Avg % Empty",
            width = 120,
            format = reactable::colFormat(suffix = "%")
          ),
          avg_pct_na = reactable::colDef(
            name = "Avg % NA",
            width = 120,
            format = reactable::colFormat(suffix = "%")
          ),
          min_completion = reactable::colDef(
            name = "Min %",
            width = 80,
            format = reactable::colFormat(suffix = "%")
          ),
          max_completion = reactable::colDef(
            name = "Max %",
            width = 80,
            format = reactable::colFormat(suffix = "%")
          )
        ),
        striped = TRUE,
        highlight = TRUE,
        defaultPageSize = 15,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(10, 15, 20, 50)
      )
    })

    output$top_missing_table <- reactable::renderReactable({
      req(filtered_missingness())

      # Get top 20 most missing variables
      top_missing <- filtered_missingness() %>%
        arrange(pct_has_data) %>%
        head(20) %>%
        select(variable, instrument, pct_has_data, pct_empty, pct_na)

      reactable::reactable(
        top_missing,
        columns = list(
          variable = reactable::colDef(name = "Variable", minWidth = 200),
          instrument = reactable::colDef(name = "Instrument", minWidth = 120),
          pct_has_data = reactable::colDef(
            name = "% Complete",
            width = 100,
            format = reactable::colFormat(suffix = "%"),
            style = function(value) {
              if (value >= 80) color <- "#2ecc71"
              else if (value >= 50) color <- "#f39c12"
              else color <- "#e74c3c"
              list(fontWeight = "bold", color = color)
            }
          ),
          pct_empty = reactable::colDef(
            name = "% Empty",
            width = 100,
            format = reactable::colFormat(suffix = "%")
          ),
          pct_na = reactable::colDef(
            name = "% NA",
            width = 100,
            format = reactable::colFormat(suffix = "%")
          )
        ),
        striped = TRUE,
        highlight = TRUE,
        defaultPageSize = 20
      )
    })


    # =========================================================================
    # OUTPUT: MISSINGNESS HEATMAP
    # =========================================================================

    output$heatmap_info <- renderUI({
      req(input$heatmap_vars)

      n_vars <- length(input$heatmap_vars)

      if (n_vars == 0) {
        p(
          class = "text-muted",
          icon("info-circle"),
          " Select variables from the list above to display heatmap"
        )
      } else {
        # Get patient filter info
        patient_info <- if (input$patient_filter == "all") {
          paste(length(unique(cleaned_data()$visits_data$id_client_id)), "patients")
        } else {
          paste("Patient:", input$patient_filter)
        }

        p(
          strong("Displaying: "), n_vars, " variables × ", patient_info
        )
      }
    })

    output$miss_heatmap <- plotly::renderPlotly({
      req(input$heatmap_vars)
      req(length(input$heatmap_vars) > 0)
      req(cleaned_data())

      # Get patient filter
      patient_ids <- if (input$patient_filter == "all") {
        NULL  # All patients
      } else {
        input$patient_filter
      }

      message("[MOD_VIZ] Creating heatmap with ",
              length(input$heatmap_vars), " variables")

      create_missingness_heatmap(
        cleaned_data()$visits_data,
        input$heatmap_vars,
        patient_ids = patient_ids
      )
    })


    # =========================================================================
    # OUTPUT: VISIT TIMELINE
    # =========================================================================

    output$timeline_info <- renderUI({
      req(cleaned_data())

      n_visits <- length(unique(cleaned_data()$visits_data$id_visit_no))

      instrument_text <- if (input$instrument_filter == "all") {
        "all instruments"
      } else {
        input$instrument_filter
      }

      p(
        strong("Showing completion across "), n_visits, " visits for ",
        instrument_text
      )
    })

    output$miss_timeline <- plotly::renderPlotly({
      req(cleaned_data())

      instrument_filter <- if (input$instrument_filter == "all") {
        NULL
      } else {
        input$instrument_filter
      }

      message("[MOD_VIZ] Creating timeline for instrument: ",
              ifelse(is.null(instrument_filter), "all", instrument_filter))

      create_visit_completion_timeline(
        cleaned_data()$visits_data,
        dict_data,
        instrument_filter = instrument_filter
      )
    })


    # =========================================================================
    # OUTPUT: PATIENT PROFILE
    # =========================================================================

    output$patient_profile_summary <- renderUI({
      req(input$patient_filter != "all")
      req(cleaned_data())

      profile <- get_patient_missingness_profile(
        cleaned_data()$visits_data,
        input$patient_filter,
        dict_data
      )

      if (is.null(profile)) {
        return(p("Error: Could not load patient profile"))
      }

      tagList(
        h5(paste("Patient:", profile$patient_id)),
        layout_columns(
          col_widths = c(3, 3, 3, 3),
          value_box(
            title = "Visits",
            value = profile$n_visits,
            theme = "primary"
          ),
          value_box(
            title = "Variables with Data",
            value = profile$n_with_data,
            theme = "success"
          ),
          value_box(
            title = "Empty Strings",
            value = profile$n_empty,
            theme = "warning"
          ),
          value_box(
            title = "Truly Missing (NA)",
            value = profile$n_na,
            theme = "danger"
          )
        )
      )
    })

    output$patient_profile_table <- reactable::renderReactable({
      req(input$patient_filter != "all")
      req(cleaned_data())

      profile <- get_patient_missingness_profile(
        cleaned_data()$visits_data,
        input$patient_filter,
        dict_data
      )

      if (is.null(profile)) {
        return(NULL)
      }

      # Show variable details
      details <- profile$variable_details %>%
        select(variable, instrument, status) %>%
        arrange(status, instrument, variable)

      reactable::reactable(
        details,
        columns = list(
          variable = reactable::colDef(name = "Variable", minWidth = 200),
          instrument = reactable::colDef(name = "Instrument", minWidth = 120),
          status = reactable::colDef(
            name = "Status",
            width = 150,
            style = function(value) {
              if (value == "Has Data") {
                color <- "#2ecc71"
              } else if (value == "Empty String") {
                color <- "#f39c12"
              } else if (value == "NA") {
                color <- "#e74c3c"
              } else {
                color <- "#7f8c8d"
              }
              list(fontWeight = "bold", color = color)
            }
          )
        ),
        groupBy = "instrument",
        striped = TRUE,
        highlight = TRUE,
        defaultPageSize = 20,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(20, 50, 100)
      )
    })

    # Show message when no patient selected
    observe({
      if (input$view_type == "patient_profile" && input$patient_filter == "all") {
        showNotification(
          "Please select a specific patient from the Patient filter",
          type = "message",
          duration = 3
        )
      }
    })

  })
}
