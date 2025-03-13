datasetDashboard <- function(input, output, session, values) {
  datasetId <- reactiveVal(0)
  
  uploadDatasetError <- reactiveVal("")
  output$uploadDatasetError <- renderText({
    uploadDatasetError()
  })
  
  selectDatasetError <- reactiveVal("")
  output$selectDatasetError <- renderText({
    selectDatasetError()
  })
  
  clearErrors <- function() {
    isolate({
      uploadDatasetError("")
      selectDatasetError("")
    })
  }
  
  # dataset upload
  observeEvent(input$fileUpload, {
    clearErrors()
    
    # check that all files have the same type
    if (length(input$fileUpload) > 1 && length(unique(input$fileUpload$type)) != 1) {
      uploadDatasetError("ERROR: Files uploaded together must be of the same type.")
    } else {
      newDatasetId <- datasetId() + 1
      datasetId(newDatasetId)
      
      newDataset <- Dataset.new(newDatasetId, input$fileUpload$datapath, input$fileUpload$name)
      # check for empty file
      if (length(newDataset@rawData) == 0) {
        uploadDatasetError("ERROR: The uploaded file is empty.")
        return(NULL)
      }
      values$datasetList <- c(values$datasetList, newDataset)
    }
  })
  
  output$dataUploaded <- reactive({
    length(values$datasetList) > 0
  })
  outputOptions(output, "dataUploaded", suspendWhenHidden = FALSE)
  
  output$datasetTable <- DT::renderDataTable({
    tableData <- data.frame(matrix(ncol = 4, nrow = 0))
    for (dataset in values$datasetList) {
      tableData <- rbind(tableData, c(
        dataset@id,
        dataset@format@sensorName,
        Dataset.displayFiles(dataset),
        dataset@status
      ))
    }
    colnames(tableData) <- c("Batch", "Sensor Type", "File Names", "Status")
    DT::datatable(
      tableData,
      options=list(
        dom="t",
        ordering=FALSE,
        pageLength=nrow(tableData)
      ),
      rownames=FALSE,
      escape=FALSE
    )
  })
  
  observeEvent(input$doFormat, {
    clearErrors()
    
    if (length(input$datasetTable_rows_selected) == 0) {
      selectDatasetError("ERROR: Please select one or more datasets to set the format for.")
      return(NULL)
    }
    
    values$selectedDatasets <- input$datasetTable_rows_selected
    values$startLine <- 1
    
    # if multiple batches are selected, check for consistent file extension
    if (length(values$selectedDatasets) > 1) {
      fileExt <- values$firstSelectedDataset()@format@fileExtension
      for (dataset in values$datasetList[values$selectedDatasets]) {
        tmpExt <- dataset@format@fileExtension
        if (tmpExt != fileExt) {
          selectDatasetError("ERROR: The selected batches must contain files of the same type.")
          values$selectedDatasets <- c()
          return(NULL)
        }
        
        # TODO: if datasets are past Uploaded stage, check for consistency
      }
    }
    
    # update UI elements based on selected dataset
    firstDataset <- values$firstSelectedDataset()
    updateNumericInput(session, "headerRowIdx", value=firstDataset@format@headerRowIdx)
    updateSelectInput(session, "columnDelimiter", selected=firstDataset@format@delimiter)
    if (firstDataset@format@timezone %in% c("in_timestamp", "sensor_specific")) {
      updateRadioButtons(session, "timeZoneOptions", selected=firstDataset@format@timezone)
      updateSelectInput(session, "timeZone", selected="UTC")
    } else {
      updateRadioButtons(session, "timeZoneOptions", selected="use_one_timezone")
      updateSelectInput(session, "timeZone", selected=firstDataset@format@timezone)
    }
    updateTextInput(session, "formatSensorType", value=firstDataset@format@sensorName)
    updateTextInput(session, "formatDescription", value=firstDataset@format@formatNotes)
    updateTextInput(session, "formatFilename", value="")
    
    updateNavbarPage(session, "main", "Format Wizard")
    updateTabsetPanel(session, "format", "Known Sensor Types")
    
    values$resetErrorsAndData()
    
    if (firstDataset@status == Dataset.status.Uploaded) {
      js$disableTab("Columns")
      js$disableTab("Timestamps")
      js$disableTab("Summary")
      js$disableTab("Data Check")
    }
  })
  
  observeEvent(input$doRemove, {
    clearErrors()
    
    if (length(input$datasetTable_rows_selected) == 0) {
      selectDatasetError("ERROR: Please select one or more datasets to remove.")
      return(NULL)
    }
    
    showModal(modalDialog(
      title = "Confirm removal",
      "Are you sure you want to remove the selected datasets?",
      footer = tagList(actionButton("confirmRemove", "Remove", class="btn-danger"),
                       modalButton("Cancel"))
    ))
  })
  
  observeEvent(input$confirmRemove, {
    # reset list of app's selected datasets
    values$selectedDatasets <- c()
    # remove user-selected datasets from master list
    values$datasetList[input$datasetTable_rows_selected] <- NULL
    
    removeModal()
  })
  
  output$datasetSelected <- reactive({
    length(values$selectedDatasets > 0)
  })
  outputOptions(output, "datasetSelected", suspendWhenHidden = FALSE)
}
