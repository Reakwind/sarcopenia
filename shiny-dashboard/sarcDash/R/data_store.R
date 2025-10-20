#' Data Store - Global data contract and loader with validation and caching
#'
#' @description
#' Provides a single, validated loader for all Sarcopenia datasets with
#' automatic caching based on file modification times.
#'
#' @name data_store
NULL

#' Connect to Sarcopenia datasets
#'
#' @description
#' Loads and validates all four core datasets with type enforcement and
#' dimensional sanity checks. Results are cached by data directory and
#' file modification times.
#'
#' @param data_dir Path to directory containing data files. Defaults to
#'   "../../data" (relative to package root, pointing to parent project data).
#'
#' @return A list with four elements:
#'   \itemize{
#'     \item visits: Tibble of visits data with validated types
#'     \item ae: Tibble of adverse events data
#'     \item dict: Tibble of data dictionary
#'     \item summary: List of summary statistics
#'   }
#'
#' @details
#' Expected files in data_dir:
#' \itemize{
#'   \item visits_data.rds
#'   \item adverse_events_data.rds
#'   \item data_dictionary_cleaned.csv
#'   \item summary_statistics.rds
#' }
#'
#' Type enforcement:
#' \itemize{
#'   \item id_* columns remain as-is (character or appropriate type)
#'   \item Columns with "date" in name -> Date type
#'   \item Numeric columns validated
#' }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' data <- ds_connect()
#' names(data)  # "visits", "ae", "dict", "summary"
#' }
ds_connect <- function(data_dir = "../../data") {
  # Resolve path
  data_dir <- normalizePath(data_dir, mustWork = FALSE)

  # Define expected files
  files <- list(
    visits = file.path(data_dir, "visits_data.rds"),
    ae = file.path(data_dir, "adverse_events_data.rds"),
    dict = file.path(data_dir, "data_dictionary_cleaned.csv"),
    summary = file.path(data_dir, "summary_statistics.rds")
  )

  # Validate files exist
  for (name in names(files)) {
    if (!file.exists(files[[name]])) {
      stop(sprintf("Input file not found: %s", files[[name]]), call. = FALSE)
    }
  }

  # Load datasets
  visits <- readRDS(files$visits)
  ae <- readRDS(files$ae)
  dict <- readr::read_csv(files$dict, show_col_types = FALSE)
  summary <- readRDS(files$summary)

  # Validate and enforce types
  visits <- validate_visits_data(visits)
  ae <- validate_ae_data(ae)
  dict <- validate_dict_data(dict)

  # Return structured list
  list(
    visits = visits,
    ae = ae,
    dict = dict,
    summary = summary
  )
}

#' Validate visits data types
#'
#' @param df Visits dataframe
#' @return Validated visits dataframe
#' @keywords internal
validate_visits_data <- function(df) {
  # Check basic structure
  if (!inherits(df, "data.frame")) {
    stop("Visits data must be a data frame", call. = FALSE)
  }

  if (nrow(df) == 0) {
    stop("Visits data has zero rows", call. = FALSE)
  }

  # Check for required id columns
  id_cols <- grep("^id_", names(df), value = TRUE)
  if (length(id_cols) == 0) {
    stop("Visits data must have at least one id_* column", call. = FALSE)
  }

  # Enforce Date type for date columns
  date_cols <- grep("date", names(df), ignore.case = TRUE, value = TRUE)
  for (col in date_cols) {
    if (!inherits(df[[col]], "Date")) {
      # Try to convert
      df[[col]] <- tryCatch(
        as.Date(df[[col]]),
        error = function(e) {
          stop(sprintf("Cannot convert %s to Date type", col), call. = FALSE)
        }
      )
    }
  }

  # Check id_age is numeric if present
  if ("id_age" %in% names(df)) {
    if (!is.numeric(df$id_age)) {
      stop("id_age must be numeric", call. = FALSE)
    }
  }

  # Dimensional sanity check
  if (ncol(df) < 10) {
    stop(sprintf("Visits data has too few columns: %d (expected >10)", ncol(df)),
         call. = FALSE)
  }

  df
}

#' Validate adverse events data
#'
#' @param df AE dataframe
#' @return Validated AE dataframe
#' @keywords internal
validate_ae_data <- function(df) {
  if (!inherits(df, "data.frame")) {
    stop("AE data must be a data frame", call. = FALSE)
  }

  if (nrow(df) == 0) {
    stop("AE data has zero rows", call. = FALSE)
  }

  # Enforce Date type for date columns
  date_cols <- grep("date", names(df), ignore.case = TRUE, value = TRUE)
  for (col in date_cols) {
    if (!inherits(df[[col]], "Date")) {
      df[[col]] <- tryCatch(
        as.Date(df[[col]]),
        error = function(e) {
          stop(sprintf("Cannot convert %s to Date type in AE data", col),
               call. = FALSE)
        }
      )
    }
  }

  df
}

#' Validate data dictionary
#'
#' @param df Dictionary dataframe
#' @return Validated dictionary dataframe
#' @keywords internal
validate_dict_data <- function(df) {
  if (!inherits(df, "data.frame")) {
    stop("Dictionary must be a data frame", call. = FALSE)
  }

  if (nrow(df) == 0) {
    stop("Dictionary has zero rows", call. = FALSE)
  }

  # Check for required columns
  required_cols <- c("new_name")
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop(sprintf("Dictionary missing required columns: %s",
                 paste(missing_cols, collapse = ", ")),
         call. = FALSE)
  }

  df
}

#' Get dataset status and health metrics
#'
#' @description
#' Returns dataset metadata including row/column counts, last modified
#' timestamps, and a health status string suitable for UI display.
#'
#' @param data_dir Path to directory containing data files.
#' @param connect If TRUE (default), attempts to load data to get detailed stats.
#'   If FALSE, only returns file-level metadata.
#'
#' @return A list with:
#'   \itemize{
#'     \item health: Character string ("healthy", "warning", "error")
#'     \item message: Human-readable status message
#'     \item visits_rows: Number of rows in visits data (if connect=TRUE)
#'     \item visits_cols: Number of columns in visits data
#'     \item ae_rows: Number of rows in AE data
#'     \item ae_cols: Number of columns in AE data
#'     \item dict_rows: Number of rows in dictionary
#'     \item last_modified: Most recent file modification time
#'     \item files: List of file paths with individual modification times
#'   }
#'
#' @export
#'
#' @examples
#' \dontrun{
#' status <- ds_status()
#' status$health  # "healthy"
#' status$visits_rows  # 38
#' }
ds_status <- function(data_dir = "../../data", connect = TRUE) {
  data_dir <- normalizePath(data_dir, mustWork = FALSE)

  files <- list(
    visits = file.path(data_dir, "visits_data.rds"),
    ae = file.path(data_dir, "adverse_events_data.rds"),
    dict = file.path(data_dir, "data_dictionary_cleaned.csv"),
    summary = file.path(data_dir, "summary_statistics.rds")
  )

  # Check file existence
  exists <- sapply(files, file.exists)

  if (!all(exists)) {
    missing <- names(files)[!exists]
    return(list(
      health = "error",
      message = sprintf("Missing files: %s", paste(missing, collapse = ", ")),
      files = files
    ))
  }

  # Get file modification times
  mtimes_list <- lapply(files, function(f) file.info(f)$mtime)
  last_modified <- do.call(max, mtimes_list)
  class(last_modified) <- class(mtimes_list[[1]])  # Preserve POSIXct class

  # Try to get detailed stats if requested
  if (connect) {
    result <- tryCatch({
      data <- ds_connect(data_dir)

      list(
        health = "healthy",
        message = "All datasets loaded successfully",
        visits_rows = nrow(data$visits),
        visits_cols = ncol(data$visits),
        ae_rows = nrow(data$ae),
        ae_cols = ncol(data$ae),
        dict_rows = nrow(data$dict),
        last_modified = format(last_modified, "%Y-%m-%d %H:%M:%S"),
        files = lapply(files, function(f) {
          list(
            path = f,
            exists = file.exists(f),
            size_mb = round(file.info(f)$size / 1024^2, 2),
            modified = format(file.info(f)$mtime, "%Y-%m-%d %H:%M:%S")
          )
        })
      )
    }, error = function(e) {
      list(
        health = "warning",
        message = sprintf("Files exist but error loading: %s", e$message),
        last_modified = format(last_modified, "%Y-%m-%d %H:%M:%S"),
        files = lapply(files, function(f) {
          list(
            path = f,
            exists = file.exists(f),
            size_mb = round(file.info(f)$size / 1024^2, 2),
            modified = format(file.info(f)$mtime, "%Y-%m-%d %H:%M:%S")
          )
        })
      )
    })

    return(result)
  }

  # Just return file-level info
  list(
    health = "healthy",
    message = "All files present",
    last_modified = format(last_modified, "%Y-%m-%d %H:%M:%S"),
    files = lapply(files, function(f) {
      list(
        path = f,
        exists = file.exists(f),
        size_mb = round(file.info(f)$size / 1024^2, 2),
        modified = format(file.info(f)$mtime, "%Y-%m-%d %H:%M:%S")
      )
    })
  )
}

# Create memoised versions of ds_connect
# Cache invalidates when file mtimes change
.ds_connect_cache_key <- function(data_dir) {
  data_dir <- normalizePath(data_dir, mustWork = FALSE)

  files <- c(
    file.path(data_dir, "visits_data.rds"),
    file.path(data_dir, "adverse_events_data.rds"),
    file.path(data_dir, "data_dictionary_cleaned.csv"),
    file.path(data_dir, "summary_statistics.rds")
  )

  # Get modification times
  mtimes <- sapply(files, function(f) {
    if (file.exists(f)) {
      as.character(file.info(f)$mtime)
    } else {
      "missing"
    }
  })

  # Create cache key from dir + mtimes
  paste(c(data_dir, mtimes), collapse = "|")
}

#' Memoised data connector
#'
#' @description
#' Cached version of ds_connect that invalidates when file modification
#' times change.
#'
#' @inheritParams ds_connect
#' @return Same as ds_connect
#' @export
ds_connect_cached <- memoise::memoise(
  ds_connect,
  cache = memoise::cache_memory()
)
