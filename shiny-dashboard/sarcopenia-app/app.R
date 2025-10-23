# ============================================================================
# Sarcopenia Data Cleaning Shiny App - Version 2.0
# ============================================================================
# Enhanced cleaning pipeline with proper missingness logic
# Uses enhanced data dictionary with variable categorization

# Load required libraries
library(shiny)
library(bslib)
library(reactable)
library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(stringr)
library(forcats)

# ============================================================================
# DATA CLEANING FUNCTIONS
# ============================================================================

#' Clean uploaded CSV file
#'
#' @param raw_data Dataframe from uploaded CSV
#' @return List with visits_data, adverse_events_data, and summary
clean_csv <- function(raw_data) {

  message("Starting data cleaning (v2.0)...")

  # Validate input
  if (!inherits(raw_data, "data.frame")) {
    stop("Input must be a dataframe")
  }

  if (nrow(raw_data) == 0) {
    stop("Input dataframe has zero rows")
  }

  # Load ENHANCED data dictionary
  dict_path <- "data_dictionary_enhanced.csv"
  if (!file.exists(dict_path)) {
    stop("Enhanced data dictionary not found. Please ensure data_dictionary_enhanced.csv exists.")
  }

  dict <- read_csv(dict_path, show_col_types = FALSE)

  # Validate dictionary has required metadata
  if (!"variable_category" %in% names(dict)) {
    stop("Data dictionary missing 'variable_category' column. Use enhanced dictionary.")
  }

  # Step 1: Remove section marker columns
  section_markers <- c(
    "Personal Information FINAL",
    "Physician evaluation FINAL",
    "Physical Health Agility FINAL",
    "Cognitive Health Agility- Final",
    "Adverse events FINAL",
    "Body composition FINAL"
  )

  raw_data <- raw_data[, !(names(raw_data) %in% section_markers), drop = FALSE]

  # Step 2: Apply variable name mapping
  cleaned_data <- apply_variable_mapping(raw_data, dict)

  # Step 3: Remove duplicate identifier fields
  dup_pattern <- "^demo_participants_study_number_v[2-9]|^demo_date_of_birth_.*v[2-9]"
  dup_cols <- grep(dup_pattern, names(cleaned_data), value = TRUE)
  if (length(dup_cols) > 0) {
    cleaned_data <- cleaned_data[, !(names(cleaned_data) %in% dup_cols), drop = FALSE]
  }

  # Step 4: Split into visits and adverse events
  datasets <- split_visits_and_ae(cleaned_data)

  # Step 5: Convert patient-level missing data (CRITICAL FIRST STEP!)
  datasets$visits_data <- convert_patient_level_na(datasets$visits_data, dict)

  # Step 6: Fill time-invariant variables within patient
  datasets$visits_data <- fill_time_invariant(datasets$visits_data, dict)

  # Step 7: Create dual analysis columns for time-varying variables
  datasets$visits_data <- create_analysis_columns(datasets$visits_data, dict)

  # Step 8: Generate summary
  summary_stats <- generate_summary(raw_data, datasets$visits_data, datasets$adverse_events_data)

  message("Data cleaning complete (v2.0)!")

  list(
    visits_data = datasets$visits_data,
    adverse_events_data = datasets$adverse_events_data,
    summary = summary_stats
  )
}


#' Apply variable name mapping from data dictionary
apply_variable_mapping <- function(data, dict) {
  message("Applying variable name mapping...")

  # Create mapping from original to new names
  mapping <- setNames(dict$new_name, dict$original_name)

  # Rename columns that exist in the mapping
  for (old_name in names(data)) {
    if (old_name %in% names(mapping)) {
      new_name <- mapping[[old_name]]
      names(data)[names(data) == old_name] <- new_name
    }
  }

  data
}


#' Split data into visits and adverse events
split_visits_and_ae <- function(data) {
  message("Splitting visits and adverse events...")

  # Adverse events have ae_ prefix
  ae_cols <- grep("^ae_", names(data), value = TRUE)
  id_cols <- grep("^id_", names(data), value = TRUE)

  # AE data: id columns + ae columns
  ae_data <- data[, c(id_cols, ae_cols), drop = FALSE]

  # Visits data: everything except ae columns
  visits_data <- data[, !(names(data) %in% ae_cols), drop = FALSE]

  list(
    visits_data = visits_data,
    adverse_events_data = ae_data
  )
}


#' Convert Patient-Level Missing Data
#'
#' Convert empty strings to NA ONLY when empty across all patient visits
#' This is the CRITICAL first step - must happen before any filling
#'
#' @param data Dataframe with id_client_id column
#' @param dict Enhanced data dictionary with variable_category column
#' @return Dataframe with patient-level "" → NA conversion
convert_patient_level_na <- function(data, dict) {
  message("[CONVERT_NA] Starting patient-level NA conversion...")
  message("[CONVERT_NA] Input: ", nrow(data), " rows, ", ncol(data), " columns")

  # Validate inputs
  if (!"id_client_id" %in% names(data)) {
    stop("id_client_id column not found in data")
  }

  if (!"variable_category" %in% names(dict)) {
    stop("variable_category column not found in dictionary. Use enhanced dictionary.")
  }

  # Get non-adverse-event columns that exist in data
  target_cols <- dict %>%
    filter(variable_category != "adverse_event") %>%
    pull(new_name) %>%
    intersect(names(data))

  message("[CONVERT_NA] Processing ", length(target_cols), " non-adverse-event columns")

  # Get unique patients
  patient_ids <- unique(data$id_client_id)
  message("[CONVERT_NA] Found ", length(patient_ids), " unique patients")

  # Track conversions
  conversion_count <- 0

  # For each target column
  for (col in target_cols) {
    # For each patient
    for (pid in patient_ids) {
      # Get patient's rows
      patient_mask <- data$id_client_id == pid
      patient_values <- data[[col]][patient_mask]

      # Check if ALL values are empty string or already NA
      all_empty <- all(is.na(patient_values) | patient_values == "")

      # Check if at least one is empty (not NA)
      has_empty <- any(!is.na(patient_values) & patient_values == "")

      if (all_empty && has_empty) {
        # Convert all empty strings to NA for this patient-column combination
        data[[col]][patient_mask] <- NA
        conversion_count <- conversion_count + sum(patient_values == "", na.rm = TRUE)
      }
    }
  }

  message("[CONVERT_NA] Converted ", conversion_count, " patient-level empty strings to NA")
  message("[CONVERT_NA] Complete!")

  return(data)
}


#' Fill Time-Invariant Variables Within Patient
#'
#' Fill time-invariant variables (demographics, baseline medical, units)
#' within each patient using first non-missing value
#' MUST be called AFTER convert_patient_level_na()
#'
#' @param data Dataframe with patient-level NAs converted
#' @param dict Enhanced data dictionary with variable_category column
#' @return Dataframe with time-invariant variables filled
fill_time_invariant <- function(data, dict) {
  message("[FILL] Starting time-invariant variable filling...")
  message("[FILL] Input: ", nrow(data), " rows")

  # Validate
  if (!"id_client_id" %in% names(data)) {
    stop("id_client_id column not found in data")
  }

  # Get time-invariant columns that exist in data
  time_inv_cols <- dict %>%
    filter(variable_category == "time_invariant") %>%
    pull(new_name) %>%
    intersect(names(data))

  message("[FILL] Found ", length(time_inv_cols), " time-invariant columns")

  if (length(time_inv_cols) == 0) {
    message("[FILL] No time-invariant columns to fill")
    return(data)
  }

  patient_ids <- unique(data$id_client_id)
  total_filled <- 0

  # For each time-invariant column
  for (col in time_inv_cols) {
    filled_this_col <- 0

    # For each patient
    for (pid in patient_ids) {
      patient_mask <- data$id_client_id == pid
      patient_indices <- which(patient_mask)
      patient_values <- data[[col]][patient_indices]

      # Get first non-NA, non-empty value
      non_missing <- patient_values[!is.na(patient_values) & patient_values != ""]

      if (length(non_missing) > 0) {
        fill_value <- non_missing[1]

        # Fill all NAs and empty strings
        for (idx in patient_indices) {
          if (is.na(data[[col]][idx]) || data[[col]][idx] == "") {
            data[[col]][idx] <- fill_value
            filled_this_col <- filled_this_col + 1
          }
        }
      }
    }

    if (filled_this_col > 0) {
      message("[FILL] Filled ", filled_this_col, " values in: ", col)
      total_filled <- total_filled + filled_this_col
    }
  }

  message("[FILL] Total filled: ", total_filled, " values across ", length(time_inv_cols), " columns")
  message("[FILL] Complete!")

  return(data)
}


#' Create Analysis Columns for Time-Varying Variables
#'
#' Creates dual columns for time-varying variables:
#' - Original: Character (preserves "" vs NA distinction)
#' - Analysis: _numeric/_factor/_date (both "" and NA → NA for stats)
#'
#' @param data Dataframe with filled time-invariant vars
#' @param dict Enhanced data dictionary
#' @return Dataframe with additional analysis columns
create_analysis_columns <- function(data, dict) {
  message("[DUAL_COL] Creating analysis columns for time-varying variables...")

  # Get time-varying variables by data type (that exist in data)
  time_var_numeric <- dict %>%
    filter(variable_category == "time_varying", data_type == "numeric") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_binary <- dict %>%
    filter(variable_category == "time_varying", data_type == "binary") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_categorical <- dict %>%
    filter(variable_category == "time_varying", data_type == "categorical") %>%
    pull(new_name) %>%
    intersect(names(data))

  time_var_date <- dict %>%
    filter(variable_category == "time_varying", data_type == "date") %>%
    pull(new_name) %>%
    intersect(names(data))

  message("[DUAL_COL] Time-varying numeric: ", length(time_var_numeric))
  message("[DUAL_COL] Time-varying binary: ", length(time_var_binary))
  message("[DUAL_COL] Time-varying categorical: ", length(time_var_categorical))
  message("[DUAL_COL] Time-varying date: ", length(time_var_date))

  # Create numeric analysis columns
  for (col in time_var_numeric) {
    new_col_name <- paste0(col, "_numeric")

    # Handle fractions (e.g., "36/41") before converting to numeric
    values <- data[[col]]
    values <- ifelse(
      !is.na(values) & grepl("/", values),
      sub("/.*", "", values),  # Extract first number from fraction
      values
    )

    data[[new_col_name]] <- suppressWarnings(as.numeric(values))
  }

  # Create binary/categorical factor columns
  for (col in c(time_var_binary, time_var_categorical)) {
    new_col_name <- paste0(col, "_factor")
    # Only factorize non-empty, non-NA values
    data[[new_col_name]] <- ifelse(
      is.na(data[[col]]) | data[[col]] == "",
      NA,
      data[[col]]
    )
    # Convert to factor only if has values
    if (any(!is.na(data[[new_col_name]]))) {
      data[[new_col_name]] <- as.factor(data[[new_col_name]])
    }
  }

  # Create date columns
  for (col in time_var_date) {
    new_col_name <- paste0(col, "_date")
    data[[new_col_name]] <- tryCatch({
      parsed <- parse_date_time(
        data[[col]],
        orders = c("ymd", "dmy", "mdy"),
        quiet = TRUE
      )
      as.Date(parsed)
    }, error = function(e) {
      rep(NA, nrow(data))
    })
  }

  total_created <- length(time_var_numeric) + length(time_var_binary) +
                   length(time_var_categorical) + length(time_var_date)

  message("[DUAL_COL] Created ", total_created, " analysis columns")
  message("[DUAL_COL] Complete!")

  return(data)
}


#' Generate cleaning summary statistics
generate_summary <- function(raw_data, visits_data, ae_data) {
  list(
    raw_rows = nrow(raw_data),
    raw_cols = ncol(raw_data),
    visits_rows = nrow(visits_data),
    visits_cols = ncol(visits_data),
    ae_rows = nrow(ae_data),
    ae_cols = ncol(ae_data),
    unique_patients = length(unique(visits_data$id_client_id))
  )
}


# ============================================================================
# SHINY UI
# ============================================================================

ui <- page_sidebar(
  title = "Sarcopenia Data Cleaning v2.0",
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
             ))
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
        clean_csv(raw_data)
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
}


# ============================================================================
# RUN APP
# ============================================================================

shinyApp(ui = ui, server = server)
