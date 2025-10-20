#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  # Initialize translator
  i18n <- init_i18n()

  # Define custom theme
  theme <- bslib::bs_theme(
    version = 5,
    primary = "#2C3E50",
    secondary = "#3498DB",
    success = "#27AE60",
    info = "#17A2B8",
    warning = "#F39C12",
    danger = "#E74C3C",
    base_font = bslib::font_google("Roboto"),
    heading_font = bslib::font_google("Roboto Slab"),
    font_scale = 1.0,
    spacer = "1rem"
  )

  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    # Your application UI logic
    bslib::page_navbar(
      title = i18n$t("Sarcopenia Study Dashboard"),
      id = "main_navbar",
      theme = theme,
      lang = "en",

      # Language selector in navbar
      nav_spacer(),
      nav_item(
        language_selector_ui("language", selected = "en", i18n = i18n)
      ),

      # Skip links for accessibility
      header = tagList(
        tags$a(
          href = "#main-content",
          class = "skip-link visually-hidden-focusable",
          i18n$t("Skip to content")
        ),
        tags$a(
          href = "#filters",
          class = "skip-link visually-hidden-focusable",
          i18n$t("Skip to filters")
        )
      ),

      # Home tab
      nav_panel(
        title = i18n$t("Home"),
        value = "home",
        icon = icon("home"),

        mod_home_ui("home", i18n = i18n)
      ),

      # Data Dictionary tab
      nav_panel(
        title = i18n$t("Data Dictionary"),
        value = "dictionary",
        icon = icon("book"),

        div(
          class = "container-fluid mt-3",
          h3(i18n$t("Data Dictionary")),
          p(i18n$t("Content coming in Prompt 5"))
        )
      ),

      # Cohort Builder tab
      nav_panel(
        title = i18n$t("Cohort Builder"),
        value = "cohort",
        icon = icon("filter"),

        div(
          id = "filters",
          class = "container-fluid mt-3",
          h3(i18n$t("Cohort Builder")),
          p(i18n$t("Content coming in Prompt 6"))
        )
      ),

      # Domains menu
      nav_menu(
        title = i18n$t("Domains"),
        icon = icon("chart-line"),

        nav_panel(
          title = i18n$t("Demographics"),
          value = "demographics",
          div(
            class = "container-fluid mt-3",
            h3(i18n$t("Demographics")),
            p(i18n$t("Content coming in Prompt 7"))
          )
        ),

        nav_panel(
          title = i18n$t("Cognitive"),
          value = "cognitive",
          div(
            class = "container-fluid mt-3",
            h3(i18n$t("Cognitive")),
            p(i18n$t("Content coming in Prompt 8"))
          )
        ),

        nav_panel(
          title = i18n$t("Medical"),
          value = "medical",
          div(
            class = "container-fluid mt-3",
            h3(i18n$t("Medical")),
            p(i18n$t("Content coming in Prompt 9"))
          )
        ),

        nav_panel(
          title = i18n$t("Physical"),
          value = "physical",
          div(
            class = "container-fluid mt-3",
            h3(i18n$t("Physical")),
            p(i18n$t("Content coming in Prompt 10"))
          )
        ),

        nav_panel(
          title = i18n$t("Adherence"),
          value = "adherence",
          div(
            class = "container-fluid mt-3",
            h3(i18n$t("Adherence")),
            p(i18n$t("Content coming in Prompt 11"))
          )
        ),

        nav_panel(
          title = i18n$t("Adverse Events"),
          value = "adverse_events",
          div(
            class = "container-fluid mt-3",
            h3(i18n$t("Adverse Events")),
            p(i18n$t("Content coming in Prompt 12"))
          )
        )
      ),

      # Longitudinal tab
      nav_panel(
        title = i18n$t("Longitudinal"),
        value = "longitudinal",
        icon = icon("chart-area"),

        div(
          class = "container-fluid mt-3",
          h3(i18n$t("Longitudinal")),
          p(i18n$t("Content coming in Prompt 13"))
        )
      ),

      # QC/Missingness tab
      nav_panel(
        title = i18n$t("Quality Checks"),
        value = "qc",
        icon = icon("check-circle"),

        div(
          class = "container-fluid mt-3",
          h3(i18n$t("Quality Checks")),
          p(i18n$t("Content coming in Prompt 14"))
        )
      ),

      # Settings tab
      nav_panel(
        title = i18n$t("Settings"),
        value = "settings",
        icon = icon("cog"),

        div(
          class = "container-fluid mt-3",
          h3(i18n$t("Settings")),
          p(i18n$t("Content coming in Prompt 17"))
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
