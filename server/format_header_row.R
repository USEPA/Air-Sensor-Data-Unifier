formatHeaderRow <- function(input, output, session, values) {
  output$headerRowError <- renderText({
    values$headerRowError
  })
  
  output$headerRowContent <- renderTable({
    firstDataset <- values$firstSelectedDataset()
    endLine <- min(values$startLine + 9, length(firstDataset@rawData))
    sample <- data.frame(seq(values$startLine, endLine), firstDataset@rawData[values$startLine:endLine])
    colnames(sample) <- c("Line #", paste("Lines", values$startLine, "through", endLine, "of the file"))
    sample
  }, striped=TRUE)
  
  output$showPrevButton <- reactive({
    values$startLine != 1
  })
  outputOptions(output, "showPrevButton", suspendWhenHidden = FALSE)
  
  output$showNextButton <- reactive({
    firstDataset <- values$firstSelectedDataset()
    if (is.null(firstDataset)) {
      return(FALSE)
    }
    (values$startLine + 10) <= length(firstDataset@rawData)
  })
  outputOptions(output, "showNextButton", suspendWhenHidden = FALSE)
  
  observeEvent(input$showPrevLines, {
    values$startLine <- values$startLine - 10
  })
  
  observeEvent(input$showNextLines, {
    values$startLine <- values$startLine + 10
  })

  observeEvent(input$headerRowDone, {
    values$headerRowError <- ""
    
    # validate the header row setting
    if (class(input$headerRowIdx) != "integer") {
      values$headerRowError <- "ERROR: The header row value must be an integer."
      return(NULL)
    }
    
    max <- length(values$firstSelectedDataset()@rawData) - 1
    if (input$headerRowIdx < 0 || input$headerRowIdx > max) {
      values$headerRowError <- paste0("ERROR: The header row value must be between 0 and ", max, ".")
      return(NULL)
    }
    
    for (datasetIdx in values$selectedDatasets) {
      values$datasetList[[datasetIdx]]@format@headerRowIdx <- input$headerRowIdx
      values$datasetList[[datasetIdx]]@format@delimiter <- input$columnDelimiter
      values$datasetList[[datasetIdx]]@status <- Dataset.status.Uploaded
    }
    
    savedData <- NULL
    for (datasetIdx in values$selectedDatasets) {
      first <- TRUE
      for (rawFile in values$datasetList[[datasetIdx]]@rawFiles) {
        parsedData <- parseFile(rawFile, input$columnDelimiter, input$headerRowIdx, 10)
        if (first) {
          values$datasetList[[datasetIdx]]@parsedData <- parsedData
          first <- FALSE
        }
        if (is.null(savedData)) {
          savedData <- parsedData
        } else {
          if (length(colnames(parsedData)) != length(colnames(savedData))) {
            values$headerRowError <- "ERROR: The number of columns is not the same in all the uploaded files."
            return(NULL)
          }
          if (!identical(colnames(parsedData), colnames(savedData))) {
            values$headerRowError <- "ERROR: The list of columns is not the same in all the uploaded files."
            return(NULL)
          }
        }
      }
    }
    
    values$resetErrorsAndData()
    
    js$enableTab("Columns")
    
    # disable Timestamps, Summary, and Data Check tabs since columns need to be configured
    js$disableTab("Timestamps")
    js$disableTab("Summary")
    js$disableTab("Data Check")
    
    updateTabsetPanel(session, "format", "Columns")
  })
}
