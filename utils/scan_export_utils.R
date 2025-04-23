parseFile <- function(path, delimiter, headerRowIdx, nrows) {
  header <- TRUE
  if (headerRowIdx == 0) {
    header <- FALSE
  }
  read.table(path, sep=delimiter, header=header, skip=headerRowIdx-1, nrows=nrows, comment.char="", check.names=FALSE, fill=TRUE)
}

parsedTimestamps <- function(data, scanConfig) {
  first <- TRUE
  for (colIdx in scanConfig@timestampCols) {
    if (first) {
      rawTimestampData <- data[,colIdx]
      first <- FALSE
    } else {
      rawTimestampData <- paste(rawTimestampData, data[,colIdx])
    }
  }
  timestampFormat <- paste0(scanConfig@timestampFormats, collapse=" ")
  parseTimestamps(rawTimestampData, timestampFormat, scanConfig@timezone)
}

addFileNameToError <- function(error, fileName=NULL) {
  paste0(error, " \"", fileName, "\".")
}

checkTimestamps <- function(timestamps, fileName) {
  if (any(is.na(timestamps))) {
    return(addFileNameToError("ERROR: Invalid timestamps were found in the data file", fileName))
  }
  ""
}

checkCoordinates <- function(data, scanConfig, fileName) {
  # skip if dataset doesn't have coordinate columns
  if (is.na(scanConfig@longitudeCol) || is.na(scanConfig@latitudeCol)) {
    return("")
  }
  
  longitudeVals <- data[,scanConfig@longitudeCol]
  if (any(is.na(longitudeVals))) {
    return(addFileNameToError("ERROR: Longitude values are missing in the data file", fileName))
  }
  if (!all(is.numeric(longitudeVals))) {
    return(addFileNameToError("ERROR: Non-numeric longitude values were found in the data file", fileName))
  }
  if (any(longitudeVals < -180) || any(longitudeVals > 180)) {
    return(addFileNameToError("ERROR: Longitude values outside the range -180 to 180 were found in the data file", fileName))
  }

  latitudeVals <- data[,scanConfig@latitudeCol]
  if (any(is.na(latitudeVals))) {
    return(addFileNameToError("ERROR: Latitude values are missing in the data file", fileName))
  }
  if (!all(is.numeric(latitudeVals))) {
    return(addFileNameToError("ERROR: Non-numeric latitude values were found in the data file", fileName))
  }
  minLat <- -50
  maxLat <- 75
  if (any(latitudeVals < minLat) || any(latitudeVals > maxLat)) {
    return(addFileNameToError(paste0("ERROR: Latitude values outside the range ", minLat, " to ", maxLat, " were found in the data file"), fileName))
  }
  ""
}

scanDataset <- function(dataset, scanConfig) {
  scannedData <- data.frame()
  timestamps <- c()
  for (fileIdx in 1:length(dataset@rawFiles)) {
    rawFile <- dataset@rawFiles[[fileIdx]]
    fileName <- dataset@displayFiles[[fileIdx]]
    fileData <- parseFile(rawFile, scanConfig@delimiter, scanConfig@headerRowIdx, -1)
    
    # parse and check timestamps
    fileTimestamps <- parsedTimestamps(fileData, scanConfig)
    error <- checkTimestamps(fileTimestamps, fileName)
    if (error != "") {
      return(list("error"=error))
    }
    
    # check latitude and longitude values
    error <- checkCoordinates(fileData, scanConfig, fileName)
    if (error != "") {
      return(list("error"=error))
    }
    
    scannedData <- rbind(scannedData, fileData)
    timestamps <- append(timestamps, fileTimestamps)
  }
  
  startDate <- min(timestamps)
  endDate <- max(timestamps)
  
  # build list of unique sensors and locations
  allCols <- c(scanConfig@sensorCol, scanConfig@longitudeCol, scanConfig@latitudeCol)
  if (all(!is.na(allCols))) {
    monitors <- unique(scannedData[,allCols])
  } else if (all(is.na(allCols))) {
    monitors <- data.frame("", 0, 0)
  } else if (is.na(scanConfig@sensorCol)) {
    monitors <- data.frame("", unique(scannedData[,c(scanConfig@longitudeCol, scanConfig@latitudeCol)]))
  } else {
    monitors <- data.frame(unique(scannedData[,scanConfig@sensorCol]), 0, 0)
  }
  colnames(monitors) <- c("Sensor ID", "Longitude", "Latitude")
  
  return(list("startDate"=startDate, "endDate"=endDate, "monitors"=monitors))
}

exportName <- function(dataType, extension, units) {
  # variable names can only contain letters, digits and internal underscores
  cleanType <- gsub("[^a-z0-9_]", "_", dataType, ignore.case=TRUE)
  name <- cleanType
  
  if (extension != "none") {
    name <- paste0(name, "_", extension)
  }
  
  if (units != "N/A") {
    # units cannot contain spaces
    cleanUnits <- gsub(" ", "", units)
    name <- paste0(name, "(", cleanUnits, ")")
  } else {
    name <- paste0(name, "(-)")
  }
 
  name
}

assignSensorLocations <- function(fileData, dataset, scanConfig) {
  sensorCol <- scanConfig@sensorCol
  longitudeCol <- scanConfig@longitudeCol
  latitudeCol <- scanConfig@latitudeCol
  
  if (all(is.na(c(sensorCol, longitudeCol, latitudeCol)))) {
    sensorCol <- ncol(fileData) + 1
    fileData[,sensorCol] <- dataset@monitors["Sensor ID"]
    longitudeCol <- ncol(fileData) + 1
    fileData[,longitudeCol] <- dataset@monitors["Longitude"]
    latitudeCol <- ncol(fileData) + 1
    fileData[,latitudeCol] <- dataset@monitors["Latitude"]

  } else if (is.na(sensorCol)) {
    # match dataset monitors to file data using longitude and latitude columns
    sensorCol <- ncol(fileData) + 1
    for (index in 1:nrow(dataset@monitors)) {
      sensorId <- dataset@monitors[["Sensor ID"]][[index]]
      longitude <- dataset@monitors[["Longitude"]][[index]]
      latitude <- dataset@monitors[["Latitude"]][[index]]
      fileData[
        fileData[[longitudeCol]] == longitude &
        fileData[[latitudeCol]] == latitude,sensorCol] <- sensorId
    }

  } else if (is.na(longitudeCol) && is.na(latitudeCol)) {
    # match dataset monitors to file data using sensor ID
    longitudeCol <- ncol(fileData) + 1
    latitudeCol <- ncol(fileData) + 2
    for (index in 1:nrow(dataset@monitors)) {
      sensorId <- dataset@monitors[["Sensor ID"]][[index]]
      longitude <- dataset@monitors[["Longitude"]][[index]]
      latitude <- dataset@monitors[["Latitude"]][[index]]
      fileData[fileData[[sensorCol]] == sensorId,longitudeCol] <- longitude
      fileData[fileData[[sensorCol]] == sensorId,latitudeCol] <- latitude
    }
  }
  
  # save new column locations to ScanConfig
  scanConfig@sensorCol <- as.integer(sensorCol)
  scanConfig@longitudeCol <- as.integer(longitudeCol)
  scanConfig@latitudeCol <- as.integer(latitudeCol)
  
  return(list("fileData"=fileData, "scanConfig"=scanConfig))
}

loadFullData <- function(datasetList, scanConfig) {
  # use original ScanConfig when loading all datasets - ScanConfig may get updated
  # when assigning sensor locations which messes up subsequent coordinate checks
  origScanConfig <- scanConfig
  
  fullData <- data.frame()
  timestamps <- c()
  for (dataset in datasetList) {
    for (fileIdx in 1:length(dataset@rawFiles)) {
      rawFile <- dataset@rawFiles[[fileIdx]]
      fileName <- dataset@displayFiles[[fileIdx]]
      fileData <- parseFile(rawFile, origScanConfig@delimiter, origScanConfig@headerRowIdx, -1)
      
      # parse and check timestamps
      fileTimestamps <- parsedTimestamps(fileData, origScanConfig)
      error <- checkTimestamps(fileTimestamps, fileName)
      if (error != "") {
        return(list("error"=error))
      }
      
      # check latitude and longitude values
      error <- checkCoordinates(fileData, origScanConfig, fileName)
      if (error != "") {
        return(list("error"=error))
      }
      
      results <- assignSensorLocations(fileData, dataset, origScanConfig)
      scanConfig <- results$scanConfig
      fullData <- rbind(fullData, results$fileData)
      timestamps <- append(timestamps, fileTimestamps)
    }
  }
  
  # assign unique sensor ID numbers
  uniqueSensors <- unique(fullData[,scanConfig@sensorCol])
  uniqueIds <- rep(0, nrow(fullData))
  for (index in 1:length(uniqueSensors)) {
    uniqueIds[fullData[,scanConfig@sensorCol] == uniqueSensors[index]] <- index
  }
  
  workTable <- data.frame(timestamps, fullData[,scanConfig@longitudeCol], fullData[,scanConfig@latitudeCol], uniqueIds, fullData[,scanConfig@sensorCol])
  colnames(workTable) <- c("ts", "lon", "lat", "id", "note")
  
  # add data columns to work table
  workDataColumns <- c()
  colIdx <- 0
  for (column in datasetList[[1]]@format@columnList) {
    colIdx <- colIdx + 1
    
    # skip unused and already output columns
    if (!is.na(match(column@dataType, c("Unused", "Sensor ID", "Timestamp", "Longitude", "Latitude")))) {
      next
    }
    workDataColumns <- c(workDataColumns, column)
    workTable[,ncol(workTable) + 1] <- fullData[,colIdx]
  }
  
  # sort by timestamp, then id
  return(list("fullData"=workTable[order(workTable[,1], workTable[,4]),], "dataColumns"=workDataColumns))
}

calculateAverages <- function(fullData, tsAverageType) {
  # calculate output timestamps
  if (tsAverageType == "Hourly") {
    fullData$ts <- paste0(format(fullData$ts, "%Y-%m-%dT%H:00:00"), "-0000")
  } else if (tsAverageType == "Daily") {
    fullData$ts <- paste0(format(fullData$ts, "%Y-%m-%dT%00:00:00"), "-0000")
  } else {
    # default to Raw
    fullData$ts <- paste0(format(fullData$ts, "%Y-%m-%dT%H:%M:%S"), "-0000")
    return(list("meanVals"=fullData, "counts"=rep(1, nrow(fullData))))
  }
  
  # calculate mean and sample count for data columns
  meanVals <- aggregate(.~ts+lon+lat+id+note, fullData, mean)
  counts <- aggregate(.~ts+lon+lat+id+note, fullData, length)
  
  numGrpCols <- length(c("ts", "lon", "lat", "id", "note"))
  return(list("meanVals"=meanVals, "counts"=counts[,numGrpCols + 1]))
}

createExportData <- function(exportData, counts, dataColumns) {
  exportNames <- c("timestamp(UTC)", "longitude(deg)", "latitude(deg)", "id(-)")
  export <- data.frame(exportData["ts"], exportData["lon"], exportData["lat"], exportData["id"])
  
  # add count column
  if (!is.null(counts)) {
    exportNames <- c(exportNames, "count(-)")
    export[,ncol(export) + 1] <- counts
  }
  
  # add data columns to output table
  numGrpCols <- length(c("ts", "lon", "lat", "id", "note"))
  dataColIdx <- numGrpCols
  for (column in dataColumns) {
    dataColIdx <- dataColIdx + 1
    exportNames <- c(exportNames, exportName(column@dataType, column@extension, column@units))
    export[,ncol(export) + 1] <- exportData[,dataColIdx]
  }
  
  # add note column
  exportNames <- c(exportNames, "note(-)")
  export[,ncol(export) + 1] <- exportData["note"]
  
  colnames(export) <- exportNames
  export
}

buildExportData <- function(datasetList, scanConfig, tsAverageType, flags) {
  loadedData <- loadFullData(datasetList, scanConfig)
  if (!is.null(loadedData$error)) {
    return(list("error"=loadedData$error))
  }
  
  flaggedData <- Flag.applyToData(flags, loadedData$fullData, TRUE)
  # check for case where all records are dropped
  if (nrow(flaggedData$data) == 0) {
    return(list("error"="ERROR: All records were dropped due to the applied data flagging rules."))
  }
  # remove flags column
  flaggedData$data$flags <- NULL
  
  averagedData <- calculateAverages(flaggedData$data, tsAverageType)
  createExportData(averagedData$meanVals, averagedData$counts, loadedData$dataColumns)
}

convertExportToRETIGO <- function(data) {
  # replace ID column
  data[["id(-)"]] <- data[["note(-)"]]
  
  # remove unused columns
  data[["count(-)"]] <- NULL
  data[["note(-)"]] <- NULL
  
  # relabel non-data columns
  colnames(data)[1:4] <- c("Timestamp(UTC)", "EAST_LONGITUDE(deg)", "NORTH_LATITUDE(deg)", "ID(-)")
  
  # update timestamp format: 2024-08-31T00:00:00-0000 -> 2024-08-31T00:00:00-00:00
  data[[1]] <- sub("00$", ":00", data[[1]])
  
  data
}

writeKML <- function(data) {
  paste0(
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<kml xmlns=\"http://www.opengis.net/kml/2.2\">
  <Document>",
    paste0(apply(data, 1, function(record) writeRecordAsKML(record)), collapse=""), "
  </Document>
</kml>")
}

writeRecordAsKML <- function(record) {
  dataColumns <- names(record)[6:(length(record)-1)]
  paste0("
    <Placemark>
      <name>", record[[length(record)]], "</name>
      <TimeStamp>
        <when>",
    sub("-0000$", "Z", record[[1]]), "</when>
      </TimeStamp>
      <ExtendedData>",
    paste0(sapply(dataColumns, function(column) {
      paste0("
        <Data name=\"", column, "\">
          <value>", record[[column]], "</value>
        </Data>")
    }), collapse=""), "
      </ExtendedData>
      <Point>
        <coordinates>", record[[2]], ",", record[[3]], "</coordinates>
      </Point>
    </Placemark>")
}

# create list of unique monitors across all selected datasets
combineMonitors <- function(datasetList) {
  rawMonitors <- data.frame()
  for (dataset in datasetList) {
    rawMonitors <- rbind(rawMonitors, dataset@monitors)
  }
  unique(rawMonitors)
}

updateMonitors <- function(dataset, newMonitors) {
  columnDataTypes <- DatasetFormat.columnDataTypes(dataset@format)
  
  sensorCol <- match("Sensor ID", columnDataTypes)
  longitudeCol <- match("Longitude", columnDataTypes)
  latitudeCol <- match("Latitude", columnDataTypes)
  
  allCols <- c(sensorCol, longitudeCol, latitudeCol)
  
  # dataset has all columns, no updates needed
  if (all(!is.na(allCols))) {
    return(dataset@monitors)
  }
  
  # dataset has none of the columns, use new data
  if (all(is.na(allCols))) {
    return(newMonitors)
  }
  
  monitors <- data.frame()
  if (is.na(sensorCol)) {
    # match monitors using Longitude and Latitude columns
    merged <- merge(dataset@monitors, newMonitors, by=c("Longitude", "Latitude"))
    monitors <- merged[c("Sensor ID.y", "Longitude", "Latitude")]
  } else {
    # match monitors using Sensor ID column
    merged <- merge(dataset@monitors, newMonitors, by="Sensor ID")
    monitors <- merged[c("Sensor ID", "Longitude.y", "Latitude.y")]
  }
  
  colnames(monitors) <- c("Sensor ID", "Longitude", "Latitude")
  return(monitors)
}
