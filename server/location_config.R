locationConfig <- function(input, output, session, values) {
  output$selectedFilenamesLocationConfig <- renderText({
    displaySelectedFilenames(values$datasetList[values$selectedDatasets])
  })
  
  output$needsDataScanned <- renderUI({
    needsFormat <- FALSE
    for (dataset in values$datasetList[values$selectedDatasets]) {
      if (dataset@status == Dataset.status.Uploaded) {
        needsFormat <- TRUE
        break
      }
    }
    
    if (needsFormat) {
      tagList(
        div("Please finish setting up your dataset's format, then scan your data in the Data Check tab.", class="alert alert-danger"),
        actionButton("locationConfigGoToFormatWizard", "Go to Format Wizard", class="btn-primary")
      )
    } else {
      tagList(
        div("Please scan your data by clicking the Scan All Data button in the Format Wizard > Data Check tab.", class="alert alert-danger"),
        actionButton("locationConfigGoToDataCheck", "Go to Data Check", class="btn-primary")
      )
    }
  })
  
  observeEvent(input$locationConfigGoToFormatWizard, {
    updateNavbarPage(session, "main", "Format Wizard")
    updateTabsetPanel(session, "format", "Known Sensor Types")
  })
  
  observeEvent(input$locationConfigGoToDataCheck, {
    updateNavbarPage(session, "main", "Format Wizard")
    updateTabsetPanel(session, "format", "Data Check")
  })
  
  output$locationError <- renderText({
    values$locationData$error
  })
  
  allMonitors <- reactive({
    combineMonitors(values$datasetList[values$selectedDatasets])
  })
  
  output$monitorLocations <- DT::renderDataTable({
    firstDataset <- values$firstSelectedDataset()
    columnDataTypes <- DatasetFormat.columnDataTypes(firstDataset@format)
    
    sensorCol <- match("Sensor ID", columnDataTypes)
    longitudeCol <- match("Longitude", columnDataTypes)
    latitudeCol <- match("Latitude", columnDataTypes)
    
    # build list of all monitors
    monitorsTable <- allMonitors()
    monitorsTable <- monitorsTable[c("Sensor ID", "Latitude", "Longitude")]
    
    # assign unique sensor ID if needed
    if (is.na(sensorCol)) {
      monitorsTable[monitorsTable["Sensor ID"] == "",1] <- paste("Sensor", seq_along(monitorsTable[,1]))
    }
    
    # set up user-editable fields based on columns in format
    for (index in 1:nrow(monitorsTable)) {
      if (is.na(sensorCol)) {
        monitorsTable[index,1] <- as.character(
          textInput(
            inputId=paste0("monitor_sensor_id_", index),
            label=NULL,
            value=monitorsTable[index,1]
          )
        )
      }
      if (is.na(longitudeCol) || is.na(latitudeCol)) {
        monitorsTable[index,2] <- as.character(
          numericInput(
            inputId=paste0("monitor_latitude_", index),
            label=NULL,
            value=monitorsTable[index,2]
          )
        )
        monitorsTable[index,3] <- as.character(
          numericInput(
            inputId=paste0("monitor_longitude_", index),
            label=NULL,
            value=monitorsTable[index,3]
          )
        )
      }
    }
    
    DT::datatable(
      monitorsTable,
      options=list(
        dom="t",
        ordering=FALSE,
        preDrawCallback=DT::JS("function() { Shiny.unbindAll(this.api().table().node()); }"),
        drawCallback=DT::JS("function() { Shiny.bindAll(this.api().table().node()); }"),
        pageLength=nrow(monitorsTable)
      ),
      rownames=FALSE,
      escape=FALSE,
      selection="none"
    )
  })
  
  output$saveLocationButton <- renderUI({
    if (!values$firstSelectedDataset()@hasLocationColumns) {
      actionButton("saveLocationConfig", "Save Sensor Information", class="btn-primary mt-4")
    }
  })
  
  observeEvent(input$saveLocationConfig, {
    values$locationData$error <- ""
  
    firstDataset <- values$firstSelectedDataset()
    columnDataTypes <- DatasetFormat.columnDataTypes(firstDataset@format)
    
    sensorCol <- match("Sensor ID", columnDataTypes)
    longitudeCol <- match("Longitude", columnDataTypes)
    latitudeCol <- match("Latitude", columnDataTypes)
  
    allMonitors <- allMonitors()
    for (index in 1:nrow(allMonitors)) {
      if (is.na(sensorCol)) {
        allMonitors[index,1] <- input[[paste0("monitor_sensor_id_", index)]]
      }
      
      if (is.na(longitudeCol) || is.na(latitudeCol)) {
        longitude <- input[[paste0("monitor_longitude_", index)]]
        if (!is.numeric(longitude)) {
          values$locationData$error <- "ERROR: Longitude values must be numbers."
          return(NULL)
        }
        if (longitude < -180 || longitude > 180) {
          values$locationData$error <- "ERROR: Longitude values must be between -180 and 180."
          return(NULL)
        }
        allMonitors[index,2] <- longitude
        
        latitude <- input[[paste0("monitor_latitude_", index)]]
        if (!is.numeric(latitude)) {
          values$locationData$error <- "ERROR: Latitude values must be numbers."
          return(NULL)
        }
        minLat <- -50
        maxLat <- 75
        if (latitude < minLat || latitude > maxLat) {
          values$locationData$error <- paste0("ERROR: Latitude values must be between ", minLat, " and ", maxLat, ".")
          return(NULL)
        }
        allMonitors[index,3] <- latitude
      }
    }
    
    # check for unique sensor names
    if (is.na(sensorCol)) {
      if (length(unique(allMonitors[,1])) != nrow(allMonitors)) {
        values$locationData$error <- "ERROR: Sensor IDs must be unique for each set of coordinates."
        return(NULL)
      }
    }
    
    # update monitors for each dataset
    for (datasetIdx in values$selectedDatasets) {
      dataset <- values$datasetList[[datasetIdx]]
      values$datasetList[[datasetIdx]]@monitors <- updateMonitors(dataset, allMonitors)
      values$datasetList[[datasetIdx]]@status <- Dataset.status.LocationsSet
    }
  })
}
