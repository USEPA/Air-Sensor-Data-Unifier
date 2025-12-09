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
  
  # assign unique sensor ID numbers based on sensor name and location
  sensorData <- paste(fullData[,scanConfig@sensorCol], fullData[,scanConfig@longitudeCol], fullData[,scanConfig@latitudeCol])
  uniqueIds <- as.numeric(as.factor(sensorData))
  
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
  
  # calculate mean and sample count for data columns and order by timestamp, then id
  rawMeanVals <- aggregate(.~ts+lon+lat+id+note, fullData, mean)
  meanVals <- rawMeanVals[order(rawMeanVals[,1], rawMeanVals[,4]),]
  
  rawCounts <- aggregate(.~ts+lon+lat+id+note, fullData, length)
  counts <- rawCounts[order(rawCounts[,1], rawCounts[,4]),]
  
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

# timePeriod -> raw, hourly, daily
convertExportToColoradoAQDE <- function(data, timePeriod) {
  n <- nrow(data)
  measure_cols <- if (ncol(data) >= 7) names(data)[6:(ncol(data)-1)] else character(0)
  if (length(measure_cols) == 0) {
    return(data.frame(
      data_steward_name = rep(NA_character_, n),          # string(64)
      device_id = as.character(data[["note(-)"]]),        # string(64)
      device_manufacturer_name = rep(NA_character_, n),   # string(64)
      datetime = as.character(data[["timestamp(UTC)"]]),  # string(27)
      lat = as.numeric(data[["latitude(deg)"]]),          # decimal(9,5)
      lon = as.numeric(data[["longitude(deg)"]]),         # decimal(9,5)
      duration = rep(NA_real_, n),                        # decimal(9,3)
      parameter_code = rep(NA_integer_, n),               # integer(5)
      method_code = rep(NA_integer_, n),                  # integer(3)
      value = rep(NA_real_, n),                           # decimal(12,5)
      unit_code = rep(NA_integer_, n),                    # integer(3)
      autoqc_check = rep(NA_integer_, n),                 # integer(1)
      corr_code = rep(NA_integer_, n),                    # integer(1)
      review_level_code = rep(NA_integer_, n),            # integer(1)
      qc_code = rep(NA_integer_, n),                      # integer(1)
      qualifier_codes = rep(NA_character_, n),            # string(254)
      data_license_code = rep(NA_integer_, n),            # integer(1)
      elev = rep(NA_real_, n),                            # decimal(8,2)
      stringsAsFactors = FALSE
    ))
  }

	# Map measurement column name -> parameter_code
  # https://aqs.epa.gov/aqsweb/documents/codetables/parameters.html
  # some parameter codes are not found in the table, might need to revisit in future.
	.param_code_for_col <- function(colname) {
		# strip trailing "(...)" units
		base <- sub("\\(.*\\)$", "", colname)
		# PM2.5 special cases by extension in the name
		if (grepl("^PM2_5_raw($|_)", base)) return(88501L)  # PM2.5 Raw Data
		if (grepl("^PM2_5_cal($|_)", base)) return(88502L)  # PM2.5 “FRM-like”
		# remove known extensions to get base data type
		base_no_ext <- sub("_(raw|cal|a|b|other)$", "", base, ignore.case = TRUE)
		codes <- c(
			"CO" = 42101L,
			"SO2" = 42401L,
			"NO" = 42601L,
			"NO2" = 42602L,
			"NOx" = 42603L,
			"O3" = 44201L,
			"PM2_5" = 88101L,
			"PM10" = 81102L,
      "CO2"= 42102L,
      # "PM1"
      # "PM4"
      "Particle_Count" = 87101L,
      "Temperature" = 68105L, # used Average Ambient Temperature from AQS
      "Dew_Point" = 62103L,
      # "Pressure" = ,
			"Wind_Speed" = 61101L,
			"Wind_Direction" = 61102L,
			"Humidity" = 62201L      # Relative Humidity
		)
		val <- unname(codes[base_no_ext])[1]
		if (is.null(val)) NA_integer_ else as.integer(val)
	}


	# Measurement column name -> unit_code (by units in trailing parentheses)
  # https://aqs.epa.gov/aqsweb/documents/codetables/units.html
	.unit_code_for_col <- function(colname) {
		units <- sub("^.*\\(([^()]*)\\)$", "\\1", colname)
		# no parentheses → no unit
		if (identical(units, colname)) return(NA_character_)

		codes <- c(
			"-"        = "123",  # N/A
			"ug/m3"    = "105",
			"ppb"      = "008",
			"ppm"      = "007",
			"#/cm3"    = "132",
			"#/m3"     = NA_character_,
			"degreesF" = "015",
			"degreesC" = "017",
			"%"        = "107",
			"hPa"      = NA_character_,
			"Pa"       = NA_character_,
			"inHg"     = "022",
			"m/s"      = "011",
			"mph"      = "012",
			"degrees"  = "014" # Degrees Compass
		)
		val <- unname(codes[units])[1]
		if (is.null(val)) NA_character_ else as.character(val)
	}

  .normalize_tzd <- function(x) {
    # Z -> +00:00
    x <- sub("Z$", "+00:00", x)
    # ±hhmm -> ±hh:mm
    x <- sub("([+-])(\\d{2})(\\d{2})$", "\\1\\2:\\3", x)
    # -00:00 -> +00:00 (UTC normalization)
    x <- sub("-00:00$", "+00:00", x)
    x
  }

  # Duration by export option
  if (identical(timePeriod, "Hourly")) {
    avg_secs_num <- 3600
  } else if (identical(timePeriod, "Daily")) {
    avg_secs_num <- 86400
  } else {
    ts_chr <- as.character(data[["timestamp(UTC)"]])
    ts <- tryCatch(as.POSIXct(ts_chr, format="%Y-%m-%dT%H:%M:%S%z", tz="UTC"),
                   error=function(e) as.POSIXct(sub("-0000$", "", ts_chr), format="%Y-%m-%dT%H:%M:%S", tz="UTC"))
    ts <- ts[order(ts)]
    diffs <- diff(ts)
    avg_secs_num <- if (length(diffs) >= 1) mean(as.numeric(diffs), na.rm=TRUE) else NA_real_
  }

  if (is.na(avg_secs_num)) {
    duration_str <- NA_character_
  } else {
    # Force a decimal point like `3600.` even for integer seconds
    # up to 3 decimals; keep a dot for whole numbers; blank if NA
    duration_str <- sprintf("%.3f", avg_secs_num)  # e.g., "60.000", "3.125"
    duration_str <- sub("0+$", "", duration_str)   # -> "60.", "3.125", "3.1"

    # Decimal(9,3): integer part ≤ 6 digits

    # integers
    d_int_part <- gsub("\\..*$", "", duration_str)     # remove after .
    d_int_digits <- nchar(d_int_part)

    # total digits
    d_digits_total <- nchar(gsub("[^0-9]", "", duration_str))

    # Decimal(9,3)
    #    - total ≤ 9
    #    - integers ≤ 6 (9 - 3)
    if (d_digits_total > 9 || d_int_digits > 6) {
      duration_str <- NA_character_
    }

  }
  
  out <- data.frame()
  for (col in measure_cols) {
    # compute parameter code from the measurement column name
    param_code_val <- as.integer(.param_code_for_col(col))
    unit_code_val  <- .unit_code_for_col(col)
    datetime = .normalize_tzd(as.character(data[["timestamp(UTC)"]]))


    # pressureUnit <- sub("^.*\\(([^()]*)\\)$", "\\1", col)
    # if (identical(pressureUnit, "Pa")) {
    #   data[[col]] <- data[[col]] / 1000
    # } else if (identical(pressureUnit, "hPa")) {
    #   data[[col]] <- data[[col]] / 10
    # }
    


    # Decimal(12,5) round to 5 decimals, keep '.', max 12 digits total)
    vals_raw <- suppressWarnings(as.numeric(data[[col]]))

    # round to 5 decimals; keep decimal point; NA -> blank via write.table(na="")
    value_str <- ifelse(is.na(vals_raw), NA_character_, sprintf("%.5f", vals_raw))
    value_str <- ifelse(is.na(value_str), NA_character_, sub("0+$", "", value_str))  # e.g., "85.00000" -> "85."




    # max 12 digits (exclude sign and decimal point)
    # Decimal(12,5): integer part ≤ 7 digits 

    # integers
    int_part <- gsub("\\..*$", "", value_str)     # remove after .
    int_part <- gsub("^[+-]", "", int_part)       # remove +- sign
    int_digits <- nchar(int_part)

    # total digits
    digits_total <- nchar(gsub("[^0-9]", "", value_str))

    # DECIMAL(12,5) 
    #    - total ≤ 12
    #    - integers ≤ 7 (12 - 5)
    invalid_values <- !is.na(value_str) & (digits_total > 12 | int_digits > 7)
    value_str[invalid_values] <- NA_character_

    tmp <- data.frame(
      data_steward_name = NA_character_,
      device_id = as.character(data[["note(-)"]]),
      device_manufacturer_name = NA_character_,
      datetime = datetime, # maximum 27 for colorado, but current datetime is always less than 27 chars so no checking added, commented incase future updates or debugging
      lat = as.numeric(data[["latitude(deg)"]]),
      lon = as.numeric(data[["longitude(deg)"]]),
      duration = duration_str,
      parameter_code = param_code_val,
      method_code = NA_integer_,
      value = value_str,
      unit_code = unit_code_val,
      autoqc_check = NA_integer_,
      corr_code = NA_integer_,
      review_level_code = NA_integer_,
      qc_code = NA_integer_,
      qualifier_codes = NA_character_,
      data_license_code = NA_integer_,
      elev = NA_real_,
      stringsAsFactors = FALSE
    )

    # if value is blank, corresponding blank entry for unit code.
    tmp$unit_code[is.na(tmp$value)] <- NA_character_


    out <- rbind(out, tmp)
  }

  out
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
