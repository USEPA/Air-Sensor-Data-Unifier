locationConfig <- nav_panel(
  title = "Location Config",
  div(class="m-4",
    h1("Location Config"),
    conditionalPanel(
      condition = "!output.datasetSelected",
      div("Please select a dataset from the Dataset Dashboard.", class="alert alert-danger")
    ),
    conditionalPanel(
      condition = "output.datasetSelected",
      div(class="alert alert-light py-2", htmlOutput("selectedFilenamesLocationConfig")),
      p("If your data contains Sensor ID or Latitude/Longitude columns, make sure to set them in the Format Wizard > Columns tab."),
      conditionalPanel(
        condition = "!output.dataScanned",
        uiOutput("needsDataScanned")
      ),
      conditionalPanel(
        condition = "output.dataScanned",
        div(class="text-danger my-3 fw-bold", textOutput("locationError")),
        div(class="custom-table-form", DT::dataTableOutput("monitorLocations")),
        uiOutput("saveLocationButton"),
        conditionalPanel(
          condition = "output.allowExport",
          div("Your dataset is ready for data flagging or export. Please go to either the Data Flagging or Export Options pages to continue.", class="alert alert-success mt-4")
        )
      )
    )
  )
)
