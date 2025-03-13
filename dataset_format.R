setClass("DatasetFormatColumn",
  slots = c(
    header = "character",
    dataType = "character",
    extension = "character",
    units = "character",
    timestampFormat = "character"
  ),
  prototype = list(
    header = "",
    dataType = "",
    extension = "",
    units = "",
    timestampFormat = ""
  )
)

setClass("DatasetFormat",
  slots = c(
    sensorName = "character",
    formatNotes = "character",
    fileExtension = "character",
    delimiter = "character",
    headerRowIdx = "integer",
    dataRowIdx = "integer",
    columnList = "list",  # DatasetFormatColumn
    timezone = "character"
  ),
  prototype = list(
    sensorName = "Unknown",
    formatNotes = "",
    fileExtension = "csv",
    delimiter = ",",
    headerRowIdx = 1L,
    dataRowIdx = 2L,
    timezone = "in_timestamp"
  )
)

DatasetFormat.newColumnList <- function(columnHeaders) {
  columnList <- list()
  for (header in columnHeaders) {
    columnList <- c(columnList, new("DatasetFormatColumn", header=header))
  }
  columnList
}

DatasetFormat.columnHeaders <- function(format) {
  headers <- c()
  for (column in format@columnList) {
    headers <- c(headers, column@header)
  }
  headers
}

DatasetFormat.columnDataTypes <- function(format) {
  dataTypes <- c()
  for (column in format@columnList) {
    dataTypes <- c(dataTypes, column@dataType)
  }
  dataTypes
}

DatasetFormat.list <- function(format) {
  columns <- data.frame(matrix(ncol = 5, nrow = 0))
  for (column in format@columnList) {
    columns <- rbind(columns, c(
      column@header,
      column@dataType,
      column@extension,
      column@units,
      column@timestampFormat
    ))
  }
  colnames(columns) <- c("header", "data_type", "extension", "units", "timestamp_format")

  list(
    "sensor_name" = format@sensorName,
    "format_notes" = format@formatNotes,
    "file_extension" = format@fileExtension,
    "delimiter" = format@delimiter,
    "header_row_idx" = format@headerRowIdx,
    "data_row_idx" = format@dataRowIdx,
    "columns" = columns,
    "timezone" = format@timezone
  )
}

DatasetFormat.isValidJson <- function(list) {
  # check expected fields
  fields <- c("sensor_name", "format_notes", "file_extension", "delimiter", "header_row_idx", "data_row_idx", "columns", "timezone")
  if (length(names(list)) != length(fields) ||
    !all(names(list) == fields)) {
    return(FALSE)
  }
  
  # check expected classes
  if (class(list$sensor_name) != "character" ||
    class(list$format_notes) != "character" ||
    class(list$file_extension) != "character" ||
    class(list$delimiter) != "character" ||
    class(list$header_row_idx) != "integer" ||
    class(list$data_row_idx) != "integer" ||
    class(list$columns) != "data.frame" ||
    class(list$timezone) != "character") {
    return(FALSE)
  }
  
  # check expected column fields
  columnFields <- c("header", "data_type", "extension", "units", "timestamp_format")
  if (length(colnames(list$columns)) != length(columnFields) ||
    !all(colnames(list$columns) == columnFields)) {
    return(FALSE)
  }
  
  # check values
  tzValues <- c(timezones, "in_timestamp", "sensor_specific")
  if (!(list$delimiter %in% columnDelimiters) ||
    !all(list$columns$data_type %in% names(columnTypes)) ||
    !all(list$columns$extension %in% columnExtensions) ||
    !all(list$column$units %in% unitOptions) ||
    !(list$timezone %in% tzValues)) {
    return(FALSE)
  }
  
  TRUE
}

DatasetFormat.columnCheck.MissingTimestamp <- "missing_timestamp"
DatasetFormat.columnCheck.MissingObs <- "missing_obs"
DatasetFormat.columnCheck.MissingLatOrLong <- "missing_lat_or_long"

DatasetFormat.columnCheck <- function(format) {
  columnDataTypes <- DatasetFormat.columnDataTypes(format)
  
  errors <- c()

  if (!("Timestamp" %in% columnDataTypes)) {
    errors <- c(errors, DatasetFormat.columnCheck.MissingTimestamp)
  }

  if (length(obsColumns(columnDataTypes)) == 0) {
    errors <- c(errors, DatasetFormat.columnCheck.MissingObs)
  }

  hasLong <- "Longitude" %in% columnDataTypes
  hasLat <- "Latitude" %in% columnDataTypes
  if (hasLong != hasLat) {
    errors <- c(errors, DatasetFormat.columnCheck.MissingLatOrLong)
  }
  
  errors
}

DatasetFormat.columnUnitCheck <- function(format) {
  errors <- c()
  
  for (column in format@columnList) {
    type <- column@dataType
    allowedUnits <- columnTypes[[type]]$units
    if (length(allowedUnits) > 0 && !(column@units %in% allowedUnits)) {
      errors <- c(errors, paste0(type, " (", paste(allowedUnits, collapse=", "), ")"))
    }
  }
  
  errors
}

DatasetFormat.load <- function(list) {
  # prereq: passed DatasetFormat.isValidJson

  columnList <- list()
  for (index in 1:nrow(list$columns)) {
    row <- list$columns[index,]
    newColumn <- new("DatasetFormatColumn",
      header = row$header,
      dataType = row$data_type,
      extension = row$extension,
      units = row$units,
      timestampFormat = row$timestamp_format
    )
    columnList <- c(columnList, newColumn)
  }
  new("DatasetFormat",
    sensorName = list$sensor_name,
    formatNotes = list$format_notes,
    fileExtension = list$file_extension,
    delimiter = list$delimiter,
    headerRowIdx = list$header_row_idx,
    dataRowIdx = list$data_row_idx,
    columnList = columnList,
    timezone = list$timezone
  )
}
