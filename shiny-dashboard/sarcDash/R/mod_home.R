#' Home Module UI
#'
#' @description
#' Landing page with dataset health, quick links, and guided tour
#'
#' @param id Module namespace ID
#' @param i18n Translator object
#'
#' @return Shiny UI
#' @noRd
mod_home_ui <- function(id, i18n = NULL) {
  ns <- NS(id)

  div(
    id = ns("home_container"),
    class = "container-fluid mt-3",

    # PHI Warning banner
    uiOutput(ns("phi_banner")),

    # Loading overlay (if waiter is available)
    if (requireNamespace("waiter", quietly = TRUE)) {
      waiter::use_waiter()
    },

    # Main content
    div(
      class = "row mt-3",

      # Dataset Health Card
      div(
        class = "col-md-4",
        id = ns("dataset_health_card"),
        div(
          class = "card h-100",
          div(
            class = "card-header bg-primary text-white",
            tags$h5(
              class = "card-title mb-0",
              icon("database"),
              " ",
              if (!is.null(i18n)) i18n$t("Dataset Health") else "Dataset Health"
            )
          ),
          div(
            class = "card-body",
            uiOutput(ns("health_content")),
            tags$hr(),
            # CSV upload for custom data
            div(
              class = "mt-2",
              h6(
                class = "text-muted mb-2",
                icon("upload"),
                " ",
                if (!is.null(i18n)) i18n$t("Upload Custom Data") else "Upload Custom Data"
              ),
              fileInput(
                ns("csv_upload"),
                label = if (!is.null(i18n)) i18n$t("Upload CSV File") else "Upload CSV File",
                accept = c(".csv", "text/csv"),
                buttonLabel = if (!is.null(i18n)) i18n$t("Browse...") else "Browse...",
                placeholder = if (!is.null(i18n)) i18n$t("No file chosen") else "No file chosen"
              ),
              uiOutput(ns("upload_status"))
            )
          )
        )
      ),

      # Quick Links Card
      div(
        class = "col-md-4",
        id = ns("quick_links_card"),
        div(
          class = "card h-100",
          div(
            class = "card-header bg-info text-white",
            tags$h5(
              class = "card-title mb-0",
              icon("bolt"),
              " ",
              if (!is.null(i18n)) i18n$t("Quick Links") else "Quick Links"
            )
          ),
          div(
            class = "card-body",
            div(
              class = "d-grid gap-2",
              actionButton(
                ns("goto_cohort"),
                label = tagList(
                  icon("filter"),
                  " ",
                  if (!is.null(i18n)) i18n$t("Cohort Builder") else "Cohort Builder"
                ),
                class = "btn btn-outline-primary btn-lg",
                width = "100%"
              ),
              actionButton(
                ns("goto_domains"),
                label = tagList(
                  icon("chart-line"),
                  " ",
                  if (!is.null(i18n)) i18n$t("Explore Domains") else "Explore Domains"
                ),
                class = "btn btn-outline-secondary btn-lg",
                width = "100%"
              ),
              actionButton(
                ns("goto_qc"),
                label = tagList(
                  icon("check-circle"),
                  " ",
                  if (!is.null(i18n)) i18n$t("Quality Checks") else "Quality Checks"
                ),
                class = "btn btn-outline-success btn-lg",
                width = "100%"
              )
            )
          )
        )
      ),

      # Learn Card (Tour)
      div(
        class = "col-md-4",
        id = ns("learn_card"),
        div(
          class = "card h-100",
          div(
            class = "card-header bg-success text-white",
            tags$h5(
              class = "card-title mb-0",
              icon("graduation-cap"),
              " ",
              if (!is.null(i18n)) i18n$t("Learn") else "Learn"
            )
          ),
          div(
            class = "card-body",
            p(
              class = "card-text",
              if (!is.null(i18n)) {
                i18n$t("Take a guided tour to learn about the dashboard features")
              } else {
                "Take a guided tour to learn about the dashboard features"
              }
            ),
            actionButton(
              ns("start_tour"),
              label = tagList(
                icon("play-circle"),
                " ",
                if (!is.null(i18n)) i18n$t("Start Tour") else "Start Tour"
              ),
              class = "btn btn-success btn-lg",
              width = "100%"
            ),
            tags$hr(),
            div(
              class = "form-check",
              checkboxInput(
                ns("show_tour_on_load"),
                label = if (!is.null(i18n)) {
                  i18n$t("Show tour on startup")
                } else {
                  "Show tour on startup"
                },
                value = FALSE
              )
            )
          )
        )
      )
    ),

    # Additional info row
    div(
      class = "row mt-4",
      div(
        class = "col-12",
        id = ns("welcome_message"),
        div(
          class = "card",
          div(
            class = "card-body",
            h5(
              class = "card-title",
              if (!is.null(i18n)) i18n$t("Welcome") else "Welcome"
            ),
            p(
              class = "card-text",
              if (!is.null(i18n)) {
                i18n$t("Use the navigation above to explore different aspects of the sarcopenia study data")
              } else {
                "Use the navigation above to explore different aspects of the sarcopenia study data"
              }
            )
          )
        )
      )
    ),

    # Cicerone guide (if cicerone is available)
    if (requireNamespace("cicerone", quietly = TRUE)) {
      cicerone::use_cicerone()
    }
  )
}

#' Home Module Server
#'
#' @param id Module namespace ID
#' @param i18n Reactive translator object
#' @param parent_session Parent Shiny session
#'
#' @return Module server logic
#' @noRd
mod_home_server <- function(id, i18n = NULL, parent_session = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive data status
    data_status <- reactive({
      # Show spinner (if waiter is available)
      if (requireNamespace("waiter", quietly = TRUE)) {
        waiter::waiter_show(
          html = tagList(
            waiter::spin_fading_circles(),
            h4("Loading dataset status...")
          ),
          color = "#f8f9fa"
        )
        on.exit(waiter::waiter_hide())
      }

      # Get status with error handling
      tryCatch({
        ds_status(connect = FALSE)
      }, error = function(e) {
        list(
          status = "error",
          error_msg = e$message
        )
      })
    })

    # Handle CSV upload
    uploaded_data <- reactiveVal(NULL)

    observeEvent(input$csv_upload, {
      req(input$csv_upload)

      # Try to load and validate CSV
      result <- tryCatch({
        data <- ds_load_csv(input$csv_upload$datapath)
        uploaded_data(data)
        list(
          success = TRUE,
          message = sprintf("Successfully loaded %d rows and %d columns", nrow(data), ncol(data)),
          n_patients = if ("id_client_id" %in% names(data)) length(unique(data$id_client_id)) else NA
        )
      }, error = function(e) {
        uploaded_data(NULL)
        list(
          success = FALSE,
          message = e$message
        )
      }, warning = function(w) {
        # Data loaded but with warnings
        list(
          success = TRUE,
          message = sprintf("Loaded with warnings: %s", w$message)
        )
      })

      # Store result for display
      session$userData$upload_result <- result
    })

    # Display upload status
    output$upload_status <- renderUI({
      req(input$csv_upload)
      result <- session$userData$upload_result

      if (is.null(result)) return(NULL)

      if (result$success) {
        div(
          class = "alert alert-success alert-dismissible fade show",
          role = "alert",
          icon("check-circle"),
          " ",
          result$message,
          if (!is.na(result$n_patients)) {
            tagList(tags$br(), tags$small(sprintf("Unique patients: %d", result$n_patients)))
          },
          tags$button(
            type = "button",
            class = "btn-close",
            `data-bs-dismiss` = "alert"
          )
        )
      } else {
        div(
          class = "alert alert-danger alert-dismissible fade show",
          role = "alert",
          icon("exclamation-triangle"),
          " ",
          result$message,
          tags$button(
            type = "button",
            class = "btn-close",
            `data-bs-dismiss` = "alert"
          )
        )
      }
    })

    # PHI Warning banner
    output$phi_banner <- renderUI({
      i18n_obj <- if (is.reactive(i18n)) i18n() else i18n

      # Get last updated
      status <- data_status()
      last_updated_text <- ""

      if (!is.null(status) && status$health != "error" && !is.null(status$last_modified)) {
        formatted_time <- format(status$last_modified, "%Y-%m-%d %H:%M")
        last_updated_text <- paste0(
          if (!is.null(i18n_obj)) i18n_obj$t("Last updated") else "Last updated",
          ": ",
          formatted_time
        )
      }

      div(
        class = "alert alert-warning alert-dismissible fade show",
        role = "alert",
        tags$strong(
          if (!is.null(i18n_obj)) i18n_obj$t("PHI Warning") else "PHI Warning"
        ),
        " ",
        if (!is.null(i18n_obj)) {
          i18n_obj$t("This dashboard contains protected health information. Do not share screenshots or exports.")
        } else {
          "This dashboard contains protected health information. Do not share screenshots or exports."
        },
        if (nchar(last_updated_text) > 0) {
          tagList(
            tags$br(),
            tags$small(class = "text-muted", last_updated_text)
          )
        },
        tags$button(
          type = "button",
          class = "btn-close",
          `data-bs-dismiss` = "alert",
          `aria-label` = if (!is.null(i18n_obj)) i18n_obj$t("Close") else "Close"
        )
      )
    })

    # Dataset health content
    output$health_content <- renderUI({
      status <- data_status()

      if (!is.null(status) && status$health == "error") {
        # Show error alert
        div(
          class = "alert alert-danger",
          role = "alert",
          icon("exclamation-triangle"),
          " ",
          strong("Error loading data:"),
          tags$br(),
          tags$small(status$error_msg)
        )
      } else if (!is.null(status)) {
        # Show health metrics
        tagList(
          div(
            class = "mb-3",
            h6(class = "text-muted mb-1", "Status"),
            h4(
              class = if (status$health == "healthy") "text-success" else "text-warning",
              icon(if (status$health == "healthy") "check-circle" else "exclamation-circle"),
              " ",
              toupper(status$health)
            )
          ),
          div(
            class = "mb-2",
            tags$dl(
              class = "row mb-0",
              tags$dt(class = "col-sm-6", "Files:"),
              tags$dd(class = "col-sm-6", length(status$files)),
              tags$dt(class = "col-sm-6", "Total Rows:"),
              tags$dd(
                class = "col-sm-6",
                if (!is.null(status$row_counts)) {
                  sum(unlist(status$row_counts), na.rm = TRUE)
                } else {
                  "N/A"
                }
              ),
              tags$dt(class = "col-sm-6", "Total Columns:"),
              tags$dd(
                class = "col-sm-6",
                if (!is.null(status$col_counts)) {
                  sum(unlist(status$col_counts), na.rm = TRUE)
                } else {
                  "N/A"
                }
              )
            )
          )
        )
      } else {
        div(
          class = "text-center text-muted",
          icon("spinner", class = "fa-spin"),
          " ",
          "Loading..."
        )
      }
    })

    # Navigation handlers
    observeEvent(input$goto_cohort, {
      if (!is.null(parent_session)) {
        updateNavbarPage(parent_session, "main_navbar", selected = "cohort")
      }
    })

    observeEvent(input$goto_domains, {
      if (!is.null(parent_session)) {
        updateNavbarPage(parent_session, "main_navbar", selected = "demographics")
      }
    })

    observeEvent(input$goto_qc, {
      if (!is.null(parent_session)) {
        updateNavbarPage(parent_session, "main_navbar", selected = "qc")
      }
    })

    # Cicerone tour (only if cicerone is available)
    if (requireNamespace("cicerone", quietly = TRUE)) {
      tour <- reactive({
        i18n_obj <- if (is.reactive(i18n)) i18n() else i18n

        cicerone::Cicerone$
          new()$
          step(
            el = "dataset_health_card",
            title = if (!is.null(i18n_obj)) i18n_obj$t("Dataset Health") else "Dataset Health",
            description = if (!is.null(i18n_obj)) {
              i18n_obj$t("View the current status of your dataset including row counts and last update time")
            } else {
              "View the current status of your dataset including row counts and last update time"
            }
          )$
          step(
            el = "quick_links_card",
            title = if (!is.null(i18n_obj)) i18n_obj$t("Quick Links") else "Quick Links",
            description = if (!is.null(i18n_obj)) {
              i18n_obj$t("Quick access to frequently used sections of the dashboard")
            } else {
              "Quick access to frequently used sections of the dashboard"
            }
          )$
          step(
            el = "learn_card",
            title = if (!is.null(i18n_obj)) i18n_obj$t("Learn") else "Learn",
            description = if (!is.null(i18n_obj)) {
              i18n_obj$t("Start this tour anytime to learn about dashboard features")
            } else {
              "Start this tour anytime to learn about dashboard features"
            }
          )$
          step(
            el = "main_navbar",
            title = if (!is.null(i18n_obj)) i18n_obj$t("Navigation") else "Navigation",
            description = if (!is.null(i18n_obj)) {
              i18n_obj$t("Use the top navigation to access different sections")
            } else {
              "Use the top navigation to access different sections"
            }
          )$
          step(
            el = "language",
            title = if (!is.null(i18n_obj)) i18n_obj$t("Language") else "Language",
            description = if (!is.null(i18n_obj)) {
              i18n_obj$t("Switch between English and Hebrew")
            } else {
              "Switch between English and Hebrew"
            }
          )$
          step(
            el = "welcome_message",
            title = if (!is.null(i18n_obj)) i18n_obj$t("Get Started") else "Get Started",
            description = if (!is.null(i18n_obj)) {
              i18n_obj$t("You are ready to explore the data")
            } else {
              "You are ready to explore the data"
            }
          )
      })

      # Start tour on button click
      observeEvent(input$start_tour, {
        tour()$init()$start()
      })

      # Auto-start tour on first load if enabled
      observe({
        if (input$show_tour_on_load) {
          tour()$init()$start()
        }
      })
    }

    # Return uploaded data for use by other modules
    return(uploaded_data)
  })
}
