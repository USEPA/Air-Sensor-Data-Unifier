exportOptions <- function(input, output, session, values) {
  output$selectedFilenamesExportOptions <- renderText({
    displaySelectedFilenames(values$datasetList[values$selectedDatasets])
  })
  
  output$allowExport <- reactive({
    for (dataset in values$datasetList[values$selectedDatasets]) {
      if (!Dataset.isReadyForExport(dataset)) {
        return(FALSE)
      }
    }
    TRUE
  })
  outputOptions(output, "allowExport", suspendWhenHidden = FALSE)
  
  output$notReadyForExport <- renderUI({
    needsFormat <- FALSE
    for (dataset in values$datasetList[values$selectedDatasets]) {
      if (dataset@status == Dataset.status.Uploaded) {
        needsFormat <- TRUE
        break
      }
    }
    
    if (needsFormat) {
      tagList(
        div("Please finish setting up your dataset's format using the Format Wizard.", class="alert alert-danger"),
        actionButton("exportGoToFormatWizard", "Go to Format Wizard", class="btn-primary")
      )
    } else {
      tagList(
        div("Please use the Location Config page to set up locations for your sensor data.", class="alert alert-danger"),
        actionButton("exportGoToLocationConfig", "Go to Location Config", class="btn-primary")
      )
    }
  })
  
  observeEvent(input$exportGoToFormatWizard, {
    updateNavbarPage(session, "main", "Format Wizard")
    updateTabsetPanel(session, "format", "Known Sensor Types")
  })
  
  observeEvent(input$exportGoToLocationConfig, {
    updateNavbarPage(session, "main", "Location Config")
  })
  
  output$exportError <- renderText({
    values$exportData$error
  })
  
  observeEvent(input$exportTimePeriod, {
    values$exportData$canDownload <- NULL
  })
  
  output$dataFlaggingStatus <- renderText({
    if (is.null(values$flaggingData$flags) ||
        Flag.isDefaults(values$flaggingData$flags)) {
      "Data flagging: Using default data flagging"
    } else {
      "Data flagging: Using custom data flagging"
    }
  })
  
  observeEvent(input$exportGoToDataFlagging, {
    updateNavbarPage(session, "main", "Data Flagging")
  })
  
  flagsForExport <- function() {
    if (is.null(values$flaggingData$flags)) {
      values$flaggingData$flags <- Flag.buildDefaults(values$firstSelectedDataset()@format)
    }
    values$flaggingData$flags
  }
  
  downloadFilename <- function() {
    name <- input$exportFilename
    if (name == "") {
      name <- "export"
    }
    extension <- "tsv"
    if (input$exportFormat == "KML") {
      extension <- "kml"
    } else if (input$exportFormat == "RETIGO") {
      extension <- "csv"
    }
    paste0(name, ".", extension)
  }
  
  observeEvent(input$generateExport, {
    values$exportData$canDownload <- NULL
  
    selectedDatasets <- values$datasetList[values$selectedDatasets]
    scanConfig <- Dataset.buildScanConfig(values$firstSelectedDataset())
    exportData <- buildExportData(selectedDatasets, scanConfig, input$exportTimePeriod, flagsForExport())
    if (!is.null(exportData$error)) {
      values$exportData$error <- exportData$error
      return(NULL)
    }
    values$exportData$data <- exportData
    
    logText <- paste0("Export date: ", Sys.time(), "\n")
    logText <- paste0(logText, "Input files: ")
    for (dataset in values$datasetList[values$selectedDatasets]) {
      for (displayFile in dataset@displayFiles) {
        logText <- paste0(logText, displayFile, "\n")
      }
    }
    logText <- paste0(logText, "Output file: ", downloadFilename(), "\n")
    logText <- paste0(logText, "Export format: ", input$exportFormat, "\n")
    logText <- paste0(logText, "Export timestamp: ", input$exportTimePeriod, "\n")
    logText <- paste0(logText, "Data flags:\n", Flag.logReport(flagsForExport()))
    logText <- paste0(logText, "Notes: ", input$exportDescription, "\n")
    values$exportData$log <- logText
    
    values$exportData$canDownload <- TRUE
  })
  
  output$downloadButtons <- renderUI({
    if (is.null(values$exportData$canDownload)) {
      return(NULL)
    }
    tagList(
      div(class="mt-4",
        downloadButton("doExport", "Export Sensor Data", class="btn-primary"),
        downloadButton("downloadLog", "Download Log File", class="btn-secondary")
      )
    )
  })
  
  output$doExport <- downloadHandler(
    filename = function() {
      downloadFilename()
    },
    content = function(file) {
      exportData <- values$exportData$data
      if (input$exportFormat == "KML") {
        writeLines(writeKML(exportData), file)
      } else if (input$exportFormat == "RETIGO") {
        write.table(convertExportToRETIGO(exportData), file, row.names=FALSE, quote=FALSE, sep=",")
      } else {
        if (input$exportTimePeriod == "Raw") {
          write.table(exportData, file, row.names=FALSE, quote=FALSE, sep="\t")
        } else {
          # output with 6 significant digits for data columns
          formattedData <- exportData[,1:4]
          formattedData[,5:ncol(exportData)] <- format(exportData[,5:ncol(exportData)], digits=6)
          write.table(formattedData, file, row.names=FALSE, quote=FALSE, sep="\t")
        }
      }
    }
  )
  
  output$downloadLog <- downloadHandler(
    filename = function() {
      name <- input$exportFilename
      if (name == "") {
        name <- "export"
      }
      paste0(name, "_log.txt")
    },
    content = function(file) {
      writeLines(values$exportData$log, file)
    }
  )
}
