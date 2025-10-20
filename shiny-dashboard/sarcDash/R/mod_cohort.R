#' Cohort Builder Module UI
#'
#' @param id Module namespace ID
#' @param i18n Translator object
#' @return Shiny UI
#' @noRd
mod_cohort_ui <- function(id, i18n = NULL) {
  ns <- NS(id)

  bslib::page_sidebar(
    sidebar = bslib::sidebar(
      title = if (!is.null(i18n)) i18n$t("Filters") else "Filters",
      width = 300,

      # Age range
      sliderInput(
        ns("age_range"),
        label = if (!is.null(i18n)) i18n$t("Age") else "Age",
        min = 40, max = 100, value = c(40, 100), step = 1
      ),

      # Gender
      checkboxGroupInput(
        ns("gender"),
        label = if (!is.null(i18n)) i18n$t("Gender") else "Gender",
        choices = c("Male" = "male", "Female" = "female"),
        selected = c("male", "female")
      ),

      # MoCA range
      sliderInput(
        ns("moca_range"),
        label = "MoCA",
        min = 0, max = 30, value = c(0, 30), step = 1
      ),

      # DSST range
      sliderInput(
        ns("dsst_range"),
        label = "DSST",
        min = 0, max = 100, value = c(0, 100), step = 1
      ),

      # Visit number (supports 0-3)
      checkboxGroupInput(
        ns("visit_number"),
        label = if (!is.null(i18n)) i18n$t("Visit Number") else "Visit Number",
        choices = list(
          "Visit 0" = "0",
          "Visit 1" = "1",
          "Visit 2" = "2",
          "Visit 3" = "3"
        ),
        selected = c("0", "1", "2", "3")
      ),

      # Retention filter
      checkboxInput(
        ns("retention_only"),
        label = if (!is.null(i18n)) i18n$t("Only patients with both visits") else "Only patients with both visits",
        value = FALSE
      ),

      # Action buttons
      div(
        class = "d-grid gap-2 mt-3",
        actionButton(
          ns("reset_filters"),
          label = if (!is.null(i18n)) i18n$t("Reset Filters") else "Reset Filters",
          class = "btn-secondary w-100"
        ),
        downloadButton(
          ns("save_filters"),
          label = if (!is.null(i18n)) i18n$t("Save Filter Set") else "Save Filter Set",
          class = "btn-primary w-100"
        )
      )
    ),

    # Main content
    div(
      class = "container-fluid",
      h3(if (!is.null(i18n)) i18n$t("Cohort Builder") else "Cohort Builder"),

      # Summary cards
      div(
        class = "row mb-4 mt-3",
        div(
          class = "col-md-4",
          div(
            class = "card",
            div(
              class = "card-body text-center",
              h6(class = "text-muted", if (!is.null(i18n)) i18n$t("Patients") else "Patients"),
              h2(class = "text-primary", uiOutput(ns("n_patients")))
            )
          )
        ),
        div(
          class = "col-md-4",
          div(
            class = "card",
            div(
              class = "card-body text-center",
              h6(class = "text-muted", if (!is.null(i18n)) i18n$t("Visits") else "Visits"),
              h2(class = "text-info", uiOutput(ns("n_visits")))
            )
          )
        ),
        div(
          class = "col-md-4",
          div(
            class = "card",
            div(
              class = "card-body text-center",
              h6(class = "text-muted", if (!is.null(i18n)) i18n$t("Retention Rate") else "Retention Rate"),
              h2(class = "text-success", uiOutput(ns("retention_rate")))
            )
          )
        )
      ),

      # Filter query display
      div(
        class = "row mb-3",
        div(
          class = "col-12",
          div(
            class = "card",
            div(
              class = "card-header bg-light",
              h5(class = "mb-0", if (!is.null(i18n)) i18n$t("Current Filters") else "Current Filters")
            ),
            div(
              class = "card-body",
              uiOutput(ns("filter_description"))
            )
          )
        )
      )
    )
  )
}

#' Cohort Builder Module Server
#'
#' @param id Module namespace ID
#' @param i18n Reactive translator object
#' @param uploaded_data Reactive uploaded CSV data (optional)
#' @return Reactive filtered data
#' @noRd
mod_cohort_server <- function(id, i18n = NULL, uploaded_data = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Load data (prioritize uploaded data if available)
    data <- reactive({
      # Check for uploaded data first
      if (!is.null(uploaded_data) && is.reactive(uploaded_data)) {
        uploaded <- uploaded_data()
        if (!is.null(uploaded)) {
          # Return uploaded data in standard format
          return(list(
            visits = uploaded,
            ae = NULL,
            dict = NULL,
            summary = NULL
          ))
        }
      }

      # Fall back to default data directory
      tryCatch({
        data_dir <- here::here("data")
        ds_connect(data_dir)
      }, error = function(e) {
        NULL
      })
    })

    # Debounced slider inputs (500ms delay for performance)
    age_range_debounced <- reactive(input$age_range) %>% debounce(500)
    moca_range_debounced <- reactive(input$moca_range) %>% debounce(500)
    dsst_range_debounced <- reactive(input$dsst_range) %>% debounce(500)

    # Filtered data based on current filters (dplyr optimized)
    filtered_data <- reactive({
      d <- data()
      if (is.null(d) || is.null(d$visits)) return(NULL)

      visits <- d$visits

      # Age filter (debounced)
      if (!is.null(age_range_debounced())) {
        visits <- visits %>%
          dplyr::filter(id_age >= age_range_debounced()[1],
                        id_age <= age_range_debounced()[2])
      }

      # Gender filter
      if (!is.null(input$gender) && length(input$gender) > 0) {
        visits <- visits %>%
          dplyr::filter(tolower(id_gender) %in% input$gender)
      }

      # MoCA filter (debounced)
      if (!is.null(moca_range_debounced())) {
        visits <- visits %>%
          dplyr::filter(!is.na(cog_moca_total),
                        cog_moca_total >= moca_range_debounced()[1],
                        cog_moca_total <= moca_range_debounced()[2])
      }

      # DSST filter (debounced)
      if (!is.null(dsst_range_debounced())) {
        visits <- visits %>%
          dplyr::filter(!is.na(cog_dsst_score),
                        cog_dsst_score >= dsst_range_debounced()[1],
                        cog_dsst_score <= dsst_range_debounced()[2])
      }

      # Visit number filter (supports multiple selections 0-3)
      if (!is.null(input$visit_number) && length(input$visit_number) > 0) {
        visit_nums <- as.numeric(input$visit_number)
        visits <- visits %>%
          dplyr::filter(id_visit_no %in% visit_nums)
      }

      # Retention filter (dplyr optimized)
      if (!is.null(input$retention_only) && input$retention_only) {
        # Get patients with at least 2 visits
        retained_patients <- visits %>%
          dplyr::count(id_client_id) %>%
          dplyr::filter(n >= 2) %>%
          dplyr::pull(id_client_id)

        visits <- visits %>%
          dplyr::filter(id_client_id %in% retained_patients)
      }

      visits
    })

    # Cohort summary metrics
    output$n_patients <- renderUI({
      visits <- filtered_data()
      if (is.null(visits)) return("--")

      n <- length(unique(visits$id_client_id))
      tags$strong(format(n, big.mark = ","))
    })

    output$n_visits <- renderUI({
      visits <- filtered_data()
      if (is.null(visits)) return("--")

      n <- nrow(visits)
      tags$strong(format(n, big.mark = ","))
    })

    output$retention_rate <- renderUI({
      visits <- filtered_data()
      if (is.null(visits)) return("--")

      # Dplyr optimized retention calculation
      retention_stats <- visits %>%
        dplyr::count(id_client_id) %>%
        dplyr::summarise(
          retained = sum(n >= 2),
          total = dplyr::n()
        )

      if (retention_stats$total == 0) return("--")

      pct <- round(100 * retention_stats$retained / retention_stats$total, 1)
      tags$strong(paste0(pct, "%"))
    })

    # Filter description (human-readable)
    output$filter_description <- renderUI({
      filters <- list()

      if (!is.null(input$age_range)) {
        filters <- c(filters, list(
          tags$span(
            class = "badge bg-primary me-2",
            paste0("Age: ", input$age_range[1], "-", input$age_range[2])
          )
        ))
      }

      if (!is.null(input$gender) && length(input$gender) > 0) {
        gender_str <- paste(input$gender, collapse = ", ")
        filters <- c(filters, list(
          tags$span(
            class = "badge bg-info me-2",
            paste0("Gender: ", gender_str)
          )
        ))
      }

      if (!is.null(input$visit_number) && length(input$visit_number) > 0) {
        # Show visit filter only if not all 4 visits selected
        if (length(input$visit_number) < 4) {
          visit_str <- paste0("Visit(s): ", paste(input$visit_number, collapse = ", "))
          filters <- c(filters, list(
            tags$span(
              class = "badge bg-secondary me-2",
              visit_str
            )
          ))
        }
      }

      if (!is.null(input$retention_only) && input$retention_only) {
        filters <- c(filters, list(
          tags$span(
            class = "badge bg-success me-2",
            "Retention: Both visits only"
          )
        ))
      }

      if (length(filters) == 0) {
        return(tags$p(class = "text-muted", "No filters applied"))
      }

      tagList(filters)
    })

    # Reset filters
    observeEvent(input$reset_filters, {
      updateSliderInput(session, "age_range", value = c(40, 100))
      updateCheckboxGroupInput(session, "gender", selected = c("male", "female"))
      updateSliderInput(session, "moca_range", value = c(0, 30))
      updateSliderInput(session, "dsst_range", value = c(0, 100))
      updateCheckboxGroupInput(session, "visit_number", selected = c("0", "1", "2", "3"))
      updateCheckboxInput(session, "retention_only", value = FALSE)
    })

    # Save filters as JSON
    output$save_filters <- downloadHandler(
      filename = function() {
        paste0("cohort_filters_", format(Sys.Date(), "%Y%m%d"), ".json")
      },
      content = function(file) {
        filter_set <- list(
          age_range = input$age_range,
          gender = input$gender,
          moca_range = input$moca_range,
          dsst_range = input$dsst_range,
          visit_number = input$visit_number,
          retention_only = input$retention_only,
          timestamp = Sys.time()
        )
        jsonlite::write_json(filter_set, file, pretty = TRUE, auto_unbox = TRUE)
      }
    )

    # Return filtered data for other modules to use
    return(filtered_data)
  })
}

#' Compute retention metric
#'
#' @param data Data frame with id_client_id column
#' @return List with retention statistics
#' @export
compute_retention <- function(data) {
  if (is.null(data) || !"id_client_id" %in% names(data)) {
    return(list(retained = 0, total = 0, rate = 0))
  }

  patient_counts <- table(data$id_client_id)
  retained <- sum(patient_counts >= 2)
  total <- length(patient_counts)
  rate <- if (total > 0) retained / total else 0

  list(
    retained = retained,
    total = total,
    rate = rate
  )
}

#' Generate human-readable filter query
#'
#' @param filters List of filter values
#' @return Character string describing filters
#' @export
describe_filters <- function(filters) {
  descriptions <- character()

  if (!is.null(filters$age_range)) {
    descriptions <- c(descriptions,
      paste0("Age: ", filters$age_range[1], "-", filters$age_range[2]))
  }

  if (!is.null(filters$gender) && length(filters$gender) > 0) {
    descriptions <- c(descriptions,
      paste0("Gender: ", paste(filters$gender, collapse = ", ")))
  }

  if (!is.null(filters$visit_number) && length(filters$visit_number) > 0 && length(filters$visit_number) < 4) {
    descriptions <- c(descriptions,
      paste0("Visit(s): ", paste(filters$visit_number, collapse = ", ")))
  }

  if (!is.null(filters$retention_only) && filters$retention_only) {
    descriptions <- c(descriptions, "Retention: Both visits only")
  }

  if (length(descriptions) == 0) {
    return("No filters applied")
  }

  paste(descriptions, collapse = "; ")
}
