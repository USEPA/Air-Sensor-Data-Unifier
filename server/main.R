source("server/dataset_dashboard.R", local=TRUE)
source("server/format_wizard.R", local=TRUE)
source("server/location_config.R", local=TRUE)
source("server/flagging.R", local=TRUE)
source("server/export.R", local=TRUE)

server <- function(input, output, session) {
  # create session storage
  values <- reactiveValues()
  values$datasetList <- list()  # list of uploaded Datasets
  values$selectedDatasets <- c()  # indexes of selected Datasets
  
  values$firstSelectedDataset <- reactive({
    if (length(values$selectedDatasets) == 0 || length(values$datasetList) == 0) {
      return(NULL)
    }
    values$datasetList[[values$selectedDatasets[1]]]
  })
  
  values$resetErrorsAndData <- function() {
    values$uploadFormatError <- ""
    values$headerRowError <- ""
    values$formatColumnsError <- ""
    values$timestampsError <- ""
    values$scanError <- ""
    
    values$locationData <- list()
    values$flagInit <- TRUE
    values$flaggingData <- list()
    values$exportData <- list()
  }
  
  datasetDashboard(input, output, session, values)
  formatWizard(input, output, session, values)
  locationConfig(input, output, session, values)
  flagging(input, output, session, values)
  exportOptions(input, output, session, values)
}
