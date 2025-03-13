setClass("Dataset",
  slots = c(
    id = "numeric",
    rawFiles = "vector",  # character
    displayFiles = "vector",  #character
    status = "character",  # Uploaded, Format Set, Scanned, Locations Set
    hasLocationColumns = "logical",
    rawData = "vector",  # character
    parsedData = "data.frame",
    format = "DatasetFormat",
    startDate = "POSIXct",
    endDate = "POSIXct",
    monitors = "data.frame"  # sensor ID, longitude, latitude
  )
)

Dataset.status.Uploaded <- "Uploaded"
Dataset.status.FormatSet <- "Format Set"
Dataset.status.Scanned <- "Scanned"
Dataset.status.LocationsSet <- "Locations Set"

Dataset.new <- function(datasetId, rawFiles, displayFiles) {
  # get file extension from first file
  fileExt <- tools::file_ext(rawFiles[1])
  delimiter <- if (fileExt == "tsv") "\t" else ","
  format <- new("DatasetFormat", fileExtension=fileExt, delimiter=delimiter)

  new("Dataset",
    id = datasetId,
    rawFiles = rawFiles,
    displayFiles = displayFiles,
    status = Dataset.status.Uploaded,
    hasLocationColumns = FALSE,
    rawData = readLines(rawFiles[1], n=100),
    parsedData = data.frame(),
    format = format,
    startDate = as.POSIXct("1900-01-01 00:00", tz="UTC"),
    endDate = as.POSIXct("1900-01-01 00:00", tz="UTC"),
    monitors = data.frame()
  )
}

Dataset.displayFiles <- function(dataset) {
  paste(dataset@displayFiles, collapse="<br>")
}

Dataset.isReadyForExport <- function(dataset) {
  if (dataset@status == Dataset.status.Uploaded) {
    FALSE
  } else {
    if (dataset@hasLocationColumns) {
      TRUE
    } else {
      if (dataset@status == Dataset.status.LocationsSet) {
        TRUE
      } else {
        FALSE
      }
    }
  }
}

setClass("ScanConfig",
  slots = c(
    sensorCol = "integer",
    timestampCols = "vector",  # integer
    longitudeCol = "vector",  # integer
    latitudeCol = "integer",
    delimiter = "character",
    headerRowIdx = "integer",
    timestampFormats = "character",
    timezone = "character"
  )
)

Dataset.buildScanConfig <- function(dataset) {
  columnDataTypes <- DatasetFormat.columnDataTypes(dataset@format)
  if (length(columnDataTypes) == 0) {
    return(NULL)
  }
  
  timestampCols <- which(columnDataTypes == "Timestamp")
  if (length(timestampCols) == 0) {
    return(NULL)
  }
  
  timestampFormats <- c()
  for (colIdx in timestampCols) {
    timestampFormats <- c(timestampFormats, dataset@format@columnList[[colIdx]]@timestampFormat)
  }
  
  new("ScanConfig",
    sensorCol = match("Sensor ID", columnDataTypes),
    timestampCols = timestampCols,
    longitudeCol = match("Longitude", columnDataTypes),
    latitudeCol = match("Latitude", columnDataTypes),
    delimiter = dataset@format@delimiter,
    headerRowIdx = dataset@format@headerRowIdx,
    timestampFormats = timestampFormats,
    timezone = dataset@format@timezone
  )
}
