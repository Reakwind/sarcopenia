# ============================================================================
# Sarcopenia Data Cleaning Shiny App - Version 2.2 (Analysis Features)
# ============================================================================
# Modular architecture with organized R/ directory
# Core cleaning logic protected in R/fct_cleaning.R
# NEW: Descriptive statistics analysis module fully implemented
#
# Version: 2.2-analysis
# Last Modified: 2025-10-29
# ============================================================================

# ============================================================================
# LOAD REQUIRED LIBRARIES
# ============================================================================

library(shiny)
library(bslib)
library(reactable)
library(plotly)
library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(stringr)
library(forcats)
library(purrr)
library(rlang)
library(tibble)
library(shinyjs)

# ============================================================================
# SOURCE ALL R FILES (NOT a package - just regular source())
# ============================================================================

message("Loading modular components...")

# Core cleaning functions (PROTECTED)
source("R/fct_cleaning.R")

# Analysis functions (scaffold)
source("R/fct_analysis.R")

# Instrument analysis functions
source("R/fct_instrument_analysis.R")

# Visualization functions (scaffold)
source("R/fct_visualization.R")

# Report generation functions (scaffold)
source("R/fct_reports.R")

# Utility functions
source("R/utils.R")

# Data pipeline utilities (column resolution, validation, etc.)
source("R/utils_data_pipeline.R")

# Shiny modules (scaffolds)
source("R/mod_analysis.R")
source("R/mod_instrument_analysis.R")
source("R/mod_visualization.R")
source("R/mod_reports.R")

message("All components loaded successfully!")

# ============================================================================
# LOAD DATA DICTIONARY
# ============================================================================

dict <- read_csv("data_dictionary_enhanced.csv", show_col_types = FALSE)
message("Data dictionary loaded: ", nrow(dict), " variables")

# ============================================================================
# SHINY UI
# ============================================================================

ui <- page_sidebar(
  title = "Sarcopenia Data Surveillance v2.2",
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  # Custom CSS
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),

  sidebar = sidebar(
    width = 350,
    useShinyjs(),

    # ========================================================================
    # PROGRESSIVE DISCLOSURE: Steps reveal sequentially
    # ========================================================================

    # Step 1: Upload (ALWAYS VISIBLE)
    div(
      id = "step1_section",
      h4(icon("upload"), " Step 1: Upload Data File"),
      fileInput("csv_file", "Upload Your Data File (.csv format)",
                accept = c(".csv", "text/csv")),
      tags$script(HTML("
        $(document).ready(function() {
          $('input[type=file]').parent().attr('title', 'Upload the CSV file exported from your study database');
        });
      ")),
      helpText(icon("info-circle"),
               "If you have an Excel file, save it as 'CSV (Comma delimited)' first."),
      uiOutput("step1_status")
    ),

    # Step 2: Process (APPEARS after file uploaded)
    uiOutput("step2_section"),

    # Step 3: Download + Reset (APPEARS after data processed)
    uiOutput("step3_section")
  ),

  # File Preview Card (shown after upload, before processing)
  uiOutput("preview_card"),

  # ============================================================================
  # VERTICAL DASHBOARD LAYOUT (Progressive Disclosure)
  # ============================================================================
  # Dashboard sections appear only after Step 2 (data processing) completes

  uiOutput("dashboard_sections")
)


# ============================================================================
# SHINY SERVER
# ============================================================================

server <- function(input, output, session) {

  # Reactive value to store cleaned data
  cleaned_data <- reactiveVal(NULL)

  # File validation function
  validate_upload <- function(filepath, filename) {
    # Check file extension
    if (!grepl("\\.csv$", filename, ignore.case = TRUE)) {
      return(list(
        valid = FALSE,
        title = "Wrong File Type",
        message = HTML(paste0(
          "<p>You selected: <strong>", filename, "</strong></p>",
          "<p>This app requires a <strong>CSV file</strong>, not an Excel or other file type.</p>",
          "<hr>",
          "<p><strong>To convert Excel to CSV:</strong></p>",
          "<ol>",
          "<li>Open your file in Excel</li>",
          "<li>Click 'File' → 'Save As'</li>",
          "<li>Choose 'CSV (Comma delimited)' from the dropdown</li>",
          "<li>Save and upload the new .csv file here</li>",
          "</ol>"
        ))
      ))
    }

    # Check file size
    size_mb <- file.size(filepath) / 1024 / 1024
    if (size_mb > 100) {
      return(list(
        valid = FALSE,
        title = "File Too Large",
        message = HTML(paste0(
          "<p>This file is <strong>", round(size_mb, 1), " MB</strong>, which exceeds the 100 MB limit.</p>",
          "<p>Most study data exports are 1-10 MB. If your file is very large:</p>",
          "<ul>",
          "<li>Check if you exported unnecessary columns</li>",
          "<li>Consider splitting into smaller batches</li>",
          "<li>Contact support if you need to process larger files</li>",
          "</ul>"
        ))
      ))
    }

    # Try to read first line and check structure
    tryCatch({
      test_read <- read.csv(filepath, nrows = 1, header = TRUE, stringsAsFactors = FALSE)

      if (ncol(test_read) < 5) {
        return(list(
          valid = FALSE,
          title = "Data Structure Issue",
          message = HTML(paste0(
            "<p>This file has only <strong>", ncol(test_read), " columns</strong>.</p>",
            "<p>Expected patient data files should have many columns (demographics, test scores, etc.)</p>",
            "<p><strong>Common problems:</strong></p>",
            "<ul>",
            "<li>File was saved with wrong delimiter (try 'comma' delimited, not 'tab' or 'semicolon')</li>",
            "<li>File is empty or incomplete</li>",
            "<li>Wrong file selected</li>",
            "</ul>"
          ))
        ))
      }

    }, error = function(e) {
      return(list(
        valid = FALSE,
        title = "Cannot Read File",
        message = HTML(paste0(
          "<p>We couldn't read this file. It may be corrupted or in the wrong format.</p>",
          "<p><strong>Try these steps:</strong></p>",
          "<ul>",
          "<li>Re-export the data from your database</li>",
          "<li>Ensure it's saved as CSV (comma delimited)</li>",
          "<li>Open in a text editor to check it looks like data (not garbled text)</li>",
          "</ul>",
          "<p class='text-muted'><small>Technical error: ", e$message, "</small></p>"
        ))
      ))
    })

    # All checks passed
    return(list(valid = TRUE, message = "File is valid!"))
  }

  # ============================================================================
  # PROGRESSIVE DISCLOSURE: Step Rendering
  # ============================================================================

  # Step 1 Status: Show completion when file uploaded
  output$step1_status <- renderUI({
    if (is.null(input$csv_file)) {
      NULL
    } else {
      div(
        style = "margin-top: 10px; padding: 10px; background-color: #d4edda; border-radius: 5px; border-left: 3px solid #28a745;",
        icon("check-circle", style = "color: #28a745;"),
        span(" File uploaded: ", style = "color: #155724; font-weight: 600;"),
        span(input$csv_file$name, style = "color: #155724;")
      )
    }
  })

  # Step 2 Section: Reveal after file uploaded
  output$step2_section <- renderUI({
    req(input$csv_file)

    div(
      class = "step-section",
      hr(),
      if (is.null(cleaned_data())) {
        # Step 2 active - show process button
        tagList(
          h4(icon("cogs"), " Step 2: Process Data"),
          actionButton("clean_btn", "Process Data",
                      class = "btn-primary",
                      width = "100%",
                      title = "Fills missing demographics, detects unusual values, and prepares data for statistical analysis"),
          helpText(class = "text-muted", style = "margin-top: 8px; font-size: 0.85em;",
                  "Prepare your data for analysis")
        )
      } else {
        # Step 2 completed - show status
        tagList(
          h4(icon("check-circle", style = "color: #28a745;"), " Step 2: Process Data"),
          div(
            style = "padding: 10px; background-color: #d4edda; border-radius: 5px; border-left: 3px solid #28a745;",
            icon("check-circle", style = "color: #28a745;"),
            sprintf(" %d rows, %d patients processed",
                    cleaned_data()$summary$visits_rows,
                    cleaned_data()$summary$unique_patients),
            style = "color: #155724; font-weight: 600;"
          )
        )
      }
    )
  })

  # Step 3 Section: Reveal after data processed
  output$step3_section <- renderUI({
    req(cleaned_data())

    div(
      class = "step-section",
      hr(),
      h4(icon("download"), " Step 3: Download Results"),
      downloadButton("download_visits",
                    HTML("📊 Patient Visit Data"),
                    class = "btn-success mb-2", style = "width: 100%;",
                    title = "Download all patient assessments and test scores (CSV format, can be opened in Excel)"),
      helpText(class = "text-muted", style = "margin-top: -8px; margin-bottom: 12px; font-size: 0.8em;",
               "All test scores and assessments"),
      downloadButton("download_ae",
                    HTML("🚨 Safety Events"),
                    class = "btn-success", style = "width: 100%;",
                    title = "Download falls, hospitalizations, and adverse events (CSV format)"),
      helpText(class = "text-muted", style = "margin-top: -8px; margin-bottom: 12px; font-size: 0.8em;",
               "Falls, hospitalizations, adverse events"),
      hr(),
      actionButton("reset_btn",
                  HTML("🔄 Start Over"),
                  class = "btn-secondary",
                  style = "width: 100%;",
                  title = "Clear all data and start fresh without refreshing the page"),
      helpText(class = "text-muted", style = "margin-top: -8px; font-size: 0.8em;",
               "Reset the app to upload new data")
    )
  })

  # Dashboard Sections: Reveal after data processed (progressive disclosure)
  output$dashboard_sections <- renderUI({
    if (is.null(cleaned_data())) {
      # Show empty state before processing
      div(
        id = "dashboard_empty_state",
        style = "margin-top: 40px;",
        card(
          card_body(
            style = "text-align: center; padding: 80px 20px; color: #6c757d;",
            icon("chart-line", class = "fa-4x", style = "color: #dee2e6; margin-bottom: 20px;"),
            h3("Dashboard Awaiting Data", style = "color: #6c757d; margin-bottom: 15px;"),
            p(style = "font-size: 1.15em; max-width: 600px; margin: 0 auto; line-height: 1.6;",
              "Upload your data file and click ",
              tags$strong("'Process Data'"),
              " in the sidebar to unlock the analysis dashboard."
            ),
            p(style = "font-size: 0.95em; color: #adb5bd; margin-top: 20px;",
              icon("info-circle"),
              " You'll see Summary Statistics, Patient Surveillance, and Instrument Analysis here."
            )
          )
        )
      )
    } else {
      # Show all three dashboard sections after processing
      tagList(
        # Summary Section
        div(
          id = "summary_section",
          class = "dashboard-section",
          style = "margin-bottom: 20px;",
          card(
            card_header(
              icon("chart-bar"),
              " Summary Statistics"
            ),
            uiOutput("summary_content")
          )
        ),

        # Patient Surveillance Section
        div(
          id = "patient_section",
          class = "dashboard-section",
          style = "margin-bottom: 20px;",
          card(
            card_header(
              icon("user"),
              " Patient Surveillance"
            ),
            mod_analysis_ui("analysis")
          )
        ),

        # Instrument Analysis Section
        div(
          id = "instrument_section",
          class = "dashboard-section",
          card(
            card_header(
              icon("microscope"),
              " Instrument Analysis"
            ),
            mod_instrument_analysis_ui("instruments")
          )
        )
      )
    }
  })

  # Reset button - start over without refreshing
  observeEvent(input$reset_btn, {
    # Clear uploaded file
    shinyjs::reset("csv_file")

    # Clear processed data
    cleaned_data(NULL)

    # Show confirmation
    showNotification("App reset! Upload a new file to begin.",
                    type = "message", duration = 3)

    # Note: Steps 2 & 3 will automatically disappear when reactive conditions fail
  })

  # File validation (show error modal if invalid)
  observe({
    req(input$csv_file)

    # Validate file
    validation <- validate_upload(input$csv_file$datapath, input$csv_file$name)

    if (!validation$valid) {
      # Validation failed - show error modal
      showModal(modalDialog(
        title = validation$title,
        validation$message,
        footer = modalButton("OK"),
        easyClose = TRUE
      ))
    }
  })

  # Render file preview card when valid file is uploaded
  output$preview_card <- renderUI({
    req(input$csv_file)

    # Only show preview if file validated successfully
    validation <- validate_upload(input$csv_file$datapath, input$csv_file$name)

    if (!validation$valid) {
      return(NULL)
    }

    # Read first 5 rows for preview
    preview_data <- tryCatch({
      read_csv(input$csv_file$datapath,
              n_max = 5,
              show_col_types = FALSE,
              col_types = cols(.default = "c"))
    }, error = function(e) {
      NULL
    })

    if (is.null(preview_data)) {
      return(NULL)
    }

    # Limit to first 20 columns for display
    max_preview_cols <- 20
    preview_cols <- min(ncol(preview_data), max_preview_cols)
    preview_display <- preview_data[, 1:preview_cols]

    card(
      card_header(
        icon("eye"),
        " File Preview",
        span(class = "text-muted", style = "font-weight: normal; font-size: 0.9em; margin-left: 10px;",
             paste0("(Showing first 5 rows, ", preview_cols, " of ", ncol(preview_data), " columns)"))
      ),
      card_body(
        p(class = "text-muted",
          icon("check-circle"),
          " Check this looks correct before clicking 'Process Data' below."
        ),
        reactable::reactable(
          preview_display,
          defaultPageSize = 5,
          compact = TRUE,
          striped = TRUE,
          highlight = TRUE,
          wrap = FALSE,
          resizable = TRUE,
          defaultColDef = reactable::colDef(
            minWidth = 100,
            headerStyle = list(background = "#f7f7f7", fontWeight = "bold", fontSize = "13px")
          ),
          theme = reactable::reactableTheme(
            borderColor = "#dfe2e5",
            highlightColor = "#f0f5f9"
          )
        )
      )
    )
  })

  # Clean data when button is clicked
  observeEvent(input$clean_btn, {
    req(input$csv_file)

    # Show loading state
    disable("clean_btn")
    html("clean_btn",
         paste('<i class="fa fa-spinner fa-spin"></i>', "Processing..."))

    withProgress(message = 'Cleaning data...', value = 0, {

      incProgress(0.2, detail = "Reading CSV...")
      raw_data <- read_csv(input$csv_file$datapath,
                          show_col_types = FALSE,
                          col_types = cols(.default = "c"),
                          na = character())

      incProgress(0.3, detail = "Applying cleaning rules...")
      result <- tryCatch({
        clean_csv(raw_data)  # Calls function from R/fct_cleaning.R
      }, error = function(e) {
        showNotification(paste("Error:", e$message),
                        type = "error", duration = 10)

        # Reset button on error
        enable("clean_btn")
        html("clean_btn", "Clean Data")

        NULL
      })

      incProgress(0.5, detail = "Finalizing...")

      if (!is.null(result)) {
        cleaned_data(result)

        showNotification("Data cleaning complete!",
                        type = "message", duration = 3)

        # Note: Step 3 will automatically appear when cleaned_data() is not null
      }
    })
  })

  # Summary content (shows empty state or summary table)
  output$summary_content <- renderUI({
    req(cleaned_data())  # Safety check - only render when data exists

    if (is.null(cleaned_data())) {
      # Empty state - no data processed yet
      tagList(
        div(
          style = "text-align: center; padding: 60px 20px; color: #6c757d;",
          icon("database", class = "fa-3x", style = "color: #dee2e6; margin-bottom: 20px;"),
          h4("No Data Processed Yet", style = "color: #6c757d; margin-bottom: 10px;"),
          p(style = "font-size: 1.1em; max-width: 500px; margin: 0 auto;",
            "Upload your data file in the sidebar and click 'Process Data' to see summary statistics here.")
        )
      )
    } else {
      # Show summary table using HTML tags
      sum_stats <- cleaned_data()$summary

      tags$table(
        class = "table table-striped",
        style = "width: auto; margin: 20px auto;",
        tags$thead(
          tags$tr(
            tags$th("Metric", style = "text-align: left; padding: 12px;"),
            tags$th("Value", style = "text-align: right; padding: 12px;")
          )
        ),
        tags$tbody(
          tags$tr(
            tags$td("Raw Data Rows", style = "padding: 10px;"),
            tags$td(sum_stats$raw_rows, style = "text-align: right; padding: 10px;")
          ),
          tags$tr(
            tags$td("Raw Data Columns", style = "padding: 10px;"),
            tags$td(sum_stats$raw_cols, style = "text-align: right; padding: 10px;")
          ),
          tags$tr(
            tags$td("Visits Rows", style = "padding: 10px;"),
            tags$td(sum_stats$visits_rows, style = "text-align: right; padding: 10px;")
          ),
          tags$tr(
            tags$td("Visits Columns", style = "padding: 10px;"),
            tags$td(sum_stats$visits_cols, style = "text-align: right; padding: 10px;")
          ),
          tags$tr(
            tags$td("Adverse Events Rows", style = "padding: 10px;"),
            tags$td(sum_stats$ae_rows, style = "text-align: right; padding: 10px;")
          ),
          tags$tr(
            tags$td("Adverse Events Columns", style = "padding: 10px;"),
            tags$td(sum_stats$ae_cols, style = "text-align: right; padding: 10px;")
          ),
          tags$tr(
            tags$td("Unique Patients", style = "padding: 10px;"),
            tags$td(sum_stats$unique_patients, style = "text-align: right; padding: 10px;")
          )
        )
      )
    }
  })

  # Download visits data
  output$download_visits <- downloadHandler(
    filename = function() {
      paste0("visits_data_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      req(cleaned_data())
      write_csv(cleaned_data()$visits_data, file)
    }
  )

  # Download adverse events data
  output$download_ae <- downloadHandler(
    filename = function() {
      paste0("adverse_events_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      req(cleaned_data())
      write_csv(cleaned_data()$adverse_events_data, file)
    }
  )

  # Call analysis module server (Patient Surveillance)
  mod_analysis_server("analysis", cleaned_data, dict)

  # Call instrument analysis module server
  mod_instrument_analysis_server("instruments", cleaned_data, dict)
}


# ============================================================================
# RUN APP
# ============================================================================

shinyApp(ui = ui, server = server)
