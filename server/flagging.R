flagging <- function(input, output, session, values) {
  output$selectedFilenamesFlagging <- renderText({
    displaySelectedFilenames(values$datasetList[values$selectedDatasets])
  })
  
  output$notReadyForFlagging <- renderUI({
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
        actionButton("flaggingGoToFormatWizard", "Go to Format Wizard", class="btn-primary")
      )
    } else {
      tagList(
        div("Please use the Location Config page to set up locations for your sensor data.", class="alert alert-danger"),
        actionButton("flaggingGoToLocationConfig", "Go to Location Config", class="btn-primary")
      )
    }
  })
  
  observeEvent(input$flaggingGoToFormatWizard, {
    updateNavbarPage(session, "main", "Format Wizard")
    updateTabsetPanel(session, "format", "Known Sensor Types")
  })
  
  observeEvent(input$flaggingGoToLocationConfig, {
    updateNavbarPage(session, "main", "Location Config")
  })

  output$flagError <- renderText({
    values$flaggingData$error
  })
  
  output$dataColumnSelect <- renderUI({
    # flag is reset when selected dataset changes or the dataset format changes
    values$flagInit
    
    isolate({
      if (values$flagInit) {
        firstDataset <- values$firstSelectedDataset()
        colNames <- Flag.columnNames(firstDataset@format)
        values$flaggingData$columns <- colNames
        values$flaggingData$selectedColumn <- colNames[1]
        values$flaggingData$flags <- Flag.buildDefaults(firstDataset@format)
        loadFlagsIntoUI(values$flaggingData$flags[[1]])
        values$flagInit <- FALSE
      } else {
        colNames <- values$flaggingData$columns
      }
      selectInput("dataColumnToFlag", "Flags for Data Column", choices=colNames)
    })
  })
  
  loadFlagsIntoUI <- function(flags) {
    for (flag in flags) {
      elementId <- paste0(flag@type, "Enable")
      updateCheckboxInput(session, elementId, label=flag@label, value=flag@enabled)
      
      if (flag@type != Flag.type.MissingValue) {
        elementId <- flag@type
        updateNumericInput(session, elementId, value=flag@testValue)
      }
      
      elementId <- paste0(flag@type, "Action")
      updateSelectInput(session, elementId, selected=flag@action)
      
      if (flag@type %in% c(Flag.type.MinimumValue, Flag.type.MaximumValue)) {
        elementId <- paste0(flag@type, "Replace")
        updateNumericInput(session, elementId, value=flag@replacementValue)
      }
    }
  }
  
  validateFlags <- function() {
    values$flaggingData$error <- ""
    
    colIdx <- match(values$flaggingData$selectedColumn, values$flaggingData$columns)
    
    replaceVal <- input$missingValueReplace
    if (!is.numeric(replaceVal)) {
      if (input$missingValueAction == Flag.action.ReplaceValue) {
        values$flaggingData$error <- "ERROR: The replacement value for missing values must be a number."
        return(NULL)
      } else {
        replaceVal <- 0
        updateNumericInput(session, "missingValueReplace", value=replaceVal)
      }
    }
    missingValueFlag <-
      new("Flag", type=Flag.type.MissingValue,
          label=paste0(colIdx, "A"),
          enabled=TRUE,
          action=input$missingValueAction,
          replacementValue=replaceVal)
    
    testVal <- input$minimumValue
    if (!is.numeric(testVal)) {
      if (input$minimumValueEnable) {
        values$flaggingData$error <- "ERROR: The minimum value must be a number."
        return(NULL)
      } else {
        testVal <- 0
        updateNumericInput(session, "minimumValue", value=testVal)
      }
    }
    
    replaceVal <- input$minimumValueReplace
    if (!is.numeric(replaceVal)) {
      if (input$minimumValueEnable &&
          input$minimumValueAction == Flag.action.ReplaceValue) {
        values$flaggingData$error <- "ERROR: The replacement value for low values must be a number."
        return(NULL)
      } else {
        replaceVal <- 0
        updateNumericInput(session, "minimumValueReplace", value=replaceVal)
      }
    }
    minimumValueFlag <-
      new("Flag", type=Flag.type.MinimumValue,
          label=paste0(colIdx, "B"),
          enabled=input$minimumValueEnable,
          testValue=testVal,
          action=input$minimumValueAction,
          replacementValue=replaceVal)
    
    testVal <- input$maximumValue
    if (!is.numeric(testVal)) {
      if (input$maximumValueEnable) {
        values$flaggingData$error <- "ERROR: The maximum value must be a number."
        return(NULL)
      } else {
        testVal <- 999
        updateNumericInput(session, "maximumValue", value=testVal)
      }
    }
    
    replaceVal <- input$maximumValueReplace
    if (!is.numeric(replaceVal)) {
      if (input$maximumValueEnable &&
          input$maximumValueAction == Flag.action.ReplaceValue) {
        values$flaggingData$error <- "ERROR: The replacement value for high values must be a number."
        return(NULL)
      } else {
        replaceVal <- 0
        updateNumericInput(session, "maximumValueReplace", value=replaceVal)
      }
    }
    maximumValueFlag <-
      new("Flag", type=Flag.type.MaximumValue,
          label=paste0(colIdx, "C"),
          enabled=input$maximumValueEnable,
          testValue=testVal,
          action=input$maximumValueAction,
          replacementValue=replaceVal)
    
    testVal <- input$repeatValue
    if (class(testVal) != "integer") {
      if (input$repeatValueEnable) {
        values$flaggingData$error <- "ERROR: The number of times a value repeats must be an integer."
        return(NULL)
      } else {
        testVal <- 3
        updateNumericInput(session, "repeatValue", value=testVal)
      }
    }
    if (input$repeatValueEnable && testVal < 2) {
      values$flaggingData$error <- "ERROR: The number of times a value repeats must be greater than one."
      return(NULL)
    }
    repeatValueFlag <-
      new("Flag", type=Flag.type.RepeatValue,
          label=paste0(colIdx, "D"),
          enabled=input$repeatValueEnable,
          testValue=testVal,
          action=input$repeatValueAction)
    
    testVal <- input$outlierValue
    if (class(testVal) != "integer") {
      if (input$outlierValueEnable) {
        values$flaggingData$error <- "ERROR: The number of standard deviations for an outlier value must be an integer."
        return(NULL)
      } else {
        testVal <- 3
        updateNumericInput(session, "outlierValue", value=testVal)
      }
    }
    if (input$outlierValueEnable && testVal < 1) {
      values$flaggingData$error <- "ERROR: The number of standard deviations for an outlier value must be greater than zero."
      return(NULL)
    }
    outlierValueFlag <-
      new("Flag", type=Flag.type.OutlierValue,
          label=paste0(colIdx, "E"),
          enabled=input$outlierValueEnable,
          testValue=testVal,
          action=input$outlierValueAction)
    
    list(missingValueFlag, minimumValueFlag, maximumValueFlag, repeatValueFlag, outlierValueFlag)
  }
  
  observeEvent(input$dataColumnToFlag, {
    # ignore triggers when column hasn't actually changed (happens when first
    # setting up the select input and when after a validation error)
    if (input$dataColumnToFlag == values$flaggingData$selectedColumn) {
      return(NULL)
    }
    
    flags <- validateFlags()
    if (values$flaggingData$error != "") {
      updateSelectInput(session, "dataColumnToFlag", selected=values$flaggingData$selectedColumn)
      return(NULL)
    }
    values$flaggingData$flags[[values$flaggingData$selectedColumn]] <- flags
    
    # load flags for selected column
    values$flaggingData$selectedColumn <- input$dataColumnToFlag
    loadFlagsIntoUI(values$flaggingData$flags[[values$flaggingData$selectedColumn]])
  })
  
  observeEvent(input$applyFlags, {
    values$flaggingData$flaggedData <- NULL
    values$flaggingData$summary <- NULL
  
    flags <- validateFlags()
    if (values$flaggingData$error != "") {
      return(NULL)
    }
    values$flaggingData$flags[[values$flaggingData$selectedColumn]] <- flags
    
    selectedDatasets <- values$datasetList[values$selectedDatasets]
    scanConfig <- Dataset.buildScanConfig(values$firstSelectedDataset())
    loadResults <- loadFullData(selectedDatasets, scanConfig)
    if (!is.null(loadResults$error)) {
      values$flaggingData$error <- loadResults$error
      return(NULL)
    }
    
    flagResults <- Flag.applyToData(values$flaggingData$flags, loadResults$fullData)
    values$flaggingData$summary <- flagResults$summary
    
    exportData <- createExportData(flagResults$data, NULL, loadResults$dataColumns)
    values$flaggingData$flaggedData <- cbind(flagResults$data$flags, exportData)
    colnames(values$flaggingData$flaggedData) <- c("flags", colnames(exportData))
  })
  
  output$flaggingSummary <- renderUI({
    if (is.null(values$flaggingData$summary)) {
      return(NULL)
    }
    summary <- values$flaggingData$summary
    tagList(
      h4("Data Flagging Summary"),
      div(paste(summary$recordsFlagged, " out of ", summary$totalRecords, " records flagged")),
      div(paste(summary$recordsDropped, " out of ", summary$totalRecords, " records dropped")),
      div(paste(summary$recordsReplaced, " out of ", summary$totalRecords, " records with replacement values"), class="mb-4")
    )
  })
  
  output$flaggedDataTable <- DT::renderDataTable({
    if (is.null(values$flaggingData$flaggedData)) {
      return(NULL)
    }
    DT::datatable(
      values$flaggingData$flaggedData,
      rownames=FALSE
    )
  })
  
  observeEvent(input$resetFlags, {
    showModal(modalDialog(
      title = "Confirm reset",
      "Are you sure you want to reset the flags to default?",
      footer = tagList(actionButton("confirmReset", "Reset", class="btn-danger"),
                       modalButton("Cancel"))
    ))
  })
  
  observeEvent(input$confirmReset, {
    # reset flags
    values$flaggingData$flags <- Flag.buildDefaults(values$firstSelectedDataset()@format)
    
    # reset UI
    firstColumn <- names(values$flaggingData$flags)[[1]]
    values$flaggingData$selectedColumn <- firstColumn
    loadFlagsIntoUI(values$flaggingData$flags[[1]])
    updateSelectInput(session, "dataColumnToFlag", selected=firstColumn)
    
    # clear flagging results
    values$flaggingData$flaggedData <- NULL
    values$flaggingData$summary <- NULL
    
    removeModal()
  })
  
  output$saveFlaggedDataOptions <- renderUI({
    if (is.null(values$flaggingData$flaggedData)) {
      return(NULL)
    }
    tagList(
      textInput("flaggedFilename", "Flagged Data Filename", width="500px"),
      textOutput("fullFilename"),
      downloadButton("saveFlaggedData", "Download Flagged Data", class="btn-secondary")
    )
  })
  
  output$fullFilename <- renderText({
    paste0("Full name: ", input$flaggedFilename, "_flagged.csv")
  })
  
  output$saveFlaggedData <- downloadHandler(
    filename = function() {
      paste0(input$flaggedFilename, "_flagged.csv")
    },
    content = function(file) {
      saveData <- values$flaggingData$flaggedData
      saveData[["timestamp(UTC)"]] <- paste0(format(saveData[["timestamp(UTC)"]], "%Y-%m-%dT%H:%M:%S"), "-0000")
      write.table(saveData, file, row.names=FALSE, quote=FALSE, sep=",")
    }
  )
}
