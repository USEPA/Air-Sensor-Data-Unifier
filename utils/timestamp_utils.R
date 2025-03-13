timezones <- c(
  "UTC",
  "US/Eastern",
  "US/Central",
  "US/Mountain",
  "US/Arizona",
  "US/Pacific",
  "US/Alaska",
  "US/Hawaii",
  "Etc/GMT+4",
  "Etc/GMT+5",
  "Etc/GMT+6",
  "Etc/GMT+7",
  "Etc/GMT+8",
  "Etc/GMT+9",
  "Etc/GMT+10"
)

timestampComponents <- c(
  "Year (4 digits)",
  "Year (2 digits)",
  "Month",
  "Day",
  "Hour (24 hours)",
  "Hour (12 hours)",
  "Minutes",
  "Seconds",
  "Milliseconds",
  "Timezone Offset (+0000)",
  "Timezone Offset Hours",
  "Timezone Offset Minutes",
  "Seconds Since Epoch",
  "Unknown"
)

timestampComponentsFormat <- c(
  "Year (4 digits)" = "%Y",
  "Year (2 digits)" = "%y",
  "Month" = "%m",
  "Day" = "%d",
  "Hour (24 hours)" = "%H:",
  "Hour (12 hours)" = "%I:",
  "Minutes" = "%M",
  "Seconds" = "%S",
  "Seconds with Milliseconds" = "%OS",
  "Timezone Offset (+0000)" = "%z",
  "Timezone Offset Hours" = "%z",
  "Timezone Offset Minutes" = ""
)

detectTimestampComponents <- function(string) {
  # split timestamp on non-digit characters
  components <- unlist(stringr::str_extract_all(string, "[0-9]+"))
  numComponents <- length(components)
  
  if (numComponents == 0) {
    return(data.frame())
  }
  
  hasColons <- grepl(":", string)
  hasAmPm <- grepl("[am|pm|AM|PM]", string)
  hasDateSep <- grepl("[-|/]", string)
  
  if (numComponents == 1) {
    if (nchar(components[1]) > 4) {
      types <- "Seconds Since Epoch"
    } else if (nchar(components[1]) == 4) {
      types <- "Year (4 digits)"
    } else {
      types <- "Unknown"
    }
  } else if (numComponents == 2) {
    if (hasColons) {
      types <- detectTimeComponents(components, hasAmPm)
    } else {
      types <- rep("Unknown", numComponents)
    }
  } else if (numComponents == 3) {
    if (hasColons) {
      types <- detectTimeComponents(components, hasAmPm)
    } else {
      types <- detectDateComponents(components)
    }
  } else if (numComponents == 4) {
    if (hasColons) {
      types <- detectTimeComponents(components, hasAmPm)
    } else {
      types <- rep("Unknown", numComponents)
    }
  } else if (numComponents == 5 || numComponents == 6) {
    if (hasDateSep) {
      types <- c(detectDateComponents(components[1:3]), detectTimeComponents(components[4:length(components)], hasAmPm))
    } else {
      types <- detectTimeComponents(components, hasAmPm)
    }
  } else if (numComponents >= 7) {
    types <- c(detectDateComponents(components[1:3]), detectTimeComponents(components[4:length(components)], hasAmPm))
  }
  data.frame(components, types)
}

detectDateComponents <- function(components) {
  # yyyy-mm-dd
  # mm-dd-yyyy
  # mm-dd-yy
  if (nchar(components[1]) == 4) {
    types <- c("Year (4 digits)", "Month", "Day")
  } else if (nchar(components[3]) == 4) {
    types <- c("Month", "Day", "Year (4 digits)")
  } else {
    types <- c("Month", "Day", "Year (2 digits)")
  }
  types
}

detectTimeComponents <- function(components, hasAmPm) {
  # h:m
  # h:m:s
  # h:m:s.ms or h:m:s+tz4
  # h:m:s.m+tz4 or h:m:s+tz:tz
  # h:m:s.m+tz:tz
  hasMilli <- (length(components) >= 4 && nchar(components[4] == 3))
  
  types <- c(
    if (hasAmPm) "Hour (12 hours)" else "Hour (24 hours)",
    "Minutes"
  )
  if (length(components) >= 3) {
    types <- append(types, "Seconds")
  }
  if (hasMilli) {
    types <- append(types, "Milliseconds")
  }
  if ((length(components) == 4 && !hasMilli) ||
      (length(components) == 5 && hasMilli)) {
    types <- append(types, "Timezone Offset (+0000)")
  }
  if ((length(components) == 5 && !hasMilli) ||
      length(components) == 6) {
    types <- append(types, c("Timezone Offset Hours", "Timezone Offset Minutes"))
  }
  types
}

isDateComponent <- function(component) {
  (component == "Year (4 digits)" ||
   component == "Year (2 digits)" ||
   component == "Month" ||
   component == "Day")
}

timestampFormat <- function(string, components) {
  if (nrow(components) == 1 && components[,2][1] == "Seconds Since Epoch") {
    return("seconds_since_epoch")
  }
  
  # set delimiters based on first timestamp string
  dateSeparator <- if (grepl("/", string)) "/" else "-"
  dateTimeSeparator <- if (grepl("T", string)) "T" else " "
  
  format <- ""
  needsAmPm <- FALSE
  for (i in 1:length(components[,2])) {
    item <- components[,2][i]
    nextItem <- components[,2][i+1]
    
    if (item == "Unknown") {
      return("")
    }
    
    if (item == "Hour (12 hours)") {
      needsAmPm <- TRUE
    }
    
    if (item == "Seconds") {
      if (!is.na(nextItem) && nextItem == "Milliseconds") {
        format <- paste0(format, timestampComponentsFormat["Seconds with Milliseconds"])
      } else {
        format <- paste0(format, timestampComponentsFormat["Seconds"])
      }
      next
    }
    
    if (item == "Milliseconds") {
      next
    }
    
    format <- paste0(format, timestampComponentsFormat[item])
    
    if (isDateComponent(item)) {
      if (!is.na(nextItem) && isDateComponent(nextItem)) {
        format <- paste0(format, dateSeparator)
      } else if (!is.na(nextItem)) {
        format <- paste0(format, dateTimeSeparator)
      }
    }
    
    if (item == "Minutes") {
      if (!is.na(nextItem) && nextItem == "Seconds") {
        format <- paste0(format, ":")
      }
    }
  }
  if (needsAmPm) {
    format <- paste0(format, " %p")
  }
  format
}

parseTimestamps <- function(rawTimestamps, format, timezone) {
  if (format == "seconds_since_epoch") {
    timestamps <- as.POSIXct(as.numeric(rawTimestamps), origin="1970-01-01", tz="UTC")
  } else {
    if (timezone == "in_timestamp") {
      timezone <- "UTC" # works for both Z, and timestamps with offsets
      # remove colon from timezone offset at end of timestamps
      if (endsWith(format, "%z")) {
        rawTimestamps <- sub(":([[:digit:]]{2})$", "\\1", rawTimestamps)
      }
    } else {
      timezone <- timezone
    }
    timestamps <- as.POSIXct(rawTimestamps, format, tz=timezone)
    if (timezone != "UTC") {
      attr(timestamps, "tzone") <- "UTC"
    }
  }
  timestamps
}
