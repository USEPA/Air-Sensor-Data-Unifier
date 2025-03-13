unitOptions <- c(
  "N/A",
  "ug/m3",
  "ppb",
  "ppm",
  "#/cm3",
  "#/m3",
  "degrees F",
  "degrees C",
  "%",
  "m/s",
  "mph",
  "degrees"
)

columnTypes <- list(
  "Unused" = list("units" = c(), "obs" = FALSE),
  "Sensor ID" = list("units" = c("N/A"), "obs" = FALSE),
  "Timestamp" = list("units" = c("N/A"), "obs" = FALSE),
  "O3" = list("units" = c("ppb", "ppm", "ug/m3"), "obs" = TRUE),
  "NO2" = list("units" = c("ppb", "ppm", "ug/m3"), "obs" = TRUE),
  "CO" = list("units" = c("ppb", "ppm"), "obs" = TRUE),
  "PM1" = list("units" = c("ug/m3"), "obs" = TRUE),
  "PM2.5" = list("units" = c("ug/m3"), "obs" = TRUE),
  "PM10" = list("units" = c("ug/m3"), "obs" = TRUE),
  "Particle Count" = list("units" = c("#/cm3", "#/m3"), "obs" = TRUE),
  "Temperature" = list("units" = c("degrees F", "degrees C"), "obs" = TRUE),
  "Dew Point" = list("units" = c("degrees F", "degrees C"), "obs" = TRUE),
  "Humidity" = list("units" = c("%"), "obs" = TRUE),
  "Pressure" = list("units" = c("hPa"), "obs" = TRUE),
  "Wind Speed" = list("units" = c("m/s", "mph"), "obs" = TRUE),
  "Wind Direction" = list("units" = c("degrees"), "obs" = TRUE),
  "Latitude" = list("units" = c("degrees"), "obs" = FALSE),
  "Longitude" = list("units" = c("degrees"), "obs" = FALSE),
  "Other" = list("units" = c(), "obs" = FALSE)
)

isObsColumn <- function(type) {
  columnTypes[[type]]$obs
}

obsColumns <- function(types) {
  which(sapply(types, isObsColumn) == TRUE)
}

columnExtensions <- c("none", "raw", "cal", "a", "b", "other")

columnDelimiters <- c(
  "Comma (,)" = ",",
  "Pipe (|)" = "|",
  "Semicolon (;)" = ";",
  "Space" = " ",
  "Tab" = "\t"
)

displaySelectedFilenames <- function(selectedDatasets) {
  allFiles <- c()
  for (dataset in selectedDatasets) {
    allFiles <- c(allFiles, dataset@displayFiles)
  }
  paste("<em>Selected Files:</em>", paste(allFiles, collapse="<br>"))
}
