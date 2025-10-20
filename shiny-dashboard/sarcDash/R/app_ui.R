#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  # Initialize translator
  i18n <- init_i18n()

  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    # Your application UI logic
    fluidPage(
      # Language and theme controls in navbar
      div(
        id = "top-controls",
        class = "d-flex justify-content-end p-2",
        style = "background-color: #f8f9fa; border-bottom: 1px solid #dee2e6;",

        # Language selector
        div(
          class = "me-3",
          language_selector_ui("language", selected = "en", i18n = i18n)
        )
      ),

      # Skip links for accessibility
      tags$a(
        href = "#main-content",
        class = "skip-link visually-hidden-focusable",
        i18n$t("Skip to content")
      ),

      # Main content area (placeholder for now)
      div(
        id = "main-content",
        class = "container-fluid mt-3",

        h1(
          id = "app-title",
          class = "text-center mb-4",
          i18n$t("Sarcopenia Study Dashboard")
        ),

        # PHI Warning banner
        div(
          class = "alert alert-warning alert-dismissible fade show",
          role = "alert",
          tags$strong(i18n$t("PHI Warning")),
          " ",
          i18n$t("This dashboard contains protected health information. Do not share screenshots or exports."),
          tags$button(
            type = "button",
            class = "btn-close",
            `data-bs-dismiss` = "alert",
            `aria-label` = i18n$t("Close")
          )
        ),

        # Placeholder content
        div(
          class = "card",
          div(
            class = "card-body",
            h5(class = "card-title", "Welcome to sarcDash"),
            p(class = "card-text", "Dashboard content will be added in upcoming prompts."),
            tags$ul(
              tags$li("Prompt 3: App shell with navigation"),
              tags$li("Prompt 4: Home page with dataset health"),
              tags$li("Prompt 5: Data dictionary viewer"),
              tags$li("Prompt 6: Cohort builder")
            )
          )
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    # Set initial lang and dir attributes
    tags$script(HTML("
      document.documentElement.setAttribute('lang', 'en');
      document.documentElement.setAttribute('dir', 'ltr');
    ")),

    # Favicon and bundle
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "sarcDash"
    ),

    # RTL CSS
    rtl_css_tag(),

    # Skip link styles
    tags$style(HTML("
      .skip-link {
        position: absolute;
        left: -9999px;
        z-index: 999;
        padding: 1em;
        background-color: #000;
        color: white;
        opacity: 0;
      }
      .skip-link:focus {
        left: 50%;
        transform: translateX(-50%);
        opacity: 1;
      }
    "))
  )
}
