exportOptions <- nav_panel(
  title = "Export Options",
  div(class="m-4",
    h1("Export Options"),
    conditionalPanel(
      condition = "!output.datasetSelected",
      div("Please select a dataset from the Dataset Dashboard.", class="alert alert-danger")
    ),
    conditionalPanel(
      condition = "output.datasetSelected",
      div(class="alert alert-light py-2", htmlOutput("selectedFilenamesExportOptions")),
      conditionalPanel(
        condition = "!output.allowExport",
        uiOutput("notReadyForExport")
      ),
      conditionalPanel(
        condition = "output.allowExport",
        div(class="text-danger my-3 fw-bold", textOutput("exportError")),
        selectInput("exportFormat", "Export format", c("ASNAT Standard Format File", "KML", "RETIGO", "Colorado AQDE")),
        selectInput("exportTimePeriod", "Export timestamp", c("Raw", "Hourly", "Daily")),
        #checkboxInput("exportBySensor", "Export each sensor in a separate file"),
        #checkboxInput("exportByDay", "Export each day in a separate file"),
        textOutput("dataFlaggingStatus"),
        actionButton("exportGoToDataFlagging", "Go to Data Flagging", class="btn-secondary mb-4"),
        textAreaInput("exportDescription", "Notes about this data (will be written to the log file)", width="500px"),
        textInput("exportFilename", "Filename", width="500px"),
        #p("Indicate how sensor and/or day would be appended to file", style="color: purple"),
        #fileInput("exportLocation", "Select a directory where the exported data will be written"),
        actionButton("generateExport", "Generate Export Data", class="btn-primary mt-4"),
        uiOutput("downloadButtons")
      )
    )
  )
)
