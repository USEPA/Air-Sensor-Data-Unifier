formatTimestamps <- function(input, output, session, values) {
  timestampColumns <- reactive({
    columnDataTypes <- DatasetFormat.columnDataTypes(values$firstSelectedDataset()@format)
    which(columnDataTypes == "Timestamp")
  })
  
  firstTimestamps <- reactive({
    values$firstSelectedDataset()@parsedData[1,timestampColumns()]
  })
  
  components <- reactive({
    components <- list()
    for (timestamp in firstTimestamps()) {
      components[[length(components) + 1]] <- detectTimestampComponents(timestamp)
    }
    components
  })
  
  output$sampleTimestamps <- renderTable({
    # prereq: format has one or more timestamp columns
    sample <- data.frame(values$firstSelectedDataset()@parsedData[,timestampColumns()])
    colnames(sample) <- paste("Timestamp Column", seq_along(sample), "Values")
    sample
  }, striped=TRUE)
  
  output$timestampsError <- renderText({
    values$timestampsError
  })
  
  output$timestampComponents <- DT::renderDataTable({
    # prereq: format has one or more timestamp columns
    
    # TODO: adjust components based on existing format
    tsComponents <- data.frame()
    for (components in components()) {
      if (nrow(components) == 0) {
        values$timestampsError <- "ERROR: No components were detected in the first value of the timestamp column."
        return(NULL)
      }
      tsComponents <- rbind(tsComponents, components)
    }
    colnames(tsComponents) <- c("Component Value", "Component Type")
    
    for (index in 1:nrow(tsComponents)) {
      selectedComponentType <- tsComponents[index,2]
      tsComponents[index,2] <- as.character(
        selectInput(
          inputId=paste0("ts_select_type_", index),
          label=NULL,
          choices=timestampComponents,
          selected=selectedComponentType,
          width="250px"
        )
      )
    }
    DT::datatable(
      tsComponents,
      options=list(
        dom="t",
        ordering=FALSE,
        preDrawCallback=DT::JS("function() { Shiny.unbindAll(this.api().table().node()); }"),
        drawCallback=DT::JS("function() { Shiny.bindAll(this.api().table().node()); }"),
        pageLength=nrow(tsComponents)
      ),
      rownames=FALSE,
      escape=FALSE,
      selection="none"
    )
  })
  
  output$timestampsDoneButton <- renderUI({
    disabled <- (values$timestampsError != "")
    actionButton("timestampsDone", "Next Step", class="btn-primary my-4", disabled=disabled)
  })
  
  observeEvent(input$timestampsDone, {
    # update timestamp format based on components
    timestampFormats <- c()
    displayRowIndex <- 0
    for (columnNum in 1:length(timestampColumns())) {
      columnComponents <- components()[[columnNum]]
      for (index in 1:nrow(columnComponents)) {
        displayRowIndex <- displayRowIndex + 1
        columnComponents[index,2] <- input[[paste0("ts_select_type_", displayRowIndex)]]
      }
      timestamp <- firstTimestamps()[columnNum]
      timestampFormats <- c(timestampFormats, timestampFormat(timestamp, columnComponents))
    }
    
    for (datasetIdx in values$selectedDatasets) {
      for (index in 1:length(timestampColumns())) {
        tsCol <- timestampColumns()[index]
        tsFormat <- timestampFormats[index]
        values$datasetList[[datasetIdx]]@format@columnList[[tsCol]]@timestampFormat <- tsFormat
      }
      
      if (input$timeZoneOptions == "use_one_timezone") {
        values$datasetList[[datasetIdx]]@format@timezone <- input$timeZone
      } else {
        values$datasetList[[datasetIdx]]@format@timezone <- input$timeZoneOptions
      }
      
      # update / reset dataset status
      values$datasetList[[datasetIdx]]@status <- Dataset.status.FormatSet
    }
    
    values$resetErrorsAndData()
    
    js$enableTab("Summary")
    js$enableTab("Data Check")
    updateTabsetPanel(session, "format", "Summary")
  })
}
