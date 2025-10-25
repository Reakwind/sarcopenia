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
