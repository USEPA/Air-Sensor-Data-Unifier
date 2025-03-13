Flag.type.MissingValue <- "missingValue"
Flag.type.MinimumValue <- "minimumValue"
Flag.type.MaximumValue <- "maximumValue"
Flag.type.RepeatValue <- "repeatValue"
Flag.type.OutlierValue <- "outlierValue"

Flag.action.DropRecord <- "Drop record"
Flag.action.ReplaceValue <- "Replace value"
Flag.action.ReportOnly <- "Report only"

setClass("Flag",
  slots = c(
    type = "character",
    label = "character",
    enabled = "logical",
    testValue = "numeric",
    action = "character",
    replacementValue = "numeric"
  ),
  prototype = list(
    type = "",
    label = "",
    enabled = FALSE,
    testValue = 0,
    action = Flag.action.DropRecord,
    replacementValue = 0
  )
)

Flag.columnNames <- function(format) {
  dataTypes <- DatasetFormat.columnDataTypes(format)
  obsIdxs <- obsColumns(dataTypes)
  sapply(format@columnList[obsIdxs],
         function(column) exportName(column@dataType, column@extension, column@units))
}

Flag.defaults <- function(index) {
  list(
    new("Flag", type=Flag.type.MissingValue, label=paste0(index, "A"), enabled=TRUE),
    new("Flag", type=Flag.type.MinimumValue, label=paste0(index, "B")),
    new("Flag", type=Flag.type.MaximumValue, label=paste0(index, "C"), testValue=999),
    new("Flag", type=Flag.type.RepeatValue, label=paste0(index, "D"), testValue=3),
    new("Flag", type=Flag.type.OutlierValue, label=paste0(index, "E"), testValue=3)
  )
}

Flag.buildDefaults <- function(format) {
  colNames <- Flag.columnNames(format)
  flags <- lapply(seq_along(colNames), function (idx) Flag.defaults(idx))
  names(flags) <- colNames
  flags
}

Flag.isDefaults <- function(flags) {
  defaults <- Flag.defaults(1)
  for (colName in names(flags)) {
    for (flagIdx in 1:length(flags[[colName]])) {
      flag <- flags[[colName]][[flagIdx]]
      defaultFlag <- defaults[[flagIdx]]
      if (flag@type != defaultFlag@type ||
          flag@enabled != defaultFlag@enabled ||
          flag@testValue != defaultFlag@testValue ||
          flag@action != defaultFlag@action ||
          flag@replacementValue != defaultFlag@replacementValue) {
        return(FALSE)
      }
    }
  }
  TRUE
}

Flag.dataIdx <- function(flag) {
  colIdx <- as.integer(substr(flag@label, 1, 1))
  colIdx + 5  # adjust for ts, lon, lat, id, and note columns
}

Flag.applyToData <- function(flags, data, modify=FALSE) {
  data$flags <- ""
  
  dropFlags <- c()
  replaceFlags <- c()
  
  for (colFlags in flags) {
    for (flag in colFlags) {
      if (!flag@enabled) {
        next
      }
      
      dataIdx <- Flag.dataIdx(flag)
      if (flag@type == Flag.type.MissingValue) {
        match <- which(is.na(data[,dataIdx]))
        data$flags[match] <- paste(data$flags[match], flag@label)
      }
      if (flag@type == Flag.type.MinimumValue) {
        match <- which(data[,dataIdx] < flag@testValue)
        data$flags[match] <- paste(data$flags[match], flag@label)
      }
      if (flag@type == Flag.type.MaximumValue) {
        match <- which(data[,dataIdx] > flag@testValue)
        data$flags[match] <- paste(data$flags[match], flag@label)
      }
      if (flag@type == Flag.type.RepeatValue) {
        for (id in unique(data$id)) {
          matchId <- which(data$id == id)
          rleResult <- rle(data[matchId,dataIdx])
          repeatIdx <- which(rleResult$lengths >= flag@testValue)
          if (length(repeatIdx) > 0) {
            for (idx in repeatIdx) {
              startIdx <- 1
              if (idx > 1) {
                startIdx <- sum(rleResult$lengths[1:(idx-1)]) + 1
              }
              endIdx <- sum(rleResult$lengths[1:idx])
              data$flags[matchId][startIdx:endIdx] <- paste(data$flags[matchId][startIdx:endIdx], flag@label)
            }
          }
        }
      }
      if (flag@type == Flag.type.OutlierValue) {
        for (id in unique(data$id)) {
          matchId <- which(data$id == id)
          meanVal <- mean(data[matchId,dataIdx], na.rm=TRUE)
          sdVal <- sd(data[matchId,dataIdx], na.rm=TRUE)
          match <- which(abs(data[matchId,dataIdx] - meanVal) > flag@testValue * sdVal)
          data$flags[matchId][match] <- paste(data$flags[matchId][match], flag@label)
        }
      }
      
      if (flag@action == Flag.action.DropRecord) {
        dropFlags <- c(dropFlags, flag)
      }
      if (flag@action == Flag.action.ReplaceValue) {
        replaceFlags <- c(replaceFlags, flag)
      }
    }
  }
  
  # strip leading space from flags column
  data$flags <- sub("^ ", "", data$flags)
  
  # build summary
  flagged <- which(data$flags != "")
  recordsFlagged <- length(flagged)
  remainingFlags <- data$flags[flagged]
  
  modifiedData <- data
  
  recordsDropped <- 0
  if (length(dropFlags) > 0) {
    flagLabels <- sapply(dropFlags, function(flag) flag@label)
    regex <- paste(flagLabels, collapse="|")
    matched <- which(grepl(regex, remainingFlags))
    recordsDropped <- recordsDropped + length(matched)
    if (length(matched) > 0) {
      remainingFlags <- remainingFlags[-matched]
    
      if (modify) {
        allDropped <- which(grepl(regex, modifiedData$flags))
        modifiedData <- modifiedData[-allDropped,]
      }
    }
  }
  
  recordsReplaced <- 0
  if (length(replaceFlags) > 0) {
    flagLabels <- sapply(replaceFlags, function(flag) flag@label)
    regex <- paste(flagLabels, collapse="|")
    matched <- which(grepl(regex, remainingFlags))
    recordsReplaced <- recordsReplaced + length(matched)
    
    if (modify && length(matched) > 0) {
      for (flag in replaceFlags) {
        match <- which(grepl(flag@label, modifiedData$flags))
        if (length(match) > 0) {
          modifiedData[match,Flag.dataIdx(flag)] <- flag@replacementValue
        }
      }
    }
  }
  
  summary <- list("totalRecords"=nrow(data),
                  "recordsFlagged"=recordsFlagged,
                  "recordsDropped"=recordsDropped,
                  "recordsReplaced"=recordsReplaced)
  
  return(list("data"=modifiedData, "summary"=summary))
}

Flag.logReport <- function(flags) {
  log <- ""
  for (column in names(flags)) {
    log <- paste0(log, column, "\n")
    for (flag in flags[[column]]) {
      if (flag@enabled && flag@action != Flag.action.ReportOnly) {
        if (flag@type == Flag.type.MissingValue) {
          log <- paste0(log, "- Missing value: ", flag@action)
          if (flag@action == Flag.action.ReplaceValue) {
            log <- paste0(log, " (", flag@replacementValue, ")")
          }
          log <- paste0(log, "\n")
        }
        if (flag@type == Flag.type.MinimumValue) {
          log <- paste0(log, "- Minimum value: ", flag@testValue, ", ", flag@action)
          if (flag@action == Flag.action.ReplaceValue) {
            log <- paste0(log, " (", flag@replacementValue, ")")
          }
          log <- paste0(log, "\n")
        }
        if (flag@type == Flag.type.MaximumValue) {
          log <- paste0(log, "- Maximum value: ", flag@testValue, ", ", flag@action)
          if (flag@action == Flag.action.ReplaceValue) {
            log <- paste0(log, " (", flag@replacementValue, ")")
          }
          log <- paste0(log, "\n")
        }
        if (flag@type == Flag.type.RepeatValue) {
          log <- paste0(log, "- Repeat value: ", flag@testValue, " times", ", ", flag@action)
          log <- paste0(log, "\n")
        }
        if (flag@type == Flag.type.OutlierValue) {
          log <- paste0(log, "- Outlier value: ", flag@testValue, " standard deviations", ", ", flag@action)
          log <- paste0(log, "\n")
        }
      }
    }
  }
  log
}
