flagging <- nav_panel(
  title = "Data Flagging",
  div(class="m-4",
    h1("Data Flagging"),
    conditionalPanel(
      condition = "!output.datasetSelected",
      div("Please select a dataset from the Dataset Dashboard.", class="alert alert-danger")
    ),
    conditionalPanel(
      condition = "output.datasetSelected",
      div(class="alert alert-light py-2", htmlOutput("selectedFilenamesFlagging")),
      conditionalPanel(
        condition = "!output.allowExport",
        uiOutput("notReadyForFlagging")
      ),
      conditionalPanel(
        condition = "output.allowExport",
        uiOutput("dataColumnSelect"),
        div(class="text-danger my-3 fw-bold", textOutput("flagError")),
        div(class="row pt-2",
          div(class="col-1",
            strong("Enable?")
          ),
          div(class="col-3",
            strong("Flag condition")
          ),
          div(class="col-4",
            strong("Action to take")
          ),
          div(class="col-4",
            strong("Replacement value (if applicable)")
          )
        ),
        div(class="row pt-2 bg-light",
          div(class="col-1",
            disabled(
              checkboxInput("missingValueEnable", "1A", value=TRUE)
            )
          ),
          div(class="col-3",
            "Missing value"
          ),
          div(class="col-4",
            selectInput("missingValueAction", NULL, choices=c("Drop record", "Replace value"))
          ),
          div(class="col-4",
            "Replacement for missing value",
            numericInput("missingValueReplace", NULL, 0, width="100px")
          )
        ),
        div(class="row pt-2",
          div(class="col-1",
            checkboxInput("minimumValueEnable", "1B")
          ),
          div(class="col-3",
            "Below minimum value",
            numericInput("minimumValue", NULL, 0, width="100px")
          ),
          div(class="col-4",
            selectInput("minimumValueAction", NULL, choices=c("Drop record", "Replace value", "Report only"))
          ),
          div(class="col-4",
            "Replacement for low value",
            numericInput("minimumValueReplace", NULL, 0, width="100px")
          )
        ),
        div(class="row pt-2 bg-light",
          div(class="col-1",
            checkboxInput("maximumValueEnable", "1C")
          ),
          div(class="col-3",
            "Above maximum value",
            numericInput("maximumValue", NULL, 999, width="100px")
          ),
          div(class="col-4",
            selectInput("maximumValueAction", NULL, choices=c("Drop record", "Replace value", "Report only")),
          ),
          div(class="col-4",
            "Replacement for high value",
            numericInput("maximumValueReplace", NULL, 0, width="100px")
          )
        ),
        div(class="row pt-2",
          div(class="col-1",
            checkboxInput("repeatValueEnable", "1D")
          ),
          div(class="col-3",
            "Value repeats X times or more",
            numericInput("repeatValue", NULL, 3, width="100px")
          ),
          div(class="col-8",
            selectInput("repeatValueAction", NULL, choices=c("Drop record", "Report only"))
          )
        ),
        div(class="row pt-2 bg-light",
          div(class="col-1",
            checkboxInput("outlierValueEnable", "1E")
          ),
          div(class="col-3",
            "Value is X standard deviations away from the mean",
            numericInput("outlierValue", NULL, 3, width="100px")
          ),
          div(class="col-8",
            selectInput("outlierValueAction", NULL, choices=c("Drop record", "Report only"))
          )
        ),
        actionButton("applyFlags", "Apply Flags", class="btn-primary my-4"),
        actionButton("resetFlags", "Reset Flags to Default", class="btn-danger my-4 mx-2"),
        uiOutput("flaggingSummary"),
        DT::dataTableOutput("flaggedDataTable"),
        uiOutput("saveFlaggedDataOptions")
      )
    )
  )
)
