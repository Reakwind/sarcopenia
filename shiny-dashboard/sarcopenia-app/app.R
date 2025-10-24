# ============================================================================
# Sarcopenia Data Cleaning Shiny App - Version 2.1 (Modular)
# ============================================================================
# Modular architecture with organized R/ directory
# Core cleaning logic protected in R/fct_cleaning.R
# Scaffolding ready for analysis, visualization, and reports
#
# Version: 2.1-modular
# Last Modified: 2025-10-24
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

# ============================================================================
# SOURCE ALL R FILES (NOT a package - just regular source())
# ============================================================================

message("Loading modular components...")

# Core cleaning functions (PROTECTED)
source("R/fct_cleaning.R")

# Analysis functions (scaffold)
source("R/fct_analysis.R")

# Visualization functions (scaffold)
source("R/fct_visualization.R")

# Report generation functions (scaffold)
source("R/fct_reports.R")

# Utility functions
source("R/utils.R")

# Shiny modules (scaffolds)
source("R/mod_analysis.R")
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
  title = "Sarcopenia Data Cleaning v2.1",
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  sidebar = sidebar(
    width = 350,
    h4("Upload CSV"),
    fileInput("csv_file", "Choose Audit Report CSV",
              accept = c(".csv", "text/csv", "text/comma-separated-values")),

    actionButton("clean_btn", "Clean Data",
                class = "btn-primary",
                width = "100%"),

    hr(),

    h4("Download Cleaned Data"),
    downloadButton("download_visits", "Download Visits Data",
                  class = "btn-success mb-2", style = "width: 100%;"),
    downloadButton("download_ae", "Download Adverse Events",
                  class = "btn-success", style = "width: 100%;")
  ),

  navset_card_tab(
    nav_panel("Summary",
             card(
               card_header("Cleaning Summary"),
               tableOutput("summary_table")
             )),

    nav_panel("Visits Data",
             card(
               card_header("Visits Data Preview"),
               reactableOutput("visits_table")
             )),

    nav_panel("Adverse Events",
             card(
               card_header("Adverse Events Preview"),
               reactableOutput("ae_table")
             )),

    # Exploratory Data Analysis Tab
    nav_panel("Data Explorer", mod_visualization_ui("viz"))

    # TODO: Add additional analysis tabs here when ready:
    # nav_panel("Analysis", mod_analysis_ui("analysis")),
    # nav_panel("Reports", mod_reports_ui("reports"))
  )
)


# ============================================================================
# SHINY SERVER
# ============================================================================

server <- function(input, output, session) {

  # Reactive value to store cleaned data
  cleaned_data <- reactiveVal(NULL)

  # Clean data when button is clicked
  observeEvent(input$clean_btn, {
    req(input$csv_file)

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
        NULL
      })

      incProgress(0.5, detail = "Finalizing...")

      if (!is.null(result)) {
        cleaned_data(result)
        showNotification("Data cleaning complete!",
                        type = "message", duration = 3)
      }
    })
  })

  # Summary table
  output$summary_table <- renderTable({
    req(cleaned_data())

    sum_stats <- cleaned_data()$summary

    data.frame(
      Metric = c("Raw Data Rows", "Raw Data Columns",
                "Visits Rows", "Visits Columns",
                "Adverse Events Rows", "Adverse Events Columns",
                "Unique Patients"),
      Value = c(sum_stats$raw_rows, sum_stats$raw_cols,
               sum_stats$visits_rows, sum_stats$visits_cols,
               sum_stats$ae_rows, sum_stats$ae_cols,
               sum_stats$unique_patients)
    )
  })

  # Visits table
  output$visits_table <- renderReactable({
    req(cleaned_data())

    reactable(
      cleaned_data()$visits_data,
      filterable = TRUE,
      searchable = TRUE,
      defaultPageSize = 10,
      striped = TRUE,
      highlight = TRUE,
      resizable = TRUE,
      compact = TRUE,
      wrap = FALSE,
      defaultColDef = colDef(
        minWidth = 100,
        maxWidth = 300,
        align = "left",
        headerStyle = list(background = "#f7f7f8")
      ),
      theme = reactableTheme(
        borderColor = "#dfe2e5",
        stripedColor = "#f6f8fa",
        highlightColor = "#f0f5f9"
      )
    )
  })

  # Adverse events table
  output$ae_table <- renderReactable({
    req(cleaned_data())

    reactable(
      cleaned_data()$adverse_events_data,
      filterable = TRUE,
      searchable = TRUE,
      defaultPageSize = 10,
      striped = TRUE,
      highlight = TRUE,
      resizable = TRUE,
      compact = TRUE,
      wrap = FALSE,
      defaultColDef = colDef(
        minWidth = 100,
        maxWidth = 300,
        align = "left",
        headerStyle = list(background = "#f7f7f8")
      ),
      theme = reactableTheme(
        borderColor = "#dfe2e5",
        stripedColor = "#f6f8fa",
        highlightColor = "#f0f5f9"
      )
    )
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

  # Call visualization module server
  mod_visualization_server("viz", cleaned_data, dict)

  # TODO: Call additional module servers when ready:
  # mod_analysis_server("analysis", cleaned_data)
  # mod_reports_server("reports", cleaned_data)
}


# ============================================================================
# RUN APP
# ============================================================================

shinyApp(ui = ui, server = server)
