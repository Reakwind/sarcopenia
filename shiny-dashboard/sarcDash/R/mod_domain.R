#' Generic Domain Module UI
#' @param id Module namespace ID
#' @param domain_name Domain name (demographics, cognitive, medical, physical, adherence, adverse_events)
#' @param i18n Translator object
#' @return Shiny UI
#' @noRd
mod_domain_ui <- function(id, domain_name = "demographics", i18n = NULL) {
  ns <- NS(id)

  div(
    class = "container-fluid mt-3",
    h3(if (!is.null(i18n)) i18n$t(tools::toTitleCase(gsub("_", " ", domain_name))) else tools::toTitleCase(gsub("_", " ", domain_name))),

    div(
      class = "row mb-3",
      div(
        class = "col-12",
        if (requireNamespace("reactable", quietly = TRUE)) {
          reactable::reactableOutput(ns("domain_table"))
        } else {
          div(class = "alert alert-info", "reactable package required")
        }
      )
    ),

    div(
      class = "row",
      div(
        class = "col-md-6",
        h5("Summary Statistics"),
        uiOutput(ns("summary_stats"))
      ),
      div(
        class = "col-md-6",
        h5("Distribution"),
        if (requireNamespace("plotly", quietly = TRUE)) {
          plotly::plotlyOutput(ns("domain_plot"))
        }
      )
    )
  )
}

#' Generic Domain Module Server
#' @param id Module namespace ID
#' @param domain Domain prefix (demo, cog, med, phys, adh, ae)
#' @param cohort_data Reactive cohort data from cohort builder
#' @return Module server logic
#' @noRd
mod_domain_server <- function(id, domain = "demo", cohort_data = NULL) {
  moduleServer(id, function(input, output, session) {

    # Get domain-specific columns
    domain_data <- reactive({
      if (is.null(cohort_data)) return(NULL)
      data <- cohort_data()
      if (is.null(data)) return(NULL)

      # Select columns matching domain prefix
      domain_cols <- grep(paste0("^", domain, "_"), names(data), value = TRUE)
      if (length(domain_cols) == 0) return(NULL)

      data[, c("id_client_id", "id_visit_no", domain_cols)]
    })

    # Render table
    output$domain_table <- reactable::renderReactable({
      data <- domain_data()
      if (is.null(data)) {
        # Return empty reactable with message
        return(reactable::reactable(
          data.frame(Message = "No data available. Please visit the Cohort Builder tab first."),
          columns = list(Message = reactable::colDef(name = ""))
        ))
      }

      if (nrow(data) == 0) {
        return(reactable::reactable(
          data.frame(Message = "No data matches the current cohort filters."),
          columns = list(Message = reactable::colDef(name = ""))
        ))
      }

      reactable::reactable(
        data,
        searchable = TRUE,
        filterable = TRUE,
        sortable = TRUE,
        defaultPageSize = 10,
        showPageSizeOptions = TRUE,
        striped = TRUE,
        highlight = TRUE
      )
    })

    # Summary statistics
    output$summary_stats <- renderUI({
      data <- domain_data()
      if (is.null(data)) {
        return(
          div(
            class = "alert alert-info",
            icon("info-circle"),
            " No data loaded. Visit the Cohort Builder tab to select data."
          )
        )
      }

      if (nrow(data) == 0) {
        return(
          div(
            class = "alert alert-warning",
            icon("filter"),
            " No records match the current cohort filters."
          )
        )
      }

      tagList(
        tags$dl(
          tags$dt("Total Records:"),
          tags$dd(nrow(data)),
          tags$dt("Unique Patients:"),
          tags$dd(length(unique(data$id_client_id))),
          tags$dt("Variables:"),
          tags$dd(ncol(data) - 2)
        )
      )
    })

    # Simple plot with downsampling for performance
    output$domain_plot <- plotly::renderPlotly({
      data <- domain_data()
      if (is.null(data) || ncol(data) < 3) return(NULL)

      # Plot first numeric variable
      numeric_cols <- names(data)[sapply(data, is.numeric)]
      numeric_cols <- setdiff(numeric_cols, c("id_client_id", "id_visit_no"))

      if (length(numeric_cols) == 0) return(NULL)

      # Downsample to max 500 points for performance (scales to 200 patients)
      plot_data <- data
      if (nrow(data) > 500) {
        set.seed(42)  # Reproducible sampling
        sample_idx <- sample(seq_len(nrow(data)), size = 500, replace = FALSE)
        plot_data <- data[sample_idx, ]
      }

      plotly::plot_ly(plot_data, y = ~get(numeric_cols[1]), type = "box") %>%
        plotly::layout(
          title = paste("Distribution of", numeric_cols[1]),
          annotations = if (nrow(data) > 500) {
            list(
              text = sprintf("Showing %d of %d points", nrow(plot_data), nrow(data)),
              xref = "paper", yref = "paper",
              x = 0.5, y = 1.05,
              xanchor = "center", yanchor = "bottom",
              showarrow = FALSE,
              font = list(size = 10, color = "gray")
            )
          } else NULL
        )
    })
  })
}
