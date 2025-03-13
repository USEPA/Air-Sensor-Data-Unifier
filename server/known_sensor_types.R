knownSensorTypes <- function(input, output, session, values) {
  output$uploadFormatError <- renderText({
    values$uploadFormatError
  })
  
  observeEvent(input$knownSensorGoToHeaderRow, {
    updateTabsetPanel(session, "format", "Header Row")
  })

  # upload format file
  observeEvent(input$loadFormat, {
    values$uploadFormatError <- ""
    
    formatList <- tryCatch(
      jsonlite::fromJSON(input$loadFormat$datapath),
      error = function(cond) {
        NULL
      }
    )
    if (is.null(formatList) || !DatasetFormat.isValidJson(formatList)) {
      values$uploadFormatError <- "ERROR: The selected file is not a valid format information file."
      return(NULL)
    }
    
    format <- DatasetFormat.load(formatList)
    
    # check for format errors
    errors <- DatasetFormat.columnCheck(format)
    if (DatasetFormat.columnCheck.MissingTimestamp %in% errors) {
      values$uploadFormatError <- paste0(values$uploadFormatError, "ERROR: The format information file has no timestamp column.<br>")
    }
    
    if (DatasetFormat.columnCheck.MissingObs %in% errors) {
      values$uploadFormatError <- paste0(values$uploadFormatError, "ERROR: The format information file must include at least one observations column (O3, NO2, CO, PM*, Particle Count, or meteorology data).<br>")
    }
    
    if (DatasetFormat.columnCheck.MissingLatOrLong %in% errors) {
      values$uploadFormatError <- paste0(values$uploadFormatError, "ERROR: If the format information file contains a Longitude or Latitude column, both columns must be included.<br>")
    }
    
    if (values$uploadFormatError != "") {
      return(NULL)
    }
    
    errors <- DatasetFormat.columnUnitCheck(format)
    if (length(errors) > 0) {
      values$uploadFormatError <- paste0("ERROR: The following columns have invalid units (valid units for the column are in parentheses): ", paste(errors, collapse=", "))
      return(NULL)
    }
    
    formatColumnHeaders <- DatasetFormat.columnHeaders(format)
    formatColumnTypes <- DatasetFormat.columnDataTypes(format)
    
    # scan files in selected datasets and check that they match the loaded format
    for (datasetIdx in values$selectedDatasets) {
      first <- TRUE
      for (rawFile in values$datasetList[[datasetIdx]]@rawFiles) {
        if (tools::file_ext(rawFile) != format@fileExtension) {
          values$uploadFormatError <- "ERROR: The file extension for the uploaded files doesn't match the sensor format information."
          return(NULL)
        }
        
        parsedData <- tryCatch(
          parseFile(rawFile, format@delimiter, format@headerRowIdx, 10),
          error = function(cond) {
            NULL
          }
        )
        if (is.null(parsedData) || nrow(parsedData) == 0) {
          values$uploadFormatError <- "ERROR: At least one uploaded file doesn't contain any data records."
          return(NULL)
        }
      
        if (length(colnames(parsedData)) != length(format@columnList)) {
          values$uploadFormatError <- "ERROR: The number of columns in the uploaded files doesn't match the sensor format information."
          return(NULL)
        }
        
        if (!identical(colnames(parsedData), formatColumnHeaders)) {
          values$uploadFormatError <- "ERROR: The list of columns in the uploaded files doesn't match the sensor format information."
          return(NULL)
        }
        
        if (first) {
          values$datasetList[[datasetIdx]]@parsedData <- parsedData
          values$datasetList[[datasetIdx]]@format <- format
          values$datasetList[[datasetIdx]]@status <- Dataset.status.FormatSet
          hasLocationColumns <- all(c("Sensor ID", "Longitude", "Latitude") %in% formatColumnTypes)
          values$datasetList[[datasetIdx]]@hasLocationColumns <- hasLocationColumns
          first <- FALSE
        }
      }
    }
    
    updateNumericInput(session, "headerRowIdx", value=format@headerRowIdx)
    #updateNumericInput(session, "dataRowIdx", value=format@dataRowIdx)
    updateTextInput(session, "columnDelimiter", value=format@delimiter)
    
    if (format@timezone %in% c("in_timestamp", "sensor_specific")) {
      updateRadioButtons(session, "timeZoneOptions", selected=format@timezone)
      updateSelectInput(session, "timeZone", selected="UTC")
    } else {
      updateRadioButtons(session, "timeZoneOptions", selected="use_one_timezone")
      updateSelectInput(session, "timeZone", selected=format@timezone)
    }
    
    updateTextInput(session, "formatSensorType", value=format@sensorName)
    updateTextInput(session, "formatDescription", value=format@formatNotes)
    # strip json extension from filename
    updateTextInput(session, "formatFilename", value=sub(".json$", "", input$loadFormat$name))
    
    values$resetErrorsAndData()
    
    js$enableTab("Columns")
    js$enableTab("Timestamps")
    js$enableTab("Summary")
    js$enableTab("Data Check")
    updateTabsetPanel(session, "format", "Data Check")
  })
}
