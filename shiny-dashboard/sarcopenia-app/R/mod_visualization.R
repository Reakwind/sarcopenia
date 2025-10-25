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
      card_body(
        fluidRow(
          # View type selector
          column(3,
            selectInput(
              ns("view_type"),
              "Analysis Type:",
              choices = c(
                "Missingness Overview" = "miss_overview",
                "Missingness Heatmap" = "miss_heatmap",
                "Visit Timeline" = "miss_timeline",
                "Patient Profile" = "patient_profile",
                "─── Outlier Detection ───" = "divider_outliers",
                "Outlier Summary" = "outlier_summary",
                "Outlier Details" = "outlier_details",
                "Outlier Boxplots" = "outlier_boxplots",
                "Outlier Timeline" = "outlier_timeline"
              ),
              selected = "miss_overview"
            )
          ),

          # Instrument filter
          column(3,
            selectInput(
              ns("instrument_filter"),
              "Instrument:",
              choices = c("All Instruments" = "all"),
              selected = "all"
            )
          ),

          # Section filter
          column(3,
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
            )
          ),

          # Patient filter
          column(3,
            selectInput(
              ns("patient_filter"),
              "Patient:",
              choices = c("All Patients" = "all"),
              selected = "all",
              multiple = FALSE
            )
          )
        )
      )
    ),

    # Main visualization area - conditional panels

    # Panel 1: Missingness Overview
    conditionalPanel(
      condition = "input['viz-view_type'] == 'miss_overview'",

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
      condition = "input['viz-view_type'] == 'miss_heatmap'",

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
      condition = "input['viz-view_type'] == 'miss_timeline'",

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
      condition = "input['viz-view_type'] == 'patient_profile'",

      card(
        card_header(icon("user"), "Patient Missingness Profile"),
        card_body(
          uiOutput(ns("patient_profile_summary")),
          reactable::reactableOutput(ns("patient_profile_table"))
        )
      )
    ),

    # ========================================================================
    # OUTLIER DETECTION PANELS
    # ========================================================================

    # Panel 5: Outlier Summary
    conditionalPanel(
      condition = "input['viz-view_type'] == 'outlier_summary'",

      card(
        card_header(icon("triangle-exclamation"), "Outliers by Instrument"),
        card_body(
          uiOutput(ns("outlier_summary_info")),
          reactable::reactableOutput(ns("outlier_instrument_table"))
        )
      ),

      card(
        card_header(icon("chart-column"), "Top Variables with Outliers"),
        card_body(
          reactable::reactableOutput(ns("outlier_variable_table"))
        )
      )
    ),

    # Panel 6: Outlier Details
    conditionalPanel(
      condition = "input['viz-view_type'] == 'outlier_details'",

      card(
        card_header(icon("list"), "All Outlier Records"),
        card_body(
          uiOutput(ns("outlier_details_info")),
          fluidRow(
            column(4,
              selectInput(
                ns("outlier_type_filter"),
                "Outlier Type:",
                choices = c(
                  "All Types" = "all",
                  "Range Violations" = "range",
                  "IQR Outliers" = "iqr",
                  "Z-Score Outliers" = "zscore"
                ),
                selected = "all"
              )
            ),
            column(4,
              downloadButton(ns("download_outliers"), "Download Outliers CSV",
                            class = "btn-primary mt-4")
            )
          ),
          reactable::reactableOutput(ns("outlier_details_table"))
        )
      )
    ),

    # Panel 7: Outlier Boxplots
    conditionalPanel(
      condition = "input['viz-view_type'] == 'outlier_boxplots'",

      card(
        card_header(icon("table-cells"), "Variable Selection"),
        card_body(
          p("Select a numeric variable to visualize outliers:"),
          selectInput(
            ns("boxplot_variable"),
            "Variable:",
            choices = NULL,
            selected = NULL
          )
        )
      ),

      card(
        card_header(icon("chart-simple"), "Distribution with Outliers"),
        card_body(
          uiOutput(ns("boxplot_info")),
          plotly::plotlyOutput(ns("outlier_boxplot"), height = "600px")
        )
      )
    ),

    # Panel 8: Outlier Timeline
    conditionalPanel(
      condition = "input['viz-view_type'] == 'outlier_timeline'",

      card(
        card_header(icon("chart-line"), "Outlier Trends Across Visits"),
        card_body(
          uiOutput(ns("outlier_timeline_info")),
          plotly::plotlyOutput(ns("outlier_timeline"), height = "500px")
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
    # OUTLIER DETECTION - REACTIVE EXPRESSIONS
    # =========================================================================

    # Load valid ranges reference
    valid_ranges <- reactive({
      ranges_file <- system.file("extdata", "instrument_valid_ranges.csv",
                                 package = "sarcDash", mustWork = FALSE)

      # If package not installed, try local path
      if (ranges_file == "") {
        ranges_file <- "inst/extdata/instrument_valid_ranges.csv"
      }

      if (file.exists(ranges_file)) {
        read_csv(ranges_file, show_col_types = FALSE)
      } else {
        message("[OUTLIERS] Valid ranges file not found")
        data.frame()  # Return empty dataframe
      }
    })

    # Detect range violations
    range_violations <- reactive({
      req(cleaned_data())
      req(valid_ranges())

      if (nrow(valid_ranges()) == 0) {
        return(data.frame())
      }

      detect_range_violations(
        cleaned_data()$visits_data,
        dict_data,
        valid_ranges()
      )
    })

    # Get numeric variables for IQR/Z-score detection
    numeric_variables <- reactive({
      req(valid_ranges())

      if (nrow(valid_ranges()) > 0) {
        valid_ranges()$variable_name
      } else {
        character(0)
      }
    })

    # Detect IQR outliers
    iqr_outliers <- reactive({
      req(cleaned_data())
      req(numeric_variables())

      if (length(numeric_variables()) == 0) {
        return(data.frame())
      }

      detect_outliers_iqr(
        cleaned_data()$visits_data,
        numeric_variables(),
        multiplier = 1.5
      )
    })

    # Detect Z-score outliers
    zscore_outliers <- reactive({
      req(cleaned_data())
      req(numeric_variables())

      if (length(numeric_variables()) == 0) {
        return(data.frame())
      }

      detect_outliers_zscore(
        cleaned_data()$visits_data,
        numeric_variables(),
        threshold = 3
      )
    })

    # Combine all outliers
    all_outliers <- reactive({
      range <- range_violations()
      iqr <- iqr_outliers()
      zscore <- zscore_outliers()

      # Add outlier_type column and combine
      result <- list()

      if (nrow(range) > 0) {
        range$outlier_type <- "range"
        range <- range %>% select(patient_id, visit_no, variable, value, outlier_type)
        result[[length(result) + 1]] <- range
      }

      if (nrow(iqr) > 0) {
        iqr$outlier_type <- "iqr"
        iqr <- iqr %>% select(patient_id, visit_no, variable, value, outlier_type)
        result[[length(result) + 1]] <- iqr
      }

      if (nrow(zscore) > 0) {
        zscore$outlier_type <- "zscore"
        zscore <- zscore %>% select(patient_id, visit_no, variable, value, outlier_type)
        result[[length(result) + 1]] <- zscore
      }

      if (length(result) > 0) {
        do.call(rbind, result)
      } else {
        data.frame()
      }
    })

    # Outlier summary by instrument
    outlier_summary_instrument <- reactive({
      req(range_violations())
      req(iqr_outliers())
      req(zscore_outliers())

      summarize_outliers_by_instrument(
        range_violations(),
        iqr_outliers(),
        zscore_outliers(),
        dict_data
      )
    })

    # Outlier summary by variable
    outlier_summary_variable <- reactive({
      req(range_violations())
      req(iqr_outliers())
      req(zscore_outliers())

      summarize_outliers_by_variable(
        range_violations(),
        iqr_outliers(),
        zscore_outliers(),
        dict_data
      )
    })

    # Filtered outliers for details table
    filtered_outliers <- reactive({
      req(all_outliers())

      result <- all_outliers()

      # Filter by outlier type
      if (input$outlier_type_filter != "all") {
        result <- result[result$outlier_type == input$outlier_type_filter, ]
      }

      # Filter by instrument
      if (input$instrument_filter != "all") {
        # Get variables for this instrument
        inst_vars <- dict_data$new_name[dict_data$instrument == input$instrument_filter &
                                         !is.na(dict_data$instrument)]
        result <- result[result$variable %in% inst_vars, ]
      }

      # Filter by patient
      if (input$patient_filter != "all") {
        result <- result[result$patient_id == input$patient_filter, ]
      }

      result
    })

    # Update boxplot variable choices
    observe({
      req(numeric_variables())

      updateSelectInput(
        session,
        "boxplot_variable",
        choices = numeric_variables(),
        selected = if (length(numeric_variables()) > 0) numeric_variables()[1] else NULL
      )
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
          avg_pct_missing = reactable::colDef(
            name = "Avg % Missing",
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
        fullWidth = TRUE,
        height = "auto",
        defaultPageSize = 50,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(10, 20, 50, 100)
      )
    })

    output$top_missing_table <- reactable::renderReactable({
      req(filtered_missingness())

      # Get top 20 most missing variables
      top_missing <- filtered_missingness() %>%
        arrange(pct_has_data) %>%
        head(20) %>%
        select(variable, instrument, pct_has_data, pct_missing)

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
          pct_missing = reactable::colDef(
            name = "% Missing",
            width = 100,
            format = reactable::colFormat(suffix = "%")
          )
        ),
        striped = TRUE,
        highlight = TRUE,
        fullWidth = TRUE,
        height = "auto",
        defaultPageSize = 20,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(10, 20, 50)
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
          col_widths = c(4, 4, 4),
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
            title = "Missing (NA)",
            value = profile$n_missing,
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
                color <- "#2ecc71"  # Green
              } else if (value == "Missing") {
                color <- "#e74c3c"  # Red
              } else {
                color <- "#7f8c8d"  # Gray (fallback)
              }
              list(fontWeight = "bold", color = color)
            }
          )
        ),
        groupBy = "instrument",
        striped = TRUE,
        highlight = TRUE,
        fullWidth = TRUE,
        height = "auto",
        defaultPageSize = 50,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(20, 50, 100, 200)
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


    # =========================================================================
    # OUTPUT: OUTLIER SUMMARY
    # =========================================================================

    output$outlier_summary_info <- renderUI({
      req(all_outliers())

      n_total <- nrow(all_outliers())
      n_patients <- length(unique(all_outliers()$patient_id))

      tagList(
        p(
          strong("Total outliers detected: "), n_total,
          " across ", n_patients, " patients"
        )
      )
    })

    output$outlier_instrument_table <- reactable::renderReactable({
      req(outlier_summary_instrument())

      reactable::reactable(
        outlier_summary_instrument(),
        columns = list(
          instrument = reactable::colDef(name = "Instrument", minWidth = 150),
          n_variables = reactable::colDef(name = "# Variables", width = 100),
          n_range_violations = reactable::colDef(
            name = "Range Violations",
            width = 120,
            style = function(value) {
              if (value > 0) list(fontWeight = "bold", color = "#e74c3c")
            }
          ),
          n_iqr_outliers = reactable::colDef(
            name = "IQR Outliers",
            width = 110,
            style = function(value) {
              if (value > 0) list(fontWeight = "bold", color = "#f39c12")
            }
          ),
          n_zscore_outliers = reactable::colDef(
            name = "Z-Score Outliers",
            width = 130,
            style = function(value) {
              if (value > 0) list(fontWeight = "bold", color = "#9b59b6")
            }
          ),
          n_total_outliers = reactable::colDef(
            name = "Total Outliers",
            width = 120,
            style = function(value) {
              color <- if (value > 50) "#e74c3c"
                       else if (value > 20) "#f39c12"
                       else "#3498db"
              list(fontWeight = "bold", color = color)
            }
          )
        ),
        striped = TRUE,
        highlight = TRUE,
        fullWidth = TRUE,
        height = "auto",
        defaultPageSize = 20
      )
    })

    output$outlier_variable_table <- reactable::renderReactable({
      req(outlier_summary_variable())

      # Show top 30 variables
      top_vars <- outlier_summary_variable() %>% head(30)

      reactable::reactable(
        top_vars,
        columns = list(
          variable = reactable::colDef(name = "Variable", minWidth = 200),
          instrument = reactable::colDef(name = "Instrument", minWidth = 120),
          n_range_violations = reactable::colDef(name = "Range", width = 80),
          n_iqr_outliers = reactable::colDef(name = "IQR", width = 70),
          n_zscore_outliers = reactable::colDef(name = "Z-Score", width = 90),
          n_total_outliers = reactable::colDef(
            name = "Total",
            width = 80,
            style = function(value) {
              list(fontWeight = "bold", color = "#e74c3c")
            }
          )
        ),
        striped = TRUE,
        highlight = TRUE,
        fullWidth = TRUE,
        height = "auto",
        defaultPageSize = 30
      )
    })


    # =========================================================================
    # OUTPUT: OUTLIER DETAILS
    # =========================================================================

    output$outlier_details_info <- renderUI({
      req(filtered_outliers())

      n_outliers <- nrow(filtered_outliers())
      n_patients <- length(unique(filtered_outliers()$patient_id))
      n_variables <- length(unique(filtered_outliers()$variable))

      p(
        strong("Showing: "), n_outliers, " outliers",
        " (", n_patients, " patients, ", n_variables, " variables)"
      )
    })

    output$outlier_details_table <- reactable::renderReactable({
      req(filtered_outliers())

      # Add instrument column
      outliers_with_inst <- filtered_outliers()
      outliers_with_inst$instrument <- sapply(outliers_with_inst$variable, function(var) {
        dict_row <- dict_data[dict_data$new_name == var, ]
        if (nrow(dict_row) > 0) dict_row$instrument[1] else NA
      })

      reactable::reactable(
        outliers_with_inst,
        columns = list(
          patient_id = reactable::colDef(name = "Patient", width = 120),
          visit_no = reactable::colDef(name = "Visit", width = 80),
          variable = reactable::colDef(name = "Variable", minWidth = 180),
          instrument = reactable::colDef(name = "Instrument", width = 130),
          value = reactable::colDef(name = "Value", width = 100),
          outlier_type = reactable::colDef(
            name = "Type",
            width = 100,
            cell = function(value) {
              label <- switch(value,
                "range" = "Range Violation",
                "iqr" = "IQR Outlier",
                "zscore" = "Z-Score Outlier",
                value
              )
              color <- switch(value,
                "range" = "#e74c3c",
                "iqr" = "#f39c12",
                "zscore" = "#9b59b6",
                "#95a5a6"
              )
              tags$span(style = paste0("color: ", color, "; font-weight: bold;"), label)
            }
          )
        ),
        filterable = TRUE,
        searchable = TRUE,
        striped = TRUE,
        highlight = TRUE,
        fullWidth = TRUE,
        height = "auto",
        defaultPageSize = 50,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(25, 50, 100, 200)
      )
    })

    # Download outliers CSV
    output$download_outliers <- downloadHandler(
      filename = function() {
        paste0("outliers_", Sys.Date(), ".csv")
      },
      content = function(file) {
        write.csv(filtered_outliers(), file, row.names = FALSE)
      }
    )


    # =========================================================================
    # OUTPUT: OUTLIER BOXPLOTS
    # =========================================================================

    output$boxplot_info <- renderUI({
      req(input$boxplot_variable)

      outliers_for_var <- all_outliers() %>%
        filter(variable == input$boxplot_variable)

      if (nrow(outliers_for_var) > 0) {
        p(
          strong("Outliers for this variable: "), nrow(outliers_for_var),
          " (", length(unique(outliers_for_var$patient_id)), " patients)"
        )
      } else {
        p(
          icon("check-circle"),
          " No outliers detected for this variable",
          style = "color: #2ecc71;"
        )
      }
    })

    output$outlier_boxplot <- plotly::renderPlotly({
      req(input$boxplot_variable)
      req(cleaned_data())

      message("[MOD_VIZ] Creating boxplot for ", input$boxplot_variable)

      create_outlier_boxplot(
        cleaned_data()$visits_data,
        input$boxplot_variable,
        all_outliers()
      )
    })


    # =========================================================================
    # OUTPUT: OUTLIER TIMELINE
    # =========================================================================

    output$outlier_timeline_info <- renderUI({
      n_range <- nrow(range_violations())
      n_iqr <- nrow(iqr_outliers())
      n_zscore <- nrow(zscore_outliers())

      tagList(
        p(
          strong("Outlier counts by type:"),
          " Range violations: ", n_range, ", ",
          "IQR outliers: ", n_iqr, ", ",
          "Z-score outliers: ", n_zscore
        )
      )
    })

    output$outlier_timeline <- plotly::renderPlotly({
      req(range_violations())
      req(iqr_outliers())
      req(zscore_outliers())

      message("[MOD_VIZ] Creating outlier timeline")

      create_outlier_timeline(
        range_violations(),
        iqr_outliers(),
        zscore_outliers(),
        visit_col = "visit_no"
      )
    })

  })
}
