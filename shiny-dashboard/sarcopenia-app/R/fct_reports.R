# ============================================================================
# REPORT GENERATION FUNCTIONS
# ============================================================================
#
# Functions for generating reports and exports
# - PDF reports with analysis summaries
# - Excel exports with multiple sheets
# - HTML reports with interactive elements
#
# SAFE TO MODIFY - These functions work on cleaned_data() output
# ============================================================================

#' Generate Analysis Report
#'
#' Creates comprehensive analysis report (PDF or HTML)
#'
#' @param data Cleaned visits data
#' @param output_format Format: "pdf", "html", "word"
#' @param include_sections Sections to include
#' @return Path to generated report file, or NULL if failed
#' @export
generate_analysis_report <- function(data, output_format = "pdf", include_sections = c("descriptive", "comparative")) {
  # Check if rmarkdown package is available
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    warning("Package 'rmarkdown' is required for report generation. Please install it with: install.packages('rmarkdown')")
    return(NULL)
  }

  message("Generating ", output_format, " report...")

  tryCatch({
    # Create temporary R Markdown file
    temp_rmd <- tempfile(fileext = ".Rmd")

    # Generate R Markdown content
    rmd_content <- paste0(
      "---\n",
      "title: 'Sarcopenia Data Analysis Report'\n",
      "date: '", format(Sys.Date(), "%B %d, %Y"), "'\n",
      "output: ", output_format, "_document\n",
      "---\n\n",
      "```{r setup, include=FALSE}\n",
      "knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)\n",
      "library(dplyr)\n",
      "library(knitr)\n",
      "```\n\n",
      "## Data Summary\n\n",
      "```{r}\n",
      "cat('Total observations:', nrow(data), '\\n')\n",
      "cat('Total variables:', ncol(data), '\\n')\n",
      "if ('id_client_id' %in% names(data)) {\n",
      "  cat('Unique patients:', length(unique(data$id_client_id)), '\\n')\n",
      "}\n",
      "```\n\n"
    )

    # Add descriptive section if requested
    if ("descriptive" %in% include_sections) {
      rmd_content <- paste0(rmd_content,
        "## Descriptive Statistics\n\n",
        "```{r}\n",
        "# Select numeric columns for summary\n",
        "numeric_cols <- names(data)[sapply(data, is.numeric)]\n",
        "if (length(numeric_cols) > 0) {\n",
        "  summary_data <- data[, numeric_cols[1:min(10, length(numeric_cols))]]\n",
        "  knitr::kable(summary(summary_data), caption = 'Summary of numeric variables')\n",
        "} else {\n",
        "  cat('No numeric variables found for summary.\\n')\n",
        "}\n",
        "```\n\n"
      )
    }

    # Add comparative section if requested
    if ("comparative" %in% include_sections) {
      rmd_content <- paste0(rmd_content,
        "## Comparative Analysis\n\n",
        "Comparative analysis would be displayed here when available.\n\n"
      )
    }

    # Write R Markdown file
    writeLines(rmd_content, temp_rmd)

    # Render the document
    output_file <- tempfile(fileext = paste0(".", output_format))
    rmarkdown::render(
      temp_rmd,
      output_format = paste0(output_format, "_document"),
      output_file = output_file,
      quiet = TRUE,
      envir = new.env(parent = globalenv())
    )

    message("Report generated successfully: ", output_file)
    return(output_file)

  }, error = function(e) {
    warning("Failed to generate report: ", e$message)
    return(NULL)
  })
}


#' Export to Excel with Multiple Sheets
#'
#' Exports cleaned data and analysis results to Excel workbook
#'
#' @param visits_data Cleaned visits dataframe
#' @param ae_data Cleaned adverse events dataframe
#' @param analysis_results Optional analysis results to include
#' @param filename Output filename
#' @return TRUE if successful, FALSE if failed
#' @export
export_to_excel <- function(visits_data, ae_data, analysis_results = NULL, filename) {
  # Check if writexl package is available
  if (!requireNamespace("writexl", quietly = TRUE)) {
    warning("Package 'writexl' is required for Excel export. Please install it with: install.packages('writexl')")
    return(FALSE)
  }

  message("Exporting to Excel: ", filename)

  tryCatch({
    # Prepare sheets list
    sheets <- list(
      "Visits Data" = visits_data,
      "Adverse Events" = ae_data
    )

    # Add analysis results if provided
    if (!is.null(analysis_results)) {
      if (is.data.frame(analysis_results)) {
        sheets[["Analysis Results"]] <- analysis_results
      } else if (is.list(analysis_results)) {
        # If it's a list of dataframes, add each one
        for (name in names(analysis_results)) {
          if (is.data.frame(analysis_results[[name]])) {
            sheets[[name]] <- analysis_results[[name]]
          }
        }
      }
    }

    # Write to Excel
    writexl::write_xlsx(sheets, path = filename)

    message("Excel export complete: ", filename)
    return(TRUE)

  }, error = function(e) {
    warning("Failed to export to Excel: ", e$message)
    return(FALSE)
  })
}


#' Create Data Summary Table
#'
#' Creates formatted summary table for reports
#'
#' @param data Cleaned visits data
#' @param variables Variables to summarize
#' @param group_by Optional grouping variable
#' @return Formatted data frame with summary statistics
#' @export
create_summary_table <- function(data, variables, group_by = NULL) {
  message("Creating summary table...")

  # Input validation
  if (is.null(data) || nrow(data) == 0) {
    warning("No data provided for summary table")
    return(NULL)
  }

  if (is.null(variables) || length(variables) == 0) {
    warning("No variables specified for summary table")
    return(NULL)
  }

  # Filter to only variables that exist in data
  variables <- intersect(variables, names(data))
  if (length(variables) == 0) {
    warning("None of the specified variables exist in the data")
    return(NULL)
  }

  tryCatch({
    # Select relevant data
    summary_data <- data[, c(variables, if (!is.null(group_by)) group_by else NULL), drop = FALSE]

    # Create summary
    if (!is.null(group_by) && group_by %in% names(data)) {
      # Grouped summary
      result <- summary_data %>%
        dplyr::group_by(across(all_of(group_by))) %>%
        dplyr::summarise(
          across(
            all_of(variables),
            list(
              n = ~sum(!is.na(.)),
              mean = ~ifelse(is.numeric(.), mean(., na.rm = TRUE), NA_real_),
              sd = ~ifelse(is.numeric(.), sd(., na.rm = TRUE), NA_real_),
              min = ~ifelse(is.numeric(.), min(., na.rm = TRUE), NA_real_),
              max = ~ifelse(is.numeric(.), max(., na.rm = TRUE), NA_real_)
            ),
            .names = "{.col}_{.fn}"
          ),
          .groups = "drop"
        )
    } else {
      # Overall summary
      result <- summary_data %>%
        dplyr::summarise(
          across(
            all_of(variables),
            list(
              n = ~sum(!is.na(.)),
              mean = ~ifelse(is.numeric(.), mean(., na.rm = TRUE), NA_real_),
              sd = ~ifelse(is.numeric(.), sd(., na.rm = TRUE), NA_real_),
              min = ~ifelse(is.numeric(.), min(., na.rm = TRUE), NA_real_),
              max = ~ifelse(is.numeric(.), max(., na.rm = TRUE), NA_real_)
            ),
            .names = "{.col}_{.fn}"
          )
        )
    }

    message("Summary table created with ", nrow(result), " rows")
    return(as.data.frame(result))

  }, error = function(e) {
    warning("Failed to create summary table: ", e$message)
    return(NULL)
  })
}
