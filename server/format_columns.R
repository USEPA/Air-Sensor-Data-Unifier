formatColumns <- function(input, output, session, values) {
  output$formatColumnsError <- renderText({
    values$formatColumnsError
  })
  
  output$columnNamesTable <- DT::renderDataTable({
    firstDataset <- values$firstSelectedDataset()
    
    # table columns: Header, First Value, Data Type (dropdown), Extension (dropdown), Units (dropdown)
    columnTable <- data.frame(c1=colnames(firstDataset@parsedData), c2=t(firstDataset@parsedData[1,]))
    columnTable$c3 <- ""
    for (index in 1:nrow(columnTable)) {
      selectedDataType <- NULL
      selectedExtension <- NULL
      selectedUnit <- NULL
      
      if (length(firstDataset@format@columnList) >= index) {
        column <- firstDataset@format@columnList[[index]]
        selectedDataType <- column@dataType
        selectedExtension <- column@extension
        selectedUnit <- column@units
      }
      columnTable$c3[[index]] <- as.character(
        selectInput(
          inputId=paste0("row_select_type_", index),
          label=NULL,
          choices=names(columnTypes),
          selected=selectedDataType,
          width="150px"
        )
      )
      columnTable$c4[[index]] <- as.character(
        selectInput(
          inputId=paste0("row_select_ext_", index),
          label=NULL,
          choices=columnExtensions,
          selected=selectedExtension,
          width="100px"
        )
      )
      columnTable$c5[[index]] <- as.character(
        selectInput(
          inputId=paste0("row_select_unit_", index),
          label=NULL,
          choices=unitOptions,
          selected=selectedUnit,
          width="100px"
        )
      )
    }
    colnames(columnTable) <- c("Header", "First Value", "Data Type", "Extension", "Units")
    DT::datatable(
      columnTable,
      options=list(
        dom="t",
        ordering=FALSE,
        preDrawCallback=DT::JS("function() { Shiny.unbindAll(this.api().table().node()); }"),
        drawCallback=DT::JS("function() { Shiny.bindAll(this.api().table().node()); }"),
        pageLength=nrow(columnTable)
      ),
      rownames=FALSE,
      escape=FALSE,
      selection="none"
    )
  })
  
  observeEvent(input$columnsDone, {
    values$formatColumnsError <- ""
    
    firstDataset <- values$firstSelectedDataset()
    newColumnList <- DatasetFormat.newColumnList(colnames(firstDataset@parsedData))
    columnDataTypes <- c()
    
    for (index in 1:length(newColumnList)) {
      selectedDataType <- input[[paste0("row_select_type_", index)]]
      selectedExtension <- input[[paste0("row_select_ext_", index)]]
      selectedUnit <- input[[paste0("row_select_unit_", index)]]
      
      newColumnList[[index]]@dataType <- selectedDataType
      newColumnList[[index]]@extension <- selectedExtension
      newColumnList[[index]]@units <- selectedUnit
      
      columnDataTypes <- c(columnDataTypes, selectedDataType)
    }
    
    for (datasetIdx in values$selectedDatasets) {
      values$datasetList[[datasetIdx]]@format@columnList <- newColumnList
      
      # update / reset dataset status
      values$datasetList[[datasetIdx]]@status <- Dataset.status.Uploaded
    }
    
    # check for required columns
    errors <- DatasetFormat.columnCheck(values$firstSelectedDataset()@format)
    if (DatasetFormat.columnCheck.MissingTimestamp %in% errors) {
      values$formatColumnsError <- paste0(values$formatColumnsError, "ERROR: Please indicate the timestamp column.<br>")
    }
    
    if (DatasetFormat.columnCheck.MissingObs %in% errors) {
      values$formatColumnsError <- paste0(values$formatColumnsError, "ERROR: Please select at least one observations column (O3, NO2, CO, PM*, Particle Count, or meteorology data).<br>")
    }
    
    if (DatasetFormat.columnCheck.MissingLatOrLong %in% errors) {
      values$formatColumnsError <- paste0(values$formatColumnsError, "ERROR: Please select both a Longitude and Latitude column.<br>")
    }
    
    if (values$formatColumnsError != "") {
      return(NULL)
    }
    
    errors <- DatasetFormat.columnUnitCheck(values$firstSelectedDataset()@format)
    if (length(errors) > 0) {
      values$formatColumnsError <- paste0("ERROR: The following columns have invalid units (valid units for the column are in parentheses): ", paste(errors, collapse=", "))
      return(NULL)
    }
    
    hasLocationColumns <- all(c("Sensor ID", "Longitude", "Latitude") %in% columnDataTypes)
    for (datasetIdx in values$selectedDatasets) {
      values$datasetList[[datasetIdx]]@hasLocationColumns <- hasLocationColumns
    }
    
    values$resetErrorsAndData()
    
    js$enableTab("Timestamps")
    
    # disable Summary and Data Check tabs since timestamps need to be configured
    js$disableTab("Summary")
    js$disableTab("Data Check")
    
    updateTabsetPanel(session, "format", "Timestamps")
  })
}
