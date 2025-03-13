source("server/known_sensor_types.R", local=TRUE)
source("server/format_header_row.R", local=TRUE)
source("server/format_columns.R", local=TRUE)
source("server/format_timestamps.R", local=TRUE)
source("server/format_summary.R", local=TRUE)
source("server/format_data_check.R", local=TRUE)

formatWizard <- function(input, output, session, values) {
  knownSensorTypes(input, output, session, values)
  formatHeaderRow(input, output, session, values)
  formatColumns(input, output, session, values)
  formatTimestamps(input, output, session, values)
  formatSummary(input, output, session, values)
  formatDataCheck(input, output, session, values)
  
  output$selectedFilenamesFormatWizard <- renderText({
    displaySelectedFilenames(values$datasetList[values$selectedDatasets])
  })
}
