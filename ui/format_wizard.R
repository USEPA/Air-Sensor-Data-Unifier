formatWizard <- nav_panel(
  title = "Format Wizard",
  div(class="m-4",
    h1("Format Wizard"),
    conditionalPanel(
      condition = "!output.datasetSelected",
      div("Please select a dataset from the Dataset Dashboard.", class="alert alert-danger")
    ),
    conditionalPanel(
      condition = "output.datasetSelected",
      div(class="alert alert-light py-2", htmlOutput("selectedFilenamesFormatWizard")),
      tabsetPanel(id = "format",
        tabPanel("Known Sensor Types",
          div(class="my-4",
            div(class="row gx-5",
              div(
                class="col-auto",
                fileInput("loadFormat", "Format information file", accept=c(".json"), width="400px")
              ),
              div(
                class="col",
                div(class="alert alert-info", "Load the sensor format information if files of this type have been processed before.​ Otherwise, click on the ", strong("Header Row"), " tab to continue.")
              )
            ),
            div(class="text-danger my-3 fw-bold", htmlOutput("uploadFormatError")),
            actionButton("knownSensorGoToHeaderRow", "Go to Header Row", class="btn-primary my-4")
          )
        ),
        tabPanel("Header Row",
          div(class="my-4",
            tableOutput("headerRowContent"),
            conditionalPanel(
              condition = "output.showPrevButton",
              actionButton("showPrevLines", "Previous 10 Lines", icon=icon("chevron-left"), class="btn-info my-4")
            ),
            conditionalPanel(
              condition = "output.showNextButton",
              actionButton("showNextLines", "Next 10 Lines", icon=icon("chevron-right"), class="btn-info my-4")
            ),
            div(class="alert alert-info", "If needed, update the ", strong("Header row"), " setting to indicate which row number contains the column headers. If your data doesn't have a header, set the ", strong("Header row"), " value to zero."),
            div(class="text-danger my-3 fw-bold", textOutput("headerRowError")),
            numericInput("headerRowIdx", "Header row", 1, min=0),
            #numericInput("dataRowIdx", "Starting data row", 2, min=1),
            selectInput("columnDelimiter", "Column delimiter", columnDelimiters, ","),
            actionButton("headerRowDone", "Next Step", class="btn-primary my-4")
          )
        ),
        tabPanel("Columns",
          div(class="my-4",
            div(class="text-danger my-3 fw-bold", htmlOutput("formatColumnsError")),
            div(class="custom-table-form", DT::dataTableOutput("columnNamesTable", fill=FALSE)),
            #p("Automatically adjust units options based on selected data type. May need to have a way to specify the output column names.", style="color: purple"),
            actionButton("columnsDone", "Next Step", class="btn-primary my-4")
          )
        ),
        tabPanel("Timestamps",
          div(class="my-4",
            tableOutput("sampleTimestamps"),
            h3("Detected Components"),
            div(class="text-danger my-3 fw-bold", textOutput("timestampsError")),
            div(class="custom-table-form", DT::dataTableOutput("timestampComponents", fill=FALSE)),
            #p(strong("Format:"), "%Y-%m-%dT%H:%M:%OS"),
            radioButtons("timeZoneOptions", "Time zone options",
                         choiceNames=c("Timestamp includes time zone", "Use one time zone for all data in files"),
                         choiceValues=c("in_timestamp", "use_one_timezone"),
                         width="100%"),
            conditionalPanel(
              condition = "input.timeZoneOptions == 'use_one_timezone'",
              selectInput("timeZone", "Time zone", timezones)
            ),
            uiOutput("timestampsDoneButton")
          )
        ),
        tabPanel("Summary",
          div(class="my-4",
            checkboxInput("hideUnusedColumns", "Hide unused columns"),
            tableOutput("formatSummary"),
            actionButton("summaryGoToDataCheck", "Go to Data Check", class="btn-primary my-4"),
            div(class="alert alert-info", "If you'd like to save your sensor format information for re-use, fill out the form below."),
            textInput("formatSensorType", "Sensor type"),
            textAreaInput("formatDescription", "Notes about this format", width="400px"),
            textInput("formatFilename", "Filename"),
            #fileInput("formatLocation", "Select a directory where the format information will be written"),
            downloadButton("saveFormat", "Save Format Information", class="btn-secondary my-4")
          )
        ),
        tabPanel("Data Check",
          div(class="my-4",
            conditionalPanel(
              condition = "output.dataScanned",
              actionButton("scanData", "Scan All Data", class="btn-primary mb-4", disabled=TRUE)
            ),
            conditionalPanel(
              condition = "!output.dataScanned",
              actionButton("scanData", "Scan All Data", class="btn-primary mb-4")
            ),
            div(class="text-danger mb-3 fw-bold", textOutput("scanError")),
            h4("Timestamp Range"),
            conditionalPanel(
              condition = "!output.dataScanned",
              p("Waiting for data scan...")
            ),
            conditionalPanel(
              condition = "output.dataScanned",
              p(textOutput("startDate"), " through ", textOutput("endDate")),
              conditionalPanel(
                condition = "!output.allowExport",
                div("Your dataset requires sensor locations to be entered. Please go to the Location Config page.", class="alert alert-warning"),
                actionButton("dataCheckGoToLocationConfig", "Go to Location Config", class="btn-primary mb-4"),
              ),
              conditionalPanel(
                condition = "output.allowExport",
                div("Your dataset is ready for data flagging or export. Please go to either the Data Flagging or Export Options pages to continue.", class="alert alert-success")
              )
            ),
            h4("Observation Data Values"),
            plotOutput("dataCheck", width = "600px"),
          )
        )
      )
    )
  )
)
