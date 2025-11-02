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
    # ========================================================================
    # SECTION 1: DATA QUALITY AT-A-GLANCE
    # ========================================================================
    card(
      card_header(icon("chart-line"), "Data Quality Overview"),
      card_body(
        layout_columns(
          col_widths = c(4, 4, 4),
          value_box(
            title = "Total Patients",
            value = uiOutput(ns("vb_total_patients")),
            theme = "primary",
            showcase = icon("users")
          ),
          value_box(
            title = "Total Outliers",
            value = uiOutput(ns("vb_total_outliers")),
            theme = "warning",
            showcase = icon("triangle-exclamation")
          ),
          value_box(
            title = "Overall Completion",
            value = uiOutput(ns("vb_overall_completion")),
            theme = "success",
            showcase = icon("check-circle")
          )
        )
      )
    ),

    # ========================================================================
    # SECTION 2: PATIENTS NEEDING ATTENTION
    # ========================================================================
    card(
      card_header(icon("users"), "Patients Needing Attention"),
      card_body(
        p(class = "text-muted",
          "Patients are automatically prioritized by data quality issues. ",
          strong("🔴 High Priority:"), " >30% missing or >10 outliers. ",
          strong("🟡 Medium:"), " 10-30% missing or 3-10 outliers. ",
          strong("🟢 Clean:"), " <10% missing and <3 outliers."
        ),

        fluidRow(
          column(6,
            selectInput(
              ns("patient_filter_type"),
              "Filter Patients:",
              choices = c(
                "All Issues" = "all",
                "High Missing Data (>30% NA)" = "high_missing",
                "Has Outliers" = "has_outliers",
                "Missing + Outliers" = "both"
              ),
              selected = "all"
            )
          ),
          column(6,
            downloadButton(ns("download_patient_list"),
                          "Export Filtered List (CSV)",
                          class = "btn-success",
                          style = "margin-top: 25px;")
          )
        ),

        hr(),

        reactable::reactableOutput(ns("patients_table"), height = "500px")
      )
    ),

    # ========================================================================
    # SECTION 3: PATIENT DETAIL PANEL (Expandable)
    # ========================================================================
    uiOutput(ns("patient_detail_panel")),

    # ========================================================================
    # SECTION 4: VISUAL EXPLORATION (Collapsible)
    # ========================================================================
    accordion(
      id = ns("viz_accordion"),
      accordion_panel(
        title = "Visual Exploration",
        icon = icon("chart-bar"),

        fluidRow(
          column(6,
            selectInput(
              ns("viz_type"),
              "Select Visualization:",
              choices = c(
                "Missingness Heatmap" = "miss_heatmap",
                "Outlier Timeline" = "outlier_timeline",
                "Completion by Visit" = "completion_timeline"
              ),
              selected = "miss_heatmap"
            )
          ),
          column(6,
            selectInput(
              ns("viz_instrument"),
              "Instrument:",
              choices = c("All Instruments" = "all"),
              selected = "all"
            )
          )
        ),

        # Heatmap view
        conditionalPanel(
          condition = "input['viz-viz_type'] == 'miss_heatmap'",

          fluidRow(
            column(12,
              p("Select variables to display:"),
              selectInput(
                ns("heatmap_vars"),
                NULL,
                choices = NULL,
                multiple = TRUE,
                selectize = FALSE,
                size = 8
              ),
              actionButton(ns("select_first_20"), "Select First 20", class = "btn-sm btn-outline-primary"),
              actionButton(ns("clear_selection"), "Clear", class = "btn-sm btn-outline-secondary")
            )
          ),

          plotly::plotlyOutput(ns("viz_heatmap"), height = "600px")
        ),

        # Timeline views
        conditionalPanel(
          condition = "input['viz-viz_type'] == 'outlier_timeline'",
          plotly::plotlyOutput(ns("viz_outlier_timeline"), height = "500px")
        ),

        conditionalPanel(
          condition = "input['viz-viz_type'] == 'completion_timeline'",
          plotly::plotlyOutput(ns("viz_completion_timeline"), height = "500px")
        )
      )
    )
  )  # End tagList
}


#' Visualization Module Server
#'
#' Server logic for simplified patient-focused data quality dashboard
#'
#' @param id Module namespace ID
#' @param cleaned_data Reactive value containing cleaned data
#' @param dict_data Data dictionary (non-reactive)
#' @export
mod_visualization_server <- function(id, cleaned_data, dict_data) {
  moduleServer(id, function(input, output, session) {

    # =========================================================================
    # REACTIVE DATA SOURCES
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

    # Instrument summary for overall metrics
    instrument_summary <- reactive({
      req(missingness_analysis())
      summarize_missingness_by_instrument(missingness_analysis())
    })


    # =========================================================================
    # OUTLIER DETECTION
    # =========================================================================

    # Load valid ranges reference
    valid_ranges <- reactive({
      # For Shiny app (not package), use direct path
      ranges_file <- "inst/extdata/instrument_valid_ranges.csv"

      if (file.exists(ranges_file)) {
        read_csv(ranges_file, show_col_types = FALSE)
      } else {
        message("[OUTLIERS] Valid ranges file not found")
        data.frame()
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

      result <- list()

      if (nrow(range) > 0) {
        range <- range %>% mutate(outlier_type = "Range Violation")
        result[[length(result) + 1]] <- range
      }

      if (nrow(iqr) > 0) {
        iqr <- iqr %>% mutate(outlier_type = "IQR Outlier")
        result[[length(result) + 1]] <- iqr
      }

      if (nrow(zscore) > 0) {
        zscore <- zscore %>% mutate(outlier_type = "Z-Score Outlier")
        result[[length(result) + 1]] <- zscore
      }

      if (length(result) > 0) {
        bind_rows(result)
      } else {
        data.frame()
      }
    })

    # Patient-level summaries
    patient_outliers_summary <- reactive({
      req(range_violations())
      req(iqr_outliers())
      req(zscore_outliers())

      summarize_patient_outliers(
        range_violations(),
        iqr_outliers(),
        zscore_outliers()
      )
    })

    patient_missingness_summary <- reactive({
      req(cleaned_data())

      summarize_patient_missingness(
        cleaned_data()$visits_data,
        dict_data
      )
    })


    # =========================================================================
    # UNIFIED PATIENT SUMMARY WITH PRIORITY SCORING
    # =========================================================================

    unified_patient_summary <- reactive({
      req(patient_missingness_summary())
      req(patient_outliers_summary())

      create_unified_patient_summary(
        patient_missingness_summary(),
        patient_outliers_summary()
      )
    })

    # Filtered patient summary based on user selection
    filtered_patient_summary <- reactive({
      req(unified_patient_summary())

      data <- unified_patient_summary()

      # Filter based on patient_filter_type input
      filter_type <- input$patient_filter_type

      if (filter_type == "high_missing") {
        data <- data %>% filter(pct_missing > 30)
      } else if (filter_type == "has_outliers") {
        data <- data %>% filter(total_outliers > 0)
      } else if (filter_type == "missing_and_outliers") {
        data <- data %>% filter(pct_missing > 10 & total_outliers > 0)
      }
      # "all" - no filter

      data
    })

    # Track selected patient for detail panel
    selected_patient <- reactiveVal(NULL)

    # Update selected patient when row is clicked
    observeEvent(input$patients_table__reactable__selected, {
      req(input$patients_table__reactable__selected)
      req(filtered_patient_summary())

      selected_row <- input$patients_table__reactable__selected
      patient_id <- filtered_patient_summary()$patient_id[selected_row]

      selected_patient(patient_id)
      message("[MOD_VIZ] Selected patient: ", patient_id)
    })


    # =========================================================================
    # UPDATE DROPDOWNS
    # =========================================================================

    # Update instrument choices for visualization filter
    observe({
      req(instrument_summary())

      instruments <- instrument_summary()$instrument
      choices <- c("All Instruments" = "all", setNames(instruments, instruments))

      updateSelectInput(session, "viz_instrument", choices = choices)
    })


    # =========================================================================
    # SECTION 1: DATA QUALITY AT-A-GLANCE (VALUE BOXES)
    # =========================================================================

    output$vb_total_patients <- renderUI({
      req(unified_patient_summary())
      nrow(unified_patient_summary())
    })

    output$vb_total_outliers <- renderUI({
      req(all_outliers())
      nrow(all_outliers())
    })

    output$vb_overall_completion <- renderUI({
      req(missingness_analysis())

      # Calculate overall completion percentage
      total_cells <- sum(missingness_analysis()$n_total)
      cells_with_data <- sum(missingness_analysis()$n_has_data)

      pct_complete <- round((cells_with_data / total_cells) * 100, 1)

      paste0(pct_complete, "%")
    })


    # =========================================================================
    # SECTION 2: PATIENTS NEEDING ATTENTION (MAIN TABLE)
    # =========================================================================

    output$patients_table <- reactable::renderReactable({
      req(filtered_patient_summary())

      data <- filtered_patient_summary()

      reactable::reactable(
        data,
        selection = "single",
        onClick = "select",
        defaultPageSize = 20,
        striped = TRUE,
        highlight = TRUE,
        searchable = TRUE,
        filterable = TRUE,
        defaultSorted = list(priority_score = "asc", pct_missing = "desc"),
        columns = list(
          priority = reactable::colDef(
            name = "Priority",
            width = 100,
            align = "center"
          ),
          patient_id = reactable::colDef(
            name = "Patient ID",
            minWidth = 120
          ),
          pct_missing = reactable::colDef(
            name = "% Missing",
            width = 110,
            format = reactable::colFormat(suffix = "%"),
            style = function(value) {
              color <- if (value > 30) "#dc3545"
                       else if (value > 10) "#ffc107"
                       else "#28a745"
              list(fontWeight = "bold", color = color)
            }
          ),
          total_outliers = reactable::colDef(
            name = "# Outliers",
            width = 100,
            style = function(value) {
              color <- if (value > 10) "#dc3545"
                       else if (value > 3) "#ffc107"
                       else "#28a745"
              list(fontWeight = "bold", color = color)
            }
          ),
          visits_with_missing = reactable::colDef(
            name = "Visits w/ Missing",
            minWidth = 150
          ),
          visits_with_outliers = reactable::colDef(
            name = "Visits w/ Outliers",
            minWidth = 150
          ),
          most_affected_instruments = reactable::colDef(
            name = "Affected Instruments",
            minWidth = 200
          ),
          # Hide internal columns
          priority_score = reactable::colDef(show = FALSE),
          total_variables = reactable::colDef(show = FALSE),
          variables_with_data = reactable::colDef(show = FALSE),
          variables_missing = reactable::colDef(show = FALSE),
          n_visits_missing = reactable::colDef(show = FALSE),
          range_violations = reactable::colDef(show = FALSE),
          iqr_outliers = reactable::colDef(show = FALSE),
          zscore_outliers = reactable::colDef(show = FALSE),
          n_visits_outliers = reactable::colDef(show = FALSE)
        )
      )
    })


    # =========================================================================
    # SECTION 3: PATIENT DETAIL PANEL (EXPANDABLE)
    # =========================================================================

    output$patient_detail_panel <- renderUI({
      req(selected_patient())

      patient_id <- selected_patient()

      # Get patient data from unified summary
      patient_row <- unified_patient_summary() %>%
        filter(patient_id == !!patient_id)

      if (nrow(patient_row) == 0) {
        return(NULL)
      }

      # Get detailed missingness profile
      miss_profile <- get_patient_missingness_profile(
        cleaned_data()$visits_data,
        patient_id,
        dict_data
      )

      # Get detailed outlier profile
      outlier_profile <- get_patient_outlier_profile(
        patient_id,
        range_violations(),
        iqr_outliers(),
        zscore_outliers(),
        dict_data
      )

      card(
        card_header(
          icon("user-circle"),
          paste("Patient Detail:", patient_id)
        ),
        card_body(
          h5("Summary"),
          layout_columns(
            col_widths = c(3, 3, 3, 3),
            value_box(
              title = "Priority",
              value = patient_row$priority,
              theme = if (patient_row$priority_score == 1) "danger"
                      else if (patient_row$priority_score == 2) "warning"
                      else "success",
              showcase = icon("exclamation-triangle")
            ),
            value_box(
              title = "% Missing",
              value = paste0(patient_row$pct_missing, "%"),
              theme = "info",
              showcase = icon("database")
            ),
            value_box(
              title = "# Outliers",
              value = patient_row$total_outliers,
              theme = "warning",
              showcase = icon("triangle-exclamation")
            ),
            value_box(
              title = "Visits",
              value = if (!is.null(miss_profile)) miss_profile$n_visits else "N/A",
              theme = "primary",
              showcase = icon("calendar")
            )
          ),

          hr(),

          h5("Missingness Details"),
          if (!is.null(miss_profile) && nrow(miss_profile$variable_details) > 0) {
            reactable::reactableOutput(session$ns("patient_detail_missing_table"))
          } else {
            p(class = "text-muted", "No missing data for this patient")
          },

          hr(),

          h5("Outlier Details"),
          if (!is.null(outlier_profile) && nrow(outlier_profile) > 0) {
            reactable::reactableOutput(session$ns("patient_detail_outlier_table"))
          } else {
            p(class = "text-muted", "No outliers for this patient")
          },

          hr(),

          downloadButton(
            session$ns("download_patient_report"),
            "Download Patient Report (CSV)",
            class = "btn-primary"
          )
        )
      )
    })

    # Patient detail missingness table
    output$patient_detail_missing_table <- reactable::renderReactable({
      req(selected_patient())

      profile <- get_patient_missingness_profile(
        cleaned_data()$visits_data,
        selected_patient(),
        dict_data
      )

      if (is.null(profile)) return(NULL)

      # Show only missing variables
      details <- profile$variable_details %>%
        filter(status == "Missing") %>%
        select(variable, instrument, visits_missing)

      if (nrow(details) == 0) return(reactable::reactable(data.frame()))

      reactable::reactable(
        details,
        columns = list(
          variable = reactable::colDef(name = "Variable", minWidth = 200),
          instrument = reactable::colDef(name = "Instrument", minWidth = 120),
          visits_missing = reactable::colDef(name = "Visits with NA", minWidth = 150)
        ),
        groupBy = "instrument",
        striped = TRUE,
        highlight = TRUE,
        defaultPageSize = 20,
        height = "400px"
      )
    })

    # Patient detail outlier table
    output$patient_detail_outlier_table <- reactable::renderReactable({
      req(selected_patient())

      profile <- get_patient_outlier_profile(
        selected_patient(),
        range_violations(),
        iqr_outliers(),
        zscore_outliers(),
        dict_data
      )

      if (is.null(profile) || nrow(profile) == 0) {
        return(reactable::reactable(data.frame()))
      }

      reactable::reactable(
        profile,
        columns = list(
          visit_no = reactable::colDef(name = "Visit", width = 80),
          variable = reactable::colDef(name = "Variable", minWidth = 150),
          variable_label = reactable::colDef(name = "Label", minWidth = 180),
          instrument = reactable::colDef(name = "Instrument", minWidth = 120),
          value = reactable::colDef(name = "Value", width = 100),
          outlier_type = reactable::colDef(
            name = "Type",
            width = 130,
            cell = function(value) {
              color <- if (value == "Range Violation") "#dc3545"
                       else if (value == "IQR Outlier") "#ffc107"
                       else "#17a2b8"
              tags$span(style = paste0("color: ", color, "; font-weight: bold;"), value)
            }
          ),
          detection_details = reactable::colDef(name = "Details", minWidth = 250)
        ),
        striped = TRUE,
        highlight = TRUE,
        defaultPageSize = 20,
        height = "400px"
      )
    })


    # =========================================================================
    # SECTION 4: VISUAL EXPLORATION (VISUALIZATIONS)
    # =========================================================================

    output$viz_heatmap <- plotly::renderPlotly({
      req(input$viz_type == "miss_heatmap")
      req(cleaned_data())
      req(missingness_analysis())

      # Get variables for selected instrument
      if (input$viz_instrument == "all") {
        # Use top 20 most missing variables overall
        vars <- missingness_analysis() %>%
          arrange(desc(pct_missing)) %>%
          head(20) %>%
          pull(variable)
      } else {
        # Get variables for selected instrument
        vars <- dict_data %>%
          filter(instrument == input$viz_instrument) %>%
          pull(new_name) %>%
          head(30)  # Limit to 30 for readability
      }

      if (length(vars) == 0) {
        return(plotly::plot_ly() %>%
                 plotly::layout(title = "No variables found for selected instrument"))
      }

      create_missingness_heatmap(
        cleaned_data()$visits_data,
        vars,
        patient_ids = NULL
      )
    })

    output$viz_outlier_timeline <- plotly::renderPlotly({
      req(input$viz_type == "outlier_timeline")
      req(range_violations())
      req(iqr_outliers())
      req(zscore_outliers())

      create_outlier_timeline(
        range_violations(),
        iqr_outliers(),
        zscore_outliers(),
        visit_col = "visit_no"
      )
    })

    output$viz_completion_timeline <- plotly::renderPlotly({
      req(input$viz_type == "completion_timeline")
      req(cleaned_data())

      instrument_filter <- if (input$viz_instrument == "all") {
        NULL
      } else {
        input$viz_instrument
      }

      create_visit_completion_timeline(
        cleaned_data()$visits_data,
        dict_data,
        instrument_filter = instrument_filter
      )
    })


    # =========================================================================
    # CSV DOWNLOAD HANDLERS
    # =========================================================================

    # Download filtered patient list
    output$download_patient_list <- downloadHandler(
      filename = function() {
        filter_name <- gsub(" ", "_", tolower(input$patient_filter_type))
        paste0("patients_", filter_name, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(filtered_patient_summary())
        write_csv(filtered_patient_summary(), file)
      }
    )

    # Download individual patient report
    output$download_patient_report <- downloadHandler(
      filename = function() {
        req(selected_patient())
        paste0("patient_", selected_patient(), "_report_", 
               format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(selected_patient())

        # Get patient summary row
        patient_row <- unified_patient_summary() %>%
          filter(patient_id == selected_patient())

        # Get missingness details
        miss_profile <- get_patient_missingness_profile(
          cleaned_data()$visits_data,
          selected_patient(),
          dict_data
        )

        # Get outlier details
        outlier_profile <- get_patient_outlier_profile(
          selected_patient(),
          range_violations(),
          iqr_outliers(),
          zscore_outliers(),
          dict_data
        )

        # Combine into report
        report <- list(
          summary = patient_row,
          missing_variables = if (!is.null(miss_profile)) {
            miss_profile$variable_details %>% filter(status == "Missing")
          } else {
            data.frame()
          },
          outliers = if (!is.null(outlier_profile)) outlier_profile else data.frame()
        )

        # Write summary section
        write_csv(report$summary, file)

        # Append missing variables
        if (nrow(report$missing_variables) > 0) {
          cat("\n\nMissing Variables:\n", file = file, append = TRUE)
          write_csv(report$missing_variables, file, append = TRUE)
        }

        # Append outliers
        if (nrow(report$outliers) > 0) {
          cat("\n\nOutliers:\n", file = file, append = TRUE)
          write_csv(report$outliers, file, append = TRUE)
        }
      }
    )

  })  # End moduleServer
}
