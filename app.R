if (!require("shiny"))
  install.packages("shiny", repos = "http://cran.us.r-project.org")
if (!require("shinyjs"))
  install.packages("shinyjs", repos = "http://cran.us.r-project.org")
if (!require("bslib"))
  install.packages("bslib", repos = "http://cran.us.r-project.org")
if (!require("DT"))
  install.packages("DT", repos = "http://cran.us.r-project.org")

options(shiny.port = 7775)
# allow files up to 100 MB to be uploaded
options(shiny.maxRequestSize = 100*1024^2)

# class definitions
source("dataset_format.R")
source("dataset.R")
source("flag.R")

# utility functions
source("utils/utils.R")
source("utils/timestamp_utils.R")
source("utils/scan_export_utils.R")

# ui
source("ui/dataset_dashboard.R", local=TRUE)
source("ui/format_wizard.R", local=TRUE)
source("ui/location_config.R", local=TRUE)
source("ui/flagging.R", local=TRUE)
source("ui/export.R", local=TRUE)
source("ui/help.R", local=TRUE)
source("ui/tab_disable.R", local=TRUE)

ui <- tagList(
  tags$head(
    tags$style(HTML("
      h1 { margin-bottom: 1.2rem }
      h2 { margin-top: 2rem; margin-bottom: 1rem }
      .custom-table-form .form-group { margin-bottom: 0 }
      .help-page h2 { margin-top: 0 }
      .help-page .tab-content { padding-left: 1.5rem; padding-right: 1.5rem }
    "))
  ),
  useShinyjs(),
  extendShinyjs(text=tabDisableJscode, functions=c("disableTab", "enableTab")),
  inlineCSS(tabDisableCss),
  page_navbar(
    theme = bs_theme(preset="bootstrap"),
    bg = "rgb(248, 249, 250)",
    id = "main",
    title = "Air Sensor Data Unifier",
    datasetDashboard,
    formatWizard,
    locationConfig,
    flagging,
    exportOptions,
    nav_spacer(),
    help,
    fillable=FALSE
  )
)

# server
source("server/main.R", local=TRUE)

shinyApp(ui, server)
