datasetDashboard <- nav_panel(
  title = "Dataset Dashboard",
  div(class="m-4",
    h1("Dataset Dashboard"),
    h2("Upload Datasets"),
    div(class="row gx-5",
      div(
        class="col-auto",
        fileInput("fileUpload", "Sensor data files", multiple=TRUE, accept=c(".csv", ".tsv", ".txt"), width="400px")
      ),
      div(
        class="col",
        div(class="alert alert-info", "Please upload sensor files in .csv, .tsv, and .txt formats. Files that are uploaded together should be of the same format.")
      )
    ),
    div(class="text-danger mb-3 fw-bold", textOutput("uploadDatasetError")),
    conditionalPanel(
      condition = "output.dataUploaded",
      h2("Loaded Datasets"),
      div("Click on one or more rows to select datasets."),
      DT::dataTableOutput("datasetTable"),
      actionButton("doFormat", "Set Format", class="btn-primary mt-4"),
      actionButton("doRemove", "Remove", class="btn-danger mt-4 mx-2"),
      div(class="text-danger my-3 fw-bold", textOutput("selectDatasetError"))
    )
  )
)
