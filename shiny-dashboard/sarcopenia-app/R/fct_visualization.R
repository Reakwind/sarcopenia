# ============================================================================
# DATA VISUALIZATION FUNCTIONS - EXPLORATORY DATA ANALYSIS
# ============================================================================
#
# Functions for exploratory data analysis with emphasis on:
# - Missingness patterns (respecting patient-level "" vs NA logic)
# - Data quality visualization
# - Instrument completion tracking
#
# SAFE TO MODIFY - These functions work on cleaned_data() output
# ============================================================================

#' Analyze Missingness Patterns
#'
#' Analyzes missingness for each variable using 2-category logic:
#' - Has data (non-empty, non-NA)
#' - Missing (NA only - truly missing after patient-level cleaning)
#'
#' Note: Empty strings ("") are NOT counted as missing. After the cleaning
#' pipeline, empty strings mean "test not performed this visit" but the patient
#' has data for this variable in other visits. Only NA represents truly missing data.
#'
#' @param data Cleaned visits data (use original columns, not _numeric)
#' @param dict Data dictionary with instrument metadata
#' @return Dataframe with missingness analysis per variable
#' @export
analyze_missingness <- function(data, dict) {
  message("[MISSINGNESS] Analyzing missingness patterns...")

  # Exclude identifier and analysis columns
  exclude_patterns <- c("^id_", "_numeric$", "_factor$", "_date$", "_unit$")

  # Get variable list
  all_vars <- names(data)
  vars_to_analyze <- all_vars[!grepl(paste(exclude_patterns, collapse = "|"), all_vars)]

  message("[MISSINGNESS] Analyzing ", length(vars_to_analyze), " variables")

  # Analyze each variable
  results <- lapply(vars_to_analyze, function(var) {
    values <- data[[var]]

    n_total <- length(values)
    # Has data = non-empty AND non-NA
    n_has_data <- sum(!is.na(values) & values != "", na.rm = TRUE)
    # Missing = NA only (empty strings are NOT missing)
    n_missing <- sum(is.na(values))

    pct_has_data <- (n_has_data / n_total) * 100
    pct_missing <- (n_missing / n_total) * 100

    # Get metadata from dictionary
    dict_row <- dict[dict$new_name == var, ]
    instrument <- if (nrow(dict_row) > 0) dict_row$instrument else NA
    section <- if (nrow(dict_row) > 0) dict_row$section else NA
    var_category <- if (nrow(dict_row) > 0) dict_row$variable_category else NA

    data.frame(
      variable = var,
      instrument = instrument,
      section = section,
      variable_category = var_category,
      n_total = n_total,
      n_has_data = n_has_data,
      n_missing = n_missing,
      pct_has_data = round(pct_has_data, 1),
      pct_missing = round(pct_missing, 1),
      stringsAsFactors = FALSE
    )
  })

  results_df <- do.call(rbind, results)

  message("[MISSINGNESS] Analysis complete!")
  return(results_df)
}


#' Create Interactive Missingness Heatmap
#'
#' Creates plotly heatmap showing missingness pattern for selected variables
#' using 2-color scheme (Has Data vs Missing/NA only)
#'
#' @param data Cleaned visits data
#' @param variables Vector of variable names to include
#' @param patient_ids Optional: specific patient IDs to show (NULL = all)
#' @return plotly heatmap object
#' @export
create_missingness_heatmap <- function(data, variables, patient_ids = NULL) {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop("Package 'plotly' is required for this function. Please install it with: install.packages('plotly')")
  }

  message("[HEATMAP] Creating missingness heatmap...")

  # Filter patients if specified
  if (!is.null(patient_ids)) {
    data <- data[data$id_client_id %in% patient_ids, ]
  }

  # Create matrix for heatmap
  patient_list <- unique(data$id_client_id)
  n_patients <- length(patient_list)
  n_vars <- length(variables)

  message("[HEATMAP] ", n_patients, " patients x ", n_vars, " variables")

  # Build matrix: rows = patients, cols = variables
  # 0 = Has Data (non-empty, non-NA)
  # 1 = Missing (NA only)
  miss_matrix <- matrix(NA, nrow = n_patients, ncol = n_vars)
  rownames(miss_matrix) <- patient_list
  colnames(miss_matrix) <- variables

  for (i in seq_along(patient_list)) {
    patient_data <- data[data$id_client_id == patient_list[i], ]

    for (j in seq_along(variables)) {
      var <- variables[j]
      if (var %in% names(patient_data)) {
        values <- patient_data[[var]]

        # 2-category logic: Has data vs Missing (NA)
        # Empty strings ("") are treated as "has data" (not missing)
        if (any(!is.na(values) & values != "")) {
          miss_matrix[i, j] <- 0  # Has data
        } else {
          miss_matrix[i, j] <- 1  # Missing (NA)
        }
      } else {
        miss_matrix[i, j] <- 1  # Variable not in data = missing
      }
    }
  }

  # Create plotly heatmap with 2-color scheme
  fig <- plot_ly(
    x = variables,
    y = patient_list,
    z = miss_matrix,
    type = "heatmap",
    colors = c("#2ecc71", "#e74c3c"),  # Green, Red
    colorscale = list(
      c(0, "#2ecc71"),    # Has data = green
      c(1, "#e74c3c")     # Missing (NA) = red
    ),
    hovertemplate = paste(
      "Patient: %{y}<br>",
      "Variable: %{x}<br>",
      "Status: %{z}<br>",
      "<extra></extra>"
    ),
    showscale = TRUE,
    colorbar = list(
      title = "Status",
      tickvals = c(0, 1),
      ticktext = c("Has Data", "Missing")
    )
  ) %>%
    layout(
      title = list(
        text = paste0("Missingness Heatmap<br><sub>n = ", n_patients, " patients</sub>"),
        x = 0
      ),
      xaxis = list(title = "Variables", tickangle = -45),
      yaxis = list(title = "Patients"),
      margin = list(b = 150)
    )

  message("[HEATMAP] Heatmap created!")
  return(fig)
}


#' Summarize Missingness by Instrument
#'
#' Creates summary table of missingness statistics by instrument
#'
#' @param missingness_analysis Output from analyze_missingness()
#' @return Dataframe with instrument-level summary
#' @export
summarize_missingness_by_instrument <- function(missingness_analysis) {
  message("[SUMMARY] Summarizing by instrument...")

  # Remove NAs from instrument column for grouping
  miss_with_inst <- missingness_analysis[!is.na(missingness_analysis$instrument), ]

  if (nrow(miss_with_inst) == 0) {
    message("[SUMMARY] No instrument metadata found")
    return(data.frame())
  }

  # Group by instrument
  summary <- miss_with_inst %>%
    group_by(instrument) %>%
    summarise(
      n_variables = n(),
      avg_pct_data = round(mean(pct_has_data, na.rm = TRUE), 1),
      avg_pct_missing = round(mean(pct_missing, na.rm = TRUE), 1),
      min_completion = round(min(pct_has_data, na.rm = TRUE), 1),
      max_completion = round(max(pct_has_data, na.rm = TRUE), 1),
      .groups = "drop"
    ) %>%
    arrange(desc(avg_pct_data))

  message("[SUMMARY] Summary complete for ", nrow(summary), " instruments")
  return(as.data.frame(summary))
}


#' Get Patient Missingness Profile
#'
#' Analyzes missingness for a specific patient
#'
#' @param data Cleaned visits data
#' @param patient_id Patient ID to analyze
#' @param dict Data dictionary
#' @return List with patient profile information
#' @export
get_patient_missingness_profile <- function(data, patient_id, dict) {
  message("[PATIENT] Analyzing patient: ", patient_id)

  patient_data <- data[data$id_client_id == patient_id, ]

  if (nrow(patient_data) == 0) {
    message("[PATIENT] Patient not found")
    return(NULL)
  }

  # Exclude identifier and analysis columns
  exclude_patterns <- c("^id_", "_numeric$", "_factor$", "_date$", "_unit$")
  all_vars <- names(patient_data)
  vars_to_check <- all_vars[!grepl(paste(exclude_patterns, collapse = "|"), all_vars)]

  # Get visit column for visit-level detail
  visit_col <- grep("visit", names(patient_data), ignore.case = TRUE, value = TRUE)[1]

  # Analyze each variable for this patient
  var_status <- lapply(vars_to_check, function(var) {
    values <- patient_data[[var]]

    # 2-category logic: Has data vs Missing (NA only)
    has_data <- any(!is.na(values) & values != "")

    status <- if (has_data) {
      "Has Data"
    } else {
      "Missing"  # NA only (empty strings not counted as missing)
    }

    # NEW: Identify which specific visits have missing data (NA only)
    if (!is.null(visit_col)) {
      visits_with_na <- patient_data[[visit_col]][is.na(values)]

      if (length(visits_with_na) > 0) {
        # Sort and create comma-separated list
        visits_missing <- paste(sort(unique(visits_with_na)), collapse = ", ")
      } else {
        visits_missing <- "None"
      }
    } else {
      visits_missing <- "Unknown (no visit column)"
    }

    # Get instrument
    dict_row <- dict[dict$new_name == var, ]
    instrument <- if (nrow(dict_row) > 0) dict_row$instrument else NA

    data.frame(
      variable = var,
      instrument = instrument,
      status = status,
      n_visits = nrow(patient_data),
      visits_missing = visits_missing,  # NEW COLUMN
      stringsAsFactors = FALSE
    )
  })

  profile <- do.call(rbind, var_status)

  # Summary statistics
  n_with_data <- sum(profile$status == "Has Data")
  n_missing <- sum(profile$status == "Missing")

  result <- list(
    patient_id = patient_id,
    n_visits = nrow(patient_data),
    n_variables_total = nrow(profile),
    n_with_data = n_with_data,
    n_missing = n_missing,
    variable_details = profile
  )

  message("[PATIENT] Profile complete: ", n_with_data, " vars with data, ",
          n_missing, " missing")

  return(result)
}


#' Create Visit Completion Timeline
#'
#' Shows % completion over visits
#'
#' @param data Cleaned visits data
#' @param dict Data dictionary
#' @param instrument_filter Optional: filter by specific instrument
#' @return plotly line plot
#' @export
create_visit_completion_timeline <- function(data, dict, instrument_filter = NULL) {
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop("Package 'plotly' is required for this function. Please install it with: install.packages('plotly')")
  }

  message("[TIMELINE] Creating completion timeline...")

  # Get visit numbers
  if (!"id_visit_no" %in% names(data)) {
    message("[TIMELINE] Visit number column not found")
    return(NULL)
  }

  # Exclude identifier and analysis columns
  exclude_patterns <- c("^id_", "_numeric$", "_factor$", "_date$", "_unit$")
  all_vars <- names(data)
  vars_to_check <- all_vars[!grepl(paste(exclude_patterns, collapse = "|"), all_vars)]

  # Filter by instrument if specified
  if (!is.null(instrument_filter)) {
    dict_filtered <- dict[dict$instrument == instrument_filter & !is.na(dict$instrument), ]
    vars_to_check <- intersect(vars_to_check, dict_filtered$new_name)
  }

  # Calculate completion by visit
  visits <- sort(unique(data$id_visit_no))
  completion_by_visit <- sapply(visits, function(visit) {
    visit_data <- data[data$id_visit_no == visit, vars_to_check]

    total_cells <- prod(dim(visit_data))
    if (total_cells == 0) return(0)

    has_data <- sum(sapply(visit_data, function(col) {
      sum(!is.na(col) & col != "", na.rm = TRUE)
    }))

    (has_data / total_cells) * 100
  })

  # Create plot
  fig <- plot_ly(
    x = visits,
    y = completion_by_visit,
    type = "scatter",
    mode = "lines+markers",
    marker = list(size = 10),
    line = list(width = 2),
    hovertemplate = paste(
      "Visit: %{x}<br>",
      "Completion: %{y:.1f}%<br>",
      "<extra></extra>"
    )
  ) %>%
    layout(
      title = list(
        text = if (!is.null(instrument_filter)) {
          paste0("Completion Timeline - ", instrument_filter,
                 "<br><sub>n = ", nrow(data), " observations</sub>")
        } else {
          paste0("Overall Completion Timeline<br><sub>n = ", nrow(data), " observations</sub>")
        },
        x = 0
      ),
      xaxis = list(title = "Visit Number"),
      yaxis = list(title = "% Completion", range = c(0, 100)),
      hovermode = "closest"
    )

  message("[TIMELINE] Timeline created!")
  return(fig)
}


#' Helper: Get Variables by Instrument
#'
#' Extract variable names for a specific instrument
#'
#' @param dict Data dictionary
#' @param instrument_name Name of instrument
#' @return Vector of variable names
#' @export
get_instrument_variables <- function(dict, instrument_name) {
  dict_filtered <- dict[dict$instrument == instrument_name & !is.na(dict$instrument), ]
  return(dict_filtered$new_name)
}


#' Helper: Get Variables by Section
#'
#' Extract variable names for a specific section
#'
#' @param dict Data dictionary
#' @param section_name Name of section (cognitive, physical, demographic, medical)
#' @return Vector of variable names
#' @export
get_section_variables <- function(dict, section_name) {
  dict_filtered <- dict[dict$section == section_name & !is.na(dict$section), ]
  return(dict_filtered$new_name)
}
