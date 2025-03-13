formatSummary <- function(input, output, session, values) {
  output$formatSummary <- renderTable({
    summary <- data.frame(matrix(ncol = 4, nrow = 0))
    for (column in values$firstSelectedDataset()@format@columnList) {
      if (column@dataType == "Unused" & input$hideUnusedColumns) {
        next
      }
      summary <- rbind(summary, c(column@header, column@dataType, column@extension, column@units))
    }
    colnames(summary) <- c("Column Header", "Data Type", "Extension", "Units")
    summary
  }, striped=TRUE)
  
  observeEvent(input$summaryGoToDataCheck, {
    updateTabsetPanel(session, "format", "Data Check")
  })
  
  output$saveFormat <- downloadHandler(
    filename = function() {
      paste0(input$formatFilename, ".json")
    },
    content = function(file) {
      for (datasetIdx in values$selectedDatasets) {
        values$datasetList[[datasetIdx]]@format@sensorName <- input$formatSensorType
        values$datasetList[[datasetIdx]]@format@formatNotes <- input$formatDescription
      }
      output <- DatasetFormat.list(values$firstSelectedDataset()@format)
      write(jsonlite::toJSON(output, pretty = TRUE), file)
    }
  )
}
