#' Data Dictionary Module UI
#'
#' @description
#' Interactive data dictionary viewer with search and prefix filtering
#'
#' @param id Module namespace ID
#' @param i18n Translator object
#'
#' @return Shiny UI
#' @noRd
mod_dictionary_ui <- function(id, i18n = NULL) {
  ns <- NS(id)

  div(
    class = "container-fluid mt-3",

    # Header row
    div(
      class = "row mb-3",
      div(
        class = "col-12",
        h3(
          if (!is.null(i18n)) i18n$t("Data Dictionary") else "Data Dictionary"
        ),
        p(
          class = "text-muted",
          if (!is.null(i18n)) {
            i18n$t("Variable mapping and metadata for all study data")
          } else {
            "Variable mapping and metadata for all study data"
          }
        )
      )
    ),

    # Prefix legend cards
    div(
      class = "row mb-4",
      div(
        class = "col-12",
        h5(
          if (!is.null(i18n)) i18n$t("Filter by Prefix") else "Filter by Prefix"
        ),
        div(
          class = "d-flex flex-wrap gap-2",
          id = ns("prefix_legend"),

          # ID prefix
          actionButton(
            ns("filter_id"),
            label = tagList(
              tags$span(class = "badge bg-secondary me-1", "id_"),
              if (!is.null(i18n)) i18n$t("Identifiers") else "Identifiers"
            ),
            class = "btn btn-outline-secondary"
          ),

          # Demo prefix
          actionButton(
            ns("filter_demo"),
            label = tagList(
              tags$span(class = "badge bg-info me-1", "demo_"),
              if (!is.null(i18n)) i18n$t("Demographics") else "Demographics"
            ),
            class = "btn btn-outline-info"
          ),

          # Cog prefix
          actionButton(
            ns("filter_cog"),
            label = tagList(
              tags$span(class = "badge bg-primary me-1", "cog_"),
              if (!is.null(i18n)) i18n$t("Cognitive") else "Cognitive"
            ),
            class = "btn btn-outline-primary"
          ),

          # Med prefix
          actionButton(
            ns("filter_med"),
            label = tagList(
              tags$span(class = "badge bg-danger me-1", "med_"),
              if (!is.null(i18n)) i18n$t("Medical") else "Medical"
            ),
            class = "btn btn-outline-danger"
          ),

          # Phys prefix
          actionButton(
            ns("filter_phys"),
            label = tagList(
              tags$span(class = "badge bg-success me-1", "phys_"),
              if (!is.null(i18n)) i18n$t("Physical") else "Physical"
            ),
            class = "btn btn-outline-success"
          ),

          # Adh prefix
          actionButton(
            ns("filter_adh"),
            label = tagList(
              tags$span(class = "badge bg-warning me-1", "adh_"),
              if (!is.null(i18n)) i18n$t("Adherence") else "Adherence"
            ),
            class = "btn btn-outline-warning"
          ),

          # AE prefix
          actionButton(
            ns("filter_ae"),
            label = tagList(
              tags$span(class = "badge bg-dark me-1", "ae_"),
              if (!is.null(i18n)) i18n$t("Adverse Events") else "Adverse Events"
            ),
            class = "btn btn-outline-dark"
          ),

          # Clear filter
          actionButton(
            ns("clear_filter"),
            label = if (!is.null(i18n)) i18n$t("Clear Filter") else "Clear Filter",
            class = "btn btn-light"
          )
        )
      )
    ),

    # Search and export row
    div(
      class = "row mb-3",
      div(
        class = "col-md-8",
        textInput(
          ns("search_text"),
          label = if (!is.null(i18n)) i18n$t("Search") else "Search",
          placeholder = if (!is.null(i18n)) {
            i18n$t("Search by any column...")
          } else {
            "Search by any column..."
          },
          width = "100%"
        )
      ),
      div(
        class = "col-md-4",
        tags$label("\u00A0"),  # Non-breaking space for alignment
        div(
          downloadButton(
            ns("export_csv"),
            label = if (!is.null(i18n)) i18n$t("Export CSV") else "Export CSV",
            class = "btn-success w-100"
          )
        )
      )
    ),

    # Table row
    div(
      class = "row",
      div(
        class = "col-12",
        if (requireNamespace("reactable", quietly = TRUE)) {
          reactable::reactableOutput(ns("dictionary_table"))
        } else {
          div(
            class = "alert alert-info",
            "reactable package required for interactive table"
          )
        }
      )
    )
  )
}

#' Data Dictionary Module Server
#'
#' @param id Module namespace ID
#' @param i18n Reactive translator object
#'
#' @return Module server logic
#' @noRd
mod_dictionary_server <- function(id, i18n = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Load data dictionary
    dict_data <- reactive({
      tryCatch({
        data_dir <- here::here("data")
        dict_path <- file.path(data_dir, "data_dictionary_cleaned.csv")

        if (!file.exists(dict_path)) {
          return(NULL)
        }

        dict <- readr::read_csv(dict_path, show_col_types = FALSE)

        # Check for PHI in original names (basic check)
        phi_patterns <- c(
          "social.?security", "ssn", "passport", "license",
          "account.?number", "credit.?card", "phone.?number",
          "email", "address", "zip.?code"
        )

        for (pattern in phi_patterns) {
          if (any(grepl(pattern, dict$original_name, ignore.case = TRUE))) {
            warning(paste("Potential PHI detected in original_name:", pattern))
          }
        }

        dict
      }, error = function(e) {
        NULL
      })
    })

    # Current filter prefix
    filter_prefix <- reactiveVal(NULL)

    # Filtered data
    filtered_data <- reactive({
      dict <- dict_data()
      if (is.null(dict)) return(NULL)

      # Apply prefix filter
      prefix_filter <- filter_prefix()
      if (!is.null(prefix_filter)) {
        dict <- dict[grepl(paste0("^", prefix_filter), dict$new_name), ]
      }

      # Apply search text filter
      search <- input$search_text
      if (!is.null(search) && nchar(search) > 0) {
        # Search across all columns
        matches <- apply(dict, 1, function(row) {
          any(grepl(search, row, ignore.case = TRUE))
        })
        dict <- dict[matches, ]
      }

      dict
    })

    # Prefix filter handlers
    observeEvent(input$filter_id, {
      filter_prefix("id_")
    })

    observeEvent(input$filter_demo, {
      filter_prefix("demo_")
    })

    observeEvent(input$filter_cog, {
      filter_prefix("cog_")
    })

    observeEvent(input$filter_med, {
      filter_prefix("med_")
    })

    observeEvent(input$filter_phys, {
      filter_prefix("phys_")
    })

    observeEvent(input$filter_adh, {
      filter_prefix("adh_")
    })

    observeEvent(input$filter_ae, {
      filter_prefix("ae_")
    })

    observeEvent(input$clear_filter, {
      filter_prefix(NULL)
      updateTextInput(session, "search_text", value = "")
    })

    # Render table
    output$dictionary_table <- reactable::renderReactable({
      dict <- filtered_data()

      if (is.null(dict)) {
        return(NULL)
      }

      # Select and rename columns for display
      display_dict <- dict[, c("original_name", "new_name", "section", "prefix")]

      i18n_obj <- if (is.reactive(i18n)) i18n() else i18n

      reactable::reactable(
        display_dict,
        searchable = FALSE,  # We have our own search
        filterable = FALSE,
        sortable = TRUE,
        defaultPageSize = 25,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(10, 25, 50, 100),
        highlight = TRUE,
        striped = TRUE,
        columns = list(
          original_name = reactable::colDef(
            name = if (!is.null(i18n_obj)) i18n_obj$t("Original Name") else "Original Name",
            minWidth = 200
          ),
          new_name = reactable::colDef(
            name = if (!is.null(i18n_obj)) i18n_obj$t("New Name") else "New Name",
            minWidth = 200,
            style = list(fontFamily = "monospace")
          ),
          section = reactable::colDef(
            name = if (!is.null(i18n_obj)) i18n_obj$t("Domain") else "Domain",
            minWidth = 120
          ),
          prefix = reactable::colDef(
            name = if (!is.null(i18n_obj)) i18n_obj$t("Prefix") else "Prefix",
            minWidth = 80,
            cell = function(value) {
              # Color-code prefixes
              color <- switch(
                value,
                "id" = "secondary",
                "demo" = "info",
                "cog" = "primary",
                "med" = "danger",
                "phys" = "success",
                "adh" = "warning",
                "ae" = "dark",
                "secondary"
              )
              tags$span(
                class = paste0("badge bg-", color),
                paste0(value, "_")
              )
            }
          )
        ),
        theme = reactable::reactableTheme(
          borderColor = "#dee2e6",
          stripedColor = "#f8f9fa",
          highlightColor = "#fff3cd"
        )
      )
    })

    # Export CSV
    output$export_csv <- downloadHandler(
      filename = function() {
        paste0("data_dictionary_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        dict <- filtered_data()
        if (!is.null(dict)) {
          readr::write_csv(dict, file)
        }
      }
    )
  })
}
