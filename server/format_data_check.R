formatDataCheck <- function(input, output, session, values) {
  output$dataScanned <- reactive({
    for (dataset in values$datasetList[values$selectedDatasets]) {
      if (!(dataset@status %in% c(Dataset.status.Scanned, Dataset.status.LocationsSet))) {
        return(FALSE)
      }
    }
    TRUE
  })
  outputOptions(output, "dataScanned", suspendWhenHidden = FALSE)
  
  output$scanError <- renderText({
    values$scanError
  })
  
  observeEvent(input$scanData, {
    values$scanError <- ""
  
    scanConfig <- Dataset.buildScanConfig(values$firstSelectedDataset())
  
    for (datasetIdx in values$selectedDatasets) {
      scanResults <- scanDataset(values$datasetList[[datasetIdx]], scanConfig)
      if (!is.null(scanResults$error)) {
        values$scanError <- scanResults$error
        break
      }
      
      values$datasetList[[datasetIdx]]@startDate <- scanResults$startDate
      values$datasetList[[datasetIdx]]@endDate <- scanResults$endDate
      values$datasetList[[datasetIdx]]@monitors <- scanResults$monitors
      
      values$datasetList[[datasetIdx]]@status <- Dataset.status.Scanned
    }
  })
  
  output$startDate <- renderText({
    startDate <- NULL
    for (datasetIdx in values$selectedDatasets) {
      if (is.null(startDate) || values$datasetList[[datasetIdx]]@startDate < startDate) {
        startDate <- values$datasetList[[datasetIdx]]@startDate
      }
    }
    format(startDate, format="%B %d, %Y %I:%M %p %z")
  })
  
  output$endDate <- renderText({
    endDate <- NULL
    for (datasetIdx in values$selectedDatasets) {
      if (is.null(endDate) || values$datasetList[[datasetIdx]]@endDate > endDate) {
        endDate <- values$datasetList[[datasetIdx]]@endDate
      }
    }
    format(endDate, format="%B %d, %Y %I:%M %p %z")
  })
  
  observeEvent(input$dataCheckGoToLocationConfig, {
    updateNavbarPage(session, "main", "Location Config")
  })
  
  output$dataCheck <- renderPlot({
    dataset <- values$firstSelectedDataset()
    for (columnIdx in obsColumns(DatasetFormat.columnDataTypes(dataset@format))) {
      # check if column has any observations
      if (all(is.na(dataset@parsedData[,columnIdx]))) {
        next
      }
      dataType <- dataset@format@columnList[[columnIdx]]@dataType
      units <- dataset@format@columnList[[columnIdx]]@units
      ylabel <- paste0(dataType, " (", units, ")")
      plot(seq_along(dataset@parsedData[,columnIdx]), dataset@parsedData[,columnIdx], ylab=ylabel, xlab="Observation #")
      break
    }
  })
}
