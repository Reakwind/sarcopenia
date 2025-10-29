# ============================================================================
# STATISTICAL ANALYSIS FUNCTIONS
# ============================================================================
#
# Functions for statistical analysis of cleaned data
# - Descriptive statistics
# - Hypothesis testing (t-tests, ANOVA, chi-square)
# - Correlation analysis
# - Regression modeling
#
# SAFE TO MODIFY - These functions work on cleaned_data() output
# ============================================================================

#' Calculate Descriptive Statistics
#'
#' Generates descriptive statistics for numeric variables
#'
#' @param data Cleaned visits data
#' @param variables Character vector of variable names to analyze
#' @return Dataframe with descriptive stats
#' @export
calculate_descriptive_stats <- function(data, variables) {
  # TODO: Implement descriptive statistics
  # Example: mean, median, SD, min, max, n, missing

  message("Calculating descriptive statistics...")

  # Placeholder implementation
  return(NULL)
}


#' Perform Group Comparison
#'
#' Compares outcome variables between groups (e.g., treatment vs control)
#'
#' @param data Cleaned visits data
#' @param outcome_var Outcome variable name
#' @param group_var Grouping variable name
#' @param test_type Type of test: "t-test", "anova", "chi-square"
#' @return List with test results
#' @export
compare_groups <- function(data, outcome_var, group_var, test_type = "t-test") {
  # TODO: Implement group comparisons

  message("Performing group comparison...")

  # Placeholder implementation
  return(NULL)
}


#' Calculate Correlations
#'
#' Calculates correlation matrix for selected variables
#'
#' @param data Cleaned visits data
#' @param variables Character vector of variable names
#' @param method Correlation method: "pearson", "spearman", "kendall"
#' @return Correlation matrix
#' @export
calculate_correlations <- function(data, variables, method = "pearson") {
  # TODO: Implement correlation analysis

  message("Calculating correlations...")

  # Placeholder implementation
  return(NULL)
}


# ============================================================================
# OUTLIER DETECTION FUNCTIONS
# ============================================================================

#' Detect Range Violations
#'
#' Checks numeric values against clinical valid ranges
#'
#' @param data Cleaned visits data
#' @param dict Data dictionary
#' @param valid_ranges Dataframe with valid ranges (from instrument_valid_ranges.csv)
#' @return Dataframe with range violations
#' @export
detect_range_violations <- function(data, dict, valid_ranges) {
  message("[OUTLIERS] Detecting range violations...")

  # Get patient and visit IDs
  if (!"id_client_id" %in% names(data)) {
    stop("Data must contain id_client_id column")
  }

  violations <- list()

  # Check each variable in valid_ranges
  for (i in 1:nrow(valid_ranges)) {
    var_name <- valid_ranges$variable_name[i]
    min_val <- valid_ranges$min_valid[i]
    max_val <- valid_ranges$max_valid[i]
    instrument <- valid_ranges$instrument[i]

    # Skip if variable not in data
    if (!var_name %in% names(data)) next

    # Get numeric version if it exists, otherwise use original
    var_to_check <- paste0(var_name, "_numeric")
    if (!var_to_check %in% names(data)) {
      var_to_check <- var_name
    }

    # Skip if not numeric
    if (!is.numeric(data[[var_to_check]])) next

    # Find violations
    below_min <- which(!is.na(data[[var_to_check]]) & data[[var_to_check]] < min_val)
    above_max <- which(!is.na(data[[var_to_check]]) & data[[var_to_check]] > max_val)

    # Record below min violations
    if (length(below_min) > 0) {
      violations[[length(violations) + 1]] <- data.frame(
        patient_id = data$id_client_id[below_min],
        visit_no = if ("id_visit_no" %in% names(data)) data$id_visit_no[below_min] else NA,
        variable = var_name,
        instrument = instrument,
        value = data[[var_to_check]][below_min],
        violation_type = "below_min",
        min_valid = min_val,
        max_valid = max_val,
        stringsAsFactors = FALSE
      )
    }

    # Record above max violations
    if (length(above_max) > 0) {
      violations[[length(violations) + 1]] <- data.frame(
        patient_id = data$id_client_id[above_max],
        visit_no = if ("id_visit_no" %in% names(data)) data$id_visit_no[above_max] else NA,
        variable = var_name,
        instrument = instrument,
        value = data[[var_to_check]][above_max],
        violation_type = "above_max",
        min_valid = min_val,
        max_valid = max_val,
        stringsAsFactors = FALSE
      )
    }
  }

  # Combine all violations
  if (length(violations) == 0) {
    message("[OUTLIERS] No range violations detected!")
    return(data.frame())
  }

  result <- do.call(rbind, violations)
  message("[OUTLIERS] Found ", nrow(result), " range violations")

  return(result)
}


#' Detect Outliers Using IQR Method
#'
#' Detects statistical outliers using interquartile range method
#'
#' @param data Cleaned visits data
#' @param variables Character vector of numeric variables to check
#' @param multiplier IQR multiplier (default 1.5)
#' @return Dataframe with IQR outliers
#' @export
detect_outliers_iqr <- function(data, variables, multiplier = 1.5) {
  message("[OUTLIERS] Detecting IQR outliers (multiplier = ", multiplier, ")...")

  if (!"id_client_id" %in% names(data)) {
    stop("Data must contain id_client_id column")
  }

  outliers <- list()

  for (var in variables) {
    # Get numeric version if it exists
    var_to_check <- paste0(var, "_numeric")
    if (!var_to_check %in% names(data)) {
      var_to_check <- var
    }

    # Skip if not in data or not numeric
    if (!var_to_check %in% names(data)) next
    if (!is.numeric(data[[var_to_check]])) next

    # Calculate IQR
    values <- data[[var_to_check]][!is.na(data[[var_to_check]])]
    if (length(values) < 4) next  # Need at least 4 values for quartiles

    q1 <- quantile(values, 0.25, na.rm = TRUE)
    q3 <- quantile(values, 0.75, na.rm = TRUE)
    iqr <- q3 - q1

    lower_bound <- q1 - multiplier * iqr
    upper_bound <- q3 + multiplier * iqr

    # Find outliers
    outlier_idx <- which(!is.na(data[[var_to_check]]) &
                         (data[[var_to_check]] < lower_bound |
                          data[[var_to_check]] > upper_bound))

    if (length(outlier_idx) > 0) {
      outliers[[length(outliers) + 1]] <- data.frame(
        patient_id = data$id_client_id[outlier_idx],
        visit_no = if ("id_visit_no" %in% names(data)) data$id_visit_no[outlier_idx] else NA,
        variable = var,
        value = data[[var_to_check]][outlier_idx],
        q1 = q1,
        q3 = q3,
        iqr = iqr,
        lower_bound = lower_bound,
        upper_bound = upper_bound,
        stringsAsFactors = FALSE
      )
    }
  }

  # Combine all outliers
  if (length(outliers) == 0) {
    message("[OUTLIERS] No IQR outliers detected!")
    return(data.frame())
  }

  result <- do.call(rbind, outliers)
  message("[OUTLIERS] Found ", nrow(result), " IQR outliers")

  return(result)
}


#' Detect Outliers Using Z-Score Method
#'
#' Detects statistical outliers using z-score method
#'
#' @param data Cleaned visits data
#' @param variables Character vector of numeric variables to check
#' @param threshold Z-score threshold (default 3)
#' @return Dataframe with z-score outliers
#' @export
detect_outliers_zscore <- function(data, variables, threshold = 3) {
  message("[OUTLIERS] Detecting Z-score outliers (threshold = ", threshold, ")...")

  if (!"id_client_id" %in% names(data)) {
    stop("Data must contain id_client_id column")
  }

  outliers <- list()

  for (var in variables) {
    # Get numeric version if it exists
    var_to_check <- paste0(var, "_numeric")
    if (!var_to_check %in% names(data)) {
      var_to_check <- var
    }

    # Skip if not in data or not numeric
    if (!var_to_check %in% names(data)) next
    if (!is.numeric(data[[var_to_check]])) next

    # Calculate mean and SD
    values <- data[[var_to_check]][!is.na(data[[var_to_check]])]
    if (length(values) < 3) next  # Need at least 3 values

    mean_val <- mean(values, na.rm = TRUE)
    sd_val <- sd(values, na.rm = TRUE)

    if (sd_val == 0) next  # Skip if no variation

    # Calculate z-scores
    z_scores <- (data[[var_to_check]] - mean_val) / sd_val

    # Find outliers
    outlier_idx <- which(!is.na(z_scores) & abs(z_scores) > threshold)

    if (length(outlier_idx) > 0) {
      outliers[[length(outliers) + 1]] <- data.frame(
        patient_id = data$id_client_id[outlier_idx],
        visit_no = if ("id_visit_no" %in% names(data)) data$id_visit_no[outlier_idx] else NA,
        variable = var,
        value = data[[var_to_check]][outlier_idx],
        mean = mean_val,
        sd = sd_val,
        zscore = z_scores[outlier_idx],
        stringsAsFactors = FALSE
      )
    }
  }

  # Combine all outliers
  if (length(outliers) == 0) {
    message("[OUTLIERS] No Z-score outliers detected!")
    return(data.frame())
  }

  result <- do.call(rbind, outliers)
  message("[OUTLIERS] Found ", nrow(result), " Z-score outliers")

  return(result)
}


#' Summarize Outliers by Instrument
#'
#' Creates summary table of outliers grouped by instrument
#'
#' @param range_violations Dataframe from detect_range_violations()
#' @param iqr_outliers Dataframe from detect_outliers_iqr()
#' @param zscore_outliers Dataframe from detect_outliers_zscore()
#' @param dict Data dictionary
#' @return Dataframe with instrument-level summary
#' @export
summarize_outliers_by_instrument <- function(range_violations, iqr_outliers,
                                               zscore_outliers, dict) {
  message("[SUMMARY] Summarizing outliers by instrument...")

  # Get all instruments from dict
  instruments <- unique(dict$instrument[!is.na(dict$instrument)])

  summary_list <- list()

  for (inst in instruments) {
    # Get variables for this instrument
    inst_vars <- dict$new_name[dict$instrument == inst & !is.na(dict$instrument)]

    # Count outliers for this instrument
    n_range <- if (nrow(range_violations) > 0) {
      sum(range_violations$instrument == inst, na.rm = TRUE)
    } else {
      0
    }

    n_iqr <- if (nrow(iqr_outliers) > 0) {
      sum(iqr_outliers$variable %in% inst_vars, na.rm = TRUE)
    } else {
      0
    }

    n_zscore <- if (nrow(zscore_outliers) > 0) {
      sum(zscore_outliers$variable %in% inst_vars, na.rm = TRUE)
    } else {
      0
    }

    n_variables <- length(inst_vars)
    n_total_outliers <- n_range + n_iqr + n_zscore

    summary_list[[length(summary_list) + 1]] <- data.frame(
      instrument = inst,
      n_variables = n_variables,
      n_range_violations = n_range,
      n_iqr_outliers = n_iqr,
      n_zscore_outliers = n_zscore,
      n_total_outliers = n_total_outliers,
      stringsAsFactors = FALSE
    )
  }

  result <- do.call(rbind, summary_list)
  result <- result[order(-result$n_total_outliers), ]

  message("[SUMMARY] Summary complete for ", nrow(result), " instruments")

  return(result)
}


#' Summarize Outliers by Variable
#'
#' Creates summary table of outliers grouped by variable
#'
#' @param range_violations Dataframe from detect_range_violations()
#' @param iqr_outliers Dataframe from detect_outliers_iqr()
#' @param zscore_outliers Dataframe from detect_outliers_zscore()
#' @param dict Data dictionary
#' @return Dataframe with variable-level summary
#' @export
summarize_outliers_by_variable <- function(range_violations, iqr_outliers,
                                             zscore_outliers, dict) {
  message("[SUMMARY] Summarizing outliers by variable...")

  # Get all variables that have outliers
  all_vars <- unique(c(
    if (nrow(range_violations) > 0) range_violations$variable else character(0),
    if (nrow(iqr_outliers) > 0) iqr_outliers$variable else character(0),
    if (nrow(zscore_outliers) > 0) zscore_outliers$variable else character(0)
  ))

  if (length(all_vars) == 0) {
    message("[SUMMARY] No outliers to summarize")
    return(data.frame())
  }

  summary_list <- list()

  for (var in all_vars) {
    # Count outliers by type
    n_range <- if (nrow(range_violations) > 0) {
      sum(range_violations$variable == var, na.rm = TRUE)
    } else {
      0
    }

    n_iqr <- if (nrow(iqr_outliers) > 0) {
      sum(iqr_outliers$variable == var, na.rm = TRUE)
    } else {
      0
    }

    n_zscore <- if (nrow(zscore_outliers) > 0) {
      sum(zscore_outliers$variable == var, na.rm = TRUE)
    } else {
      0
    }

    # Get instrument from dict
    dict_row <- dict[dict$new_name == var, ]
    instrument <- if (nrow(dict_row) > 0) dict_row$instrument[1] else NA

    n_total <- n_range + n_iqr + n_zscore

    summary_list[[length(summary_list) + 1]] <- data.frame(
      variable = var,
      instrument = instrument,
      n_range_violations = n_range,
      n_iqr_outliers = n_iqr,
      n_zscore_outliers = n_zscore,
      n_total_outliers = n_total,
      stringsAsFactors = FALSE
    )
  }

  result <- do.call(rbind, summary_list)
  result <- result[order(-result$n_total_outliers), ]

  message("[SUMMARY] Summary complete for ", nrow(result), " variables")

  return(result)
}


#' Create Outlier Boxplot
#'
#' Creates interactive boxplot with outliers highlighted
#'
#' @param data Cleaned visits data
#' @param variable Variable name to plot
#' @param outliers_df Dataframe with outliers for this variable
#' @return plotly boxplot object
#' @export
create_outlier_boxplot <- function(data, variable, outliers_df = NULL) {
  require(plotly)

  message("[PLOT] Creating outlier boxplot for ", variable)

  # Get numeric version if it exists
  var_to_plot <- paste0(variable, "_numeric")
  if (!var_to_plot %in% names(data)) {
    var_to_plot <- variable
  }

  if (!var_to_plot %in% names(data)) {
    stop("Variable not found in data")
  }

  # Get values
  values <- data[[var_to_plot]][!is.na(data[[var_to_plot]])]

  if (length(values) == 0) {
    message("[PLOT] No data to plot")
    return(NULL)
  }

  # Create boxplot
  fig <- plot_ly(
    y = values,
    type = "box",
    name = variable,
    marker = list(color = "#3498db"),
    boxmean = TRUE
  ) %>%
    layout(
      title = list(
        text = paste0("Distribution: ", variable,
                     "<br><sub>n = ", length(values), " observations</sub>"),
        x = 0
      ),
      yaxis = list(title = variable),
      hovermode = "closest"
    )

  # Add outlier points if provided
  if (!is.null(outliers_df) && nrow(outliers_df) > 0) {
    outliers_for_var <- outliers_df[outliers_df$variable == variable, ]

    if (nrow(outliers_for_var) > 0) {
      fig <- fig %>%
        add_trace(
          y = outliers_for_var$value,
          type = "scatter",
          mode = "markers",
          name = "Outliers",
          marker = list(
            color = "#e74c3c",
            size = 10,
            symbol = "circle-open",
            line = list(width = 2)
          ),
          hovertemplate = paste(
            "Patient: %{text}<br>",
            "Value: %{y}<br>",
            "<extra></extra>"
          ),
          text = outliers_for_var$patient_id
        )
    }
  }

  message("[PLOT] Boxplot created")
  return(fig)
}


#' Create Outlier Timeline
#'
#' Shows outlier counts over visits
#'
#' @param range_violations Dataframe from detect_range_violations()
#' @param iqr_outliers Dataframe from detect_outliers_iqr()
#' @param zscore_outliers Dataframe from detect_outliers_zscore()
#' @param visit_col Column name for visit numbers
#' @return plotly line chart object
#' @export
create_outlier_timeline <- function(range_violations, iqr_outliers,
                                     zscore_outliers, visit_col = "visit_no") {
  require(plotly)

  message("[PLOT] Creating outlier timeline...")

  # Get all visit numbers
  all_visits <- unique(c(
    if (nrow(range_violations) > 0 && visit_col %in% names(range_violations))
      range_violations[[visit_col]] else numeric(0),
    if (nrow(iqr_outliers) > 0 && visit_col %in% names(iqr_outliers))
      iqr_outliers[[visit_col]] else numeric(0),
    if (nrow(zscore_outliers) > 0 && visit_col %in% names(zscore_outliers))
      zscore_outliers[[visit_col]] else numeric(0)
  ))

  all_visits <- sort(unique(all_visits[!is.na(all_visits)]))

  if (length(all_visits) == 0) {
    message("[PLOT] No visit data to plot")
    return(NULL)
  }

  # Count outliers by visit
  range_counts <- sapply(all_visits, function(v) {
    if (nrow(range_violations) > 0 && visit_col %in% names(range_violations)) {
      sum(range_violations[[visit_col]] == v, na.rm = TRUE)
    } else {
      0
    }
  })

  iqr_counts <- sapply(all_visits, function(v) {
    if (nrow(iqr_outliers) > 0 && visit_col %in% names(iqr_outliers)) {
      sum(iqr_outliers[[visit_col]] == v, na.rm = TRUE)
    } else {
      0
    }
  })

  zscore_counts <- sapply(all_visits, function(v) {
    if (nrow(zscore_outliers) > 0 && visit_col %in% names(zscore_outliers)) {
      sum(zscore_outliers[[visit_col]] == v, na.rm = TRUE)
    } else {
      0
    }
  })

  # Create plot
  fig <- plot_ly() %>%
    add_trace(
      x = all_visits,
      y = range_counts,
      type = "scatter",
      mode = "lines+markers",
      name = "Range Violations",
      line = list(color = "#e74c3c", width = 2),
      marker = list(size = 8)
    ) %>%
    add_trace(
      x = all_visits,
      y = iqr_counts,
      type = "scatter",
      mode = "lines+markers",
      name = "IQR Outliers",
      line = list(color = "#f39c12", width = 2),
      marker = list(size = 8)
    ) %>%
    add_trace(
      x = all_visits,
      y = zscore_counts,
      type = "scatter",
      mode = "lines+markers",
      name = "Z-Score Outliers",
      line = list(color = "#9b59b6", width = 2),
      marker = list(size = 8)
    ) %>%
    layout(
      title = list(
        text = "Outlier Trends Across Visits",
        x = 0
      ),
      xaxis = list(title = "Visit Number"),
      yaxis = list(title = "Number of Outliers"),
      hovermode = "x unified",
      legend = list(x = 0.7, y = 1)
    )

  message("[PLOT] Timeline created")
  return(fig)
}


# =============================================================================
# PATIENT-FOCUSED SUMMARY FUNCTIONS
# =============================================================================
# Functions to identify which patients have issues and enable patient outreach
# =============================================================================

#' Summarize Outliers by Patient
#'
#' Creates a summary table showing each patient's outlier count and severity.
#' Enables identification of patients with most data quality issues for outreach.
#'
#' @param range_violations Data frame from detect_range_violations()
#' @param iqr_outliers Data frame from detect_outliers_iqr()
#' @param zscore_outliers Data frame from detect_outliers_zscore()
#'
#' @return Data frame with columns:
#'   - patient_id: Patient identifier
#'   - total_outliers: Total number of outliers detected for this patient
#'   - range_violations: Count of clinical range violations
#'   - iqr_outliers: Count of IQR statistical outliers
#'   - zscore_outliers: Count of Z-score statistical outliers
#'   - visits_with_outliers: Comma-separated list of visit numbers with outliers
#'   - n_visits_affected: Number of distinct visits with outliers
#'   - severity_score: Weighted severity (range=3, iqr=2, zscore=1)
#'
#' @export
summarize_patient_outliers <- function(range_violations, iqr_outliers, zscore_outliers) {

  message("[PATIENT] Summarizing outliers by patient...")

  # Combine all outlier types with type indicator
  all_outliers <- bind_rows(
    range_violations %>%
      mutate(outlier_type = "range") %>%
      select(patient_id, visit_no, variable, value, outlier_type),
    iqr_outliers %>%
      mutate(outlier_type = "iqr") %>%
      select(patient_id, visit_no, variable, value, outlier_type),
    zscore_outliers %>%
      mutate(outlier_type = "zscore") %>%
      select(patient_id, visit_no, variable, value, outlier_type)
  )

  # If no outliers detected
  if (nrow(all_outliers) == 0) {
    message("[PATIENT] No outliers detected - returning empty summary")
    return(data.frame(
      patient_id = character(0),
      total_outliers = integer(0),
      range_violations = integer(0),
      iqr_outliers = integer(0),
      zscore_outliers = integer(0),
      visits_with_outliers = character(0),
      n_visits_affected = integer(0),
      severity_score = numeric(0)
    ))
  }

  # Summarize by patient
  patient_summary <- all_outliers %>%
    group_by(patient_id) %>%
    summarise(
      total_outliers = n(),
      range_violations = sum(outlier_type == "range"),
      iqr_outliers = sum(outlier_type == "iqr"),
      zscore_outliers = sum(outlier_type == "zscore"),
      visits_with_outliers = paste(sort(unique(visit_no)), collapse = ", "),
      n_visits_affected = n_distinct(visit_no),
      .groups = "drop"
    ) %>%
    mutate(
      # Severity score: range violations weighted highest (clinical concern)
      severity_score = (range_violations * 3) + (iqr_outliers * 2) + (zscore_outliers * 1)
    ) %>%
    arrange(desc(severity_score), desc(total_outliers))

  message("[PATIENT] Summary created: ", nrow(patient_summary), " patients with outliers")
  message("[PATIENT] Total outliers across all patients: ", sum(patient_summary$total_outliers))

  return(patient_summary)
}


#' Get Patient Outlier Profile
#'
#' Returns detailed outlier information for a specific patient across all visits.
#' Shows all detection parameters to help understand WHY each value was flagged.
#'
#' @param patient_id Patient identifier to profile
#' @param range_violations Data frame from detect_range_violations()
#' @param iqr_outliers Data frame from detect_outliers_iqr()
#' @param zscore_outliers Data frame from detect_outliers_zscore()
#' @param dict Data dictionary with variable metadata
#'
#' @return Data frame with columns:
#'   - visit_no: Visit number where outlier occurred
#'   - variable: Variable name
#'   - variable_label: Human-readable label from data dictionary
#'   - instrument: Instrument name
#'   - value: Observed value
#'   - outlier_type: Type of detection (range/iqr/zscore)
#'   - detection_details: Human-readable explanation of why flagged
#'
#' @export
get_patient_outlier_profile <- function(patient_id, range_violations, iqr_outliers,
                                         zscore_outliers, dict) {

  message("[PATIENT] Creating outlier profile for patient: ", patient_id)

  # Prepare range violations for this patient
  patient_range <- range_violations %>%
    filter(patient_id == !!patient_id) %>%
    mutate(
      outlier_type = "Range Violation",
      detection_details = paste0(
        violation_type, ": Value ", value,
        " outside valid range [", min_valid, "-", max_valid, "]"
      )
    ) %>%
    select(visit_no, variable, value, outlier_type, detection_details, instrument)

  # Prepare IQR outliers for this patient
  patient_iqr <- iqr_outliers %>%
    filter(patient_id == !!patient_id) %>%
    mutate(
      outlier_type = "IQR Outlier",
      detection_details = paste0(
        "Value ", value, " outside IQR bounds [",
        round(lower_bound, 2), "-", round(upper_bound, 2), "]",
        " (Q1=", round(q1, 2), ", Q3=", round(q3, 2), ", IQR=", round(iqr, 2), ")"
      )
    ) %>%
    left_join(dict %>% select(variable_name, instrument),
              by = c("variable" = "variable_name")) %>%
    select(visit_no, variable, value, outlier_type, detection_details, instrument)

  # Prepare Z-score outliers for this patient
  patient_zscore <- zscore_outliers %>%
    filter(patient_id == !!patient_id) %>%
    mutate(
      outlier_type = "Z-Score Outlier",
      detection_details = paste0(
        "Z-score = ", round(zscore, 2), " (",
        round(abs(zscore), 2), " SDs ",
        ifelse(zscore > 0, "above", "below"), " mean=", round(mean, 2), ")"
      )
    ) %>%
    left_join(dict %>% select(variable_name, instrument),
              by = c("variable" = "variable_name")) %>%
    select(visit_no, variable, value, outlier_type, detection_details, instrument)

  # Combine all outlier types
  patient_profile <- bind_rows(patient_range, patient_iqr, patient_zscore)

  # If no outliers for this patient
  if (nrow(patient_profile) == 0) {
    message("[PATIENT] No outliers found for patient ", patient_id)
    return(data.frame(
      visit_no = character(0),
      variable = character(0),
      variable_label = character(0),
      instrument = character(0),
      value = character(0),
      outlier_type = character(0),
      detection_details = character(0)
    ))
  }

  # Add variable labels from data dictionary
  patient_profile <- patient_profile %>%
    left_join(dict %>% select(variable_name, variable_label),
              by = c("variable" = "variable_name")) %>%
    mutate(
      variable_label = ifelse(is.na(variable_label), variable, variable_label),
      instrument = ifelse(is.na(instrument), "Unknown", instrument)
    ) %>%
    select(visit_no, variable, variable_label, instrument, value,
           outlier_type, detection_details) %>%
    arrange(visit_no, instrument, variable)

  message("[PATIENT] Profile created: ", nrow(patient_profile), " outliers found")

  return(patient_profile)
}


#' Summarize Missing Data by Patient
#'
#' Creates a summary table showing each patient's missing data count.
#' Only counts TRUE NA values (empty strings "" are NOT considered missing).
#' Enables identification of patients with most missing data for outreach.
#'
#' @param data Cleaned visits data
#' @param dict Data dictionary with variable metadata
#'
#' @return Data frame with columns:
#'   - patient_id: Patient identifier
#'   - total_variables: Total number of variables in dataset
#'   - variables_with_data: Number of variables with at least one non-NA value
#'   - variables_missing: Number of variables that are completely missing (all NA)
#'   - pct_missing: Percentage of variables that are missing
#'   - visits_with_missing: Comma-separated list of visit numbers with any NA
#'   - n_visits_affected: Number of distinct visits with missing data
#'   - most_affected_instruments: Top 3 instruments with most missing variables
#'
#' @export
summarize_patient_missingness <- function(data, dict) {

  message("[PATIENT] Summarizing missing data by patient...")

  # Get patient ID column
  id_col <- grep("^id_", names(data), value = TRUE)[1]

  if (is.null(id_col) || length(id_col) == 0) {
    stop("Cannot find patient ID column (should start with 'id_')")
  }

  # Get visit column
  visit_col <- grep("visit", names(data), ignore.case = TRUE, value = TRUE)[1]

  if (is.null(visit_col) || length(visit_col) == 0) {
    warning("Cannot find visit column - visit analysis will be skipped")
    visit_col <- NULL
  }

  # Exclude ID and visit columns from missingness analysis
  exclude_cols <- c(id_col, visit_col)
  analysis_vars <- setdiff(names(data), exclude_cols)

  message("[PATIENT] Analyzing ", length(analysis_vars), " variables across ",
          length(unique(data[[id_col]])), " patients")

  # STEP 1: Count missing/present variables per patient using correct dplyr syntax
  patient_summary <- data %>%
    select(all_of(c(id_col, analysis_vars))) %>%
    group_by(across(all_of(id_col))) %>%
    summarise(
      across(
        all_of(analysis_vars),
        list(
          all_missing = ~all(is.na(.x)),
          any_data = ~any(!is.na(.x))
        ),
        .names = "{.col}___{.fn}"
      ),
      .groups = "drop"
    ) %>%
    mutate(
      variables_missing = rowSums(select(., ends_with("___all_missing"))),
      variables_with_data = rowSums(select(., ends_with("___any_data"))),
      total_variables = length(analysis_vars)
    ) %>%
    select(all_of(id_col), total_variables, variables_with_data, variables_missing)

  # STEP 2: Find visits with any missing data (if visit column exists)
  if (!is.null(visit_col)) {
    visit_missing_summary <- data %>%
      select(all_of(c(id_col, visit_col, analysis_vars))) %>%
      mutate(
        has_any_na = rowSums(is.na(select(., all_of(analysis_vars)))) > 0
      ) %>%
      filter(has_any_na) %>%
      group_by(across(all_of(id_col))) %>%
      summarise(
        visits_with_missing = paste(sort(unique(!!sym(visit_col))), collapse = ", "),
        n_visits_affected = n_distinct(!!sym(visit_col)),
        .groups = "drop"
      )

    # Join with patient summary
    patient_summary <- patient_summary %>%
      left_join(visit_missing_summary, by = id_col) %>%
      mutate(
        visits_with_missing = if_else(is.na(visits_with_missing), "", visits_with_missing),
        n_visits_affected = if_else(is.na(n_visits_affected), 0L, n_visits_affected)
      )
  } else {
    patient_summary <- patient_summary %>%
      mutate(
        visits_with_missing = NA_character_,
        n_visits_affected = NA_integer_
      )
  }

  # STEP 3: Calculate percentage
  patient_summary <- patient_summary %>%
    mutate(pct_missing = round(variables_missing / total_variables * 100, 1))

  # STEP 4: Find most affected instruments
  if (nrow(dict) > 0 && "variable_name" %in% names(dict) && "instrument" %in% names(dict)) {
    # First create a temp data frame with patient ID and variable missing status
    patient_var_status <- data %>%
      select(all_of(c(id_col, analysis_vars))) %>%
      group_by(across(all_of(id_col))) %>%
      summarise(
        across(
          all_of(analysis_vars),
          ~all(is.na(.x)),
          .names = "{.col}"
        ),
        .groups = "drop"
      )

    # Pivot to long format to get missing variables per patient
    patient_missing_vars <- patient_var_status %>%
      pivot_longer(
        cols = -all_of(id_col),
        names_to = "variable",
        values_to = "is_missing"
      ) %>%
      filter(is_missing) %>%
      select(-is_missing)

    # Join with dict to get instruments and find top 3
    patient_instruments <- patient_missing_vars %>%
      left_join(
        dict %>% select(variable_name, instrument),
        by = c("variable" = "variable_name")
      ) %>%
      filter(!is.na(instrument)) %>%
      group_by(across(all_of(id_col)), instrument) %>%
      summarise(n_missing_vars = n(), .groups = "drop") %>%
      group_by(across(all_of(id_col))) %>%
      slice_max(n_missing_vars, n = 3, with_ties = FALSE) %>%
      summarise(
        most_affected_instruments = paste(instrument, collapse = ", "),
        .groups = "drop"
      )

    # Join with patient summary
    patient_summary <- patient_summary %>%
      left_join(patient_instruments, by = id_col) %>%
      mutate(
        most_affected_instruments = if_else(
          is.na(most_affected_instruments) | most_affected_instruments == "",
          "None",
          most_affected_instruments
        )
      )
  } else {
    patient_summary <- patient_summary %>%
      mutate(most_affected_instruments = "Unknown - no data dictionary")
  }

  # Rename id column to patient_id
  patient_summary <- patient_summary %>%
    rename(patient_id = !!sym(id_col))

  # Sort by most missing data
  patient_summary <- patient_summary %>%
    arrange(desc(pct_missing), desc(variables_missing))

  message("[PATIENT] Summary created: ", nrow(patient_summary), " patients analyzed")
  message("[PATIENT] Patients with missing data: ",
          sum(patient_summary$variables_missing > 0))

  return(patient_summary)
}


#' Create Unified Patient Summary with Priority Scoring
#'
#' Combines missingness and outlier data for each patient and calculates
#' priority scores for patient outreach
#'
#' Priority scoring:
#' - 🔴 High Priority: >30% missing OR >10 outliers
#' - 🟡 Medium Priority: 10-30% missing OR 3-10 outliers
#' - 🟢 Clean: <10% missing AND <3 outliers
#'
#' @param patient_missingness_summary Output from summarize_patient_missingness()
#' @param patient_outliers_summary Output from summarize_patient_outliers()
#' @return Dataframe with unified patient summary and priority indicators
#' @export
create_unified_patient_summary <- function(patient_missingness_summary,
                                           patient_outliers_summary) {
  message("[UNIFIED] Creating unified patient summary...")

  # Start with missingness summary (all patients)
  unified <- patient_missingness_summary %>%
    select(
      patient_id,
      total_variables,
      variables_with_data,
      variables_missing,
      pct_missing,
      visits_with_missing,
      n_visits_affected,
      most_affected_instruments
    ) %>%
    rename(n_visits_missing = n_visits_affected)

  # Add outlier data (left join - not all patients have outliers)
  if (nrow(patient_outliers_summary) > 0) {
    outlier_data <- patient_outliers_summary %>%
      select(
        patient_id,
        total_outliers,
        range_violations,
        iqr_outliers,
        zscore_outliers,
        visits_with_outliers,
        n_visits_affected
      ) %>%
      rename(n_visits_outliers = n_visits_affected)

    unified <- unified %>%
      left_join(outlier_data, by = "patient_id")
  } else {
    # No outliers - add empty columns
    unified <- unified %>%
      mutate(
        total_outliers = 0,
        range_violations = 0,
        iqr_outliers = 0,
        zscore_outliers = 0,
        visits_with_outliers = "",
        n_visits_outliers = 0
      )
  }

  # Replace NAs in outlier columns with 0
  unified <- unified %>%
    mutate(
      total_outliers = ifelse(is.na(total_outliers), 0, total_outliers),
      range_violations = ifelse(is.na(range_violations), 0, range_violations),
      iqr_outliers = ifelse(is.na(iqr_outliers), 0, iqr_outliers),
      zscore_outliers = ifelse(is.na(zscore_outliers), 0, zscore_outliers),
      visits_with_outliers = ifelse(is.na(visits_with_outliers), "", visits_with_outliers),
      n_visits_outliers = ifelse(is.na(n_visits_outliers), 0, n_visits_outliers)
    )

  # Calculate priority score
  unified <- unified %>%
    mutate(
      # Priority logic
      priority = case_when(
        pct_missing > 30 | total_outliers > 10 ~ "🔴 High",
        pct_missing > 10 | total_outliers > 3 ~ "🟡 Medium",
        TRUE ~ "🟢 Clean"
      ),

      # Numeric priority for sorting (1=High, 2=Medium, 3=Clean)
      priority_score = case_when(
        pct_missing > 30 | total_outliers > 10 ~ 1,
        pct_missing > 10 | total_outliers > 3 ~ 2,
        TRUE ~ 3
      )
    )

  # Sort by priority (High first) then by severity
  unified <- unified %>%
    arrange(priority_score, desc(pct_missing), desc(total_outliers))

  message("[UNIFIED] Summary created: ", nrow(unified), " patients")
  message("[UNIFIED] Priority breakdown:")
  message("  🔴 High Priority: ", sum(unified$priority == "🔴 High"))
  message("  🟡 Medium Priority: ", sum(unified$priority == "🟡 Medium"))
  message("  🟢 Clean: ", sum(unified$priority == "🟢 Clean"))

  return(unified)
}
