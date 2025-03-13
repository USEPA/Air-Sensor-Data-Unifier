help <- nav_panel(
  title = "Help",
  div(class="m-4 help-page",
    h1("Help"),
    navset_pill_list(
      widths = c(3,9),
      nav_panel("Overview",
        h2("Overview"),
        p("The Air Sensor Data Unifier allows you to import text-based sensor data, define the format of that data, and export the data to standard formats. Format information can be saved for re-use to speed up processing of additional sensors of the same type."),
        h4("Steps"),
        tags$ol(
          tags$li("Use the ", strong("Dataset Dashboard"), " to upload your raw sensor files."),
          tags$li("Select one or more sets of uploaded files, then use the ", strong("Format Wizard"), " to define the file format. This includes identifying the header row, data columns, and timestamp formats."),
          tags$li("If needed, use the ", strong("Location Config"), " option to set the locations (latitude and longitude) of your sensors."),
          tags$li("Optionally use the ", strong("Data Flagging"), " feature to check for certain conditions in your data and decide how to handle them."),
          tags$li("From the ", strong("Export Options"), " page, select how you want your data to be exported and create your exported files. You can also generate a log file with details of the files you imported to create the exported data.")
        ),
      ),
      
      nav_panel("Dataset Dashboard",
        h2("Dataset Dashboard"),
        p("The Dataset Dashboard allows you to upload your raw sensor files, and displays a summary of files you've already loaded."),
        p("Click the ", strong("Browse"), " button to select your local sensor data files. The Air Sensor Data Unifier works with CSV (comma-separated values), TSV (tab-separated values), and plain text files. Allowed file extensions are .csv, .tsv, and .txt. Files that are uploaded together should be of the same format, and initially the Air Sensor Data Unifier will check that all the file extensions for a batch are the same."),
        p("Once your files are uploaded, they'll be displayed as a row in the ", strong("Loaded Datasets"), " table. Initially, your files will have a Sensor Type of \"Unknown\" and a Status of \"Uploaded\". As you work through the import process, the dataset's status will update."),
        h4("Dataset Status"),
        tags$ul(
          tags$li(strong("Uploaded: "), "The files in this dataset have been uploaded, but format information has not been applied yet."),
          tags$li(strong("Format Set: "), "The format for this dataset has been set. Format information includes header row, column delimiter, data columns, and timestamp formats."),
          tags$li(strong("Scanned: "), "The dataset has been scanned to check the format, determine the time period covered, and build a list of unique sensors."),
          tags$li(strong("Locations Set: "), "You've entered location information for the sensors in the dataset. If the columns in the files include latitude and longitude values, this step isn't needed.")
        ),
        p("Once you've set the format for a dataset and ensured that location information is available (either directly from the data files or by entering it manually), you'll be able to apply data flagging rules and export your dataset.")
      ),
      
      nav_panel("Format Wizard",
        h2("Format Wizard"),
        p("The Format Wizard allows you to set the format of your sensor data files. The interface is split into several tabs:"),
        tags$ul(
          tags$li(strong("Known Sensor Types: "), "Load previously saved sensor format information."),
          tags$li(strong("Header Row: "), "Set the header row and column delimiter for the files."),
          tags$li(strong("Columns: "), "Identify the data type and units for the columns in the files."),
          tags$li(strong("Timestamps: "), "Indicate how the timestamps in the data are formatted."),
          tags$li(strong("Summary: "), "Review the format information and optionally save it for re-use."),
          tags$li(strong("Data Check: "), "Scan the full file data and review basic plots of the data.")
        ),
        p("When you first start working with a dataset, you'll start on the ", strong("Known Sensor Types"), " tab. If you've already set up and saved the format information for this sensor type, you can load your saved format information here. Format information is saved as a JSON (JavaScript Object Notation) file with a .json extension; these files are created using the ", strong("Summary"), " tab. If you don't have saved format information, click the ", strong("Header Row"), " tab to get started."),
        p("The ", strong("Header Row"), " tab displays the first 10 lines of your data file. Use the ", em("Header row"), " text field to indicate which row contains the column headers. If your data doesn't have a header, set the ", em("Header row"), " value to zero. The ", em("Column delimiter"), " pull-down menu lets you set the delimiter character used in the data files. Files with a .csv extension will default to comma as the delimiter, and .tsv files default to tab. Available delimiters are comma (,), pipe (|), semicolon (;), space, and tab. Click the ", strong("Next Step"), " button to move on to the next step."),
        p("The ", strong("Columns"), " tab uses information about the header row and column delimiter to detect the individual columns in the data files. Each column has the header name and the first value from the file displayed. For each column, you'll need to set the data type, extension (if applicable), and units. The extension is used if you have multiple columns of the same data type, such as raw and calibrated data. Columns with a data type of \"Unused\" won't be included in the exported output."),
        p("When setting up your columns, keep in mind the following restrictions:"),
        tags$ul(
          tags$li("The data must include a timestamp column."),
          tags$li("The data must have at least one observations column (O3, NO2, CO, PM*, Particle Count, or meteorology data)."),
          tags$li("If either a latitude or longitude column is selected, the data must have both columns."),
          tags$li("The units for each data column must match the allowed units (see the Allowed Units section of the Help page).")
        ),
        p("When you click the ", strong("Next Step"), " button, the importer will check your column configuration, display an error message if needed, or move on to the ", strong("Timestamps"), " tab."),
        p("The ", strong("Timestamps"), " tab displays the first 10 values from the designated timestamp columns. The Air Sensor Data Unifier will auto-detect the components of the timestamp values and show the results in the ", strong("Detected Components"), " section. For each component, review the Component Type and adjust any as needed; for example, your timestamp may need the month and day components switched. Details about the timestamp formats that the Air Sensor Data Unifier can detect are given in the Timestamp Formats section of the Help page."),
        p("If the timestamps in your data file don't include the time zone, set the ", em("Time zone options"), " radio button to \"Use one time zone for all data in files\", and use the ", em("Time zone"), " pull-down menu to set the time zone. Click the ", strong("Next Step"), " button to move on to the ", strong("Summary"), " tab."),
        p("The ", strong("Summary"), " tab allows you to review your configured format information and optionally save it for re-use. For each column, the Column Header, Data Type, Extension, and Units are displayed in a table. To hide unused columns from the table, check the ", em("Hide unused columns"), " checkbox. Below the column information, you have the option to save your sensor format information for re-use. Information entered in the ", em("Sensor type"), " and ", em("Notes about this format"), " text fields will be saved as metadata in the format file. Use the ", em("Filename"), " text field to set the filename; the extension .json will automatically be added to the filename. Click the ", strong("Save Format Information"), " button to download your sensor format information as a JSON file. This file can then be re-used for additional sensor data files by uploading it on the ", strong("Known Sensor Types"), " tab."),
        p("The ", strong("Data Check"), " tab provides an opportunity to review the data found in your sensor files. Click the ", strong("Scan All Data"), " button to initiate a scan of all the records in your selected files. After the scan is complete, the Timestamp Range section will show the starting and ending timestamps found in the sensor data. The Observation Data Values section displays plots of the first 10 sensor data values.")
      ),
      
      nav_panel(HTML("&nbsp;&nbsp;&nbsp;Allowed Units"),
        h2("Allowed Units"),
        p("For each Data Type, the list of allowed units is shown below:"),
        tags$table(class="table table-striped",
          tags$thead(
            tags$tr(
              tags$th("Data Type"),
              tags$th("Allowed Units")
            )
          ),
          tags$tbody(
            tags$tr(
              tags$td("Unused"),
              tags$td("any"),
            ),
            tags$tr(
              tags$td("Sensor ID"),
              tags$td("N/A")
            ),
            tags$tr(
              tags$td("Timestamp"),
              tags$td("N/A")
            ),
            tags$tr(
              tags$td("O3"),
              tags$td("ppb, ppm, ug/m3")
            ),
            tags$tr(
              tags$td("NO2"),
              tags$td("ppb, ppm, ug/m3")
            ),
            tags$tr(
              tags$td("CO"),
              tags$td("ppb, ppm")
            ),
            tags$tr(
              tags$td("PM1"),
              tags$td("ug/m3")
            ),
            tags$tr(
              tags$td("PM2.5"),
              tags$td("ug/m3")
            ),
            tags$tr(
              tags$td("PM10"),
              tags$td("ug/m3")
            ),
            tags$tr(
              tags$td("Particle Count"),
              tags$td("#/cm3, #/m3")
            ),
            tags$tr(
              tags$td("Temperature"),
              tags$td("degrees F, degrees C")
            ),
            tags$tr(
              tags$td("Dew Point"),
              tags$td("degrees F, degrees C")
            ),
            tags$tr(
              tags$td("Humidity"),
              tags$td("%")
            ),
            tags$tr(
              tags$td("Pressure"),
              tags$td("hPa")
            ),
            tags$tr(
              tags$td("Wind Speed"),
              tags$td("m/s, mph")
            ),
            tags$tr(
              tags$td("Wind Direction"),
              tags$td("degrees")
            ),
            tags$tr(
              tags$td("Latitude"),
              tags$td("degrees")
            ),
            tags$tr(
              tags$td("Longitude"),
              tags$td("degrees")
            ),
            tags$tr(
              tags$td("Other"),
              tags$td("any")
            )
          )
        )
      ),
      
      nav_panel(HTML("&nbsp;&nbsp;&nbsp;Timestamp Formats"),
        h2("Timestamp Formats"),
        p("When setting up a new sensor format, the Air Sensor Data Unifier will try to detect the components of any timestamp columns you've indicated. You'll be able to adjust these automatically detected types when setting up your format."),
        h4("Date Components"),
        tags$ul(
          tags$li(code("YYYY-MM-DD"), " or ", code("YYYY/MM/DD")),
          tags$li(code("MM-DD-YYYY"), " or ", code("MM/DD/YYYY")),
          tags$li(code("MM-DD-YY"), " or ", code("MM/DD/YY"))
        ),
        p("If your dates are in Day/Month order, you can switch the auto-detected component types when setting up your format."),
        h4("Time Components"),
        tags$ul(
          tags$li(code("HH:MM"), "(with or without AM/PM indicator)"),
          tags$li(code("HH:MM:SS"), "(with or without AM/PM indicator)"),
          tags$li(code("HH:MM:SS-hhmm")),
          tags$li(code("HH:MM:SS-hh:mm"))
        ),
        p("For times without an AM/PM indicator, hours are assumed to be 24-hour values. Seconds can be specified as an integer, or with a decimal point and milliseconds (e.g. SS.SSS)."),
        p("Date and time components can be specified in a single column, with the date and time separated by a ", code("T"), " or with a space."),
        h4("Example"),
        p("A timestamp like ", code("2021-06-09T11:19:25.000"), " will be auto-detected as having the following fields:"),
        tags$ul(
          tags$li("Year (4 digits)"),
          tags$li("Month"),
          tags$li("Day"),
          tags$li("Hour (24 hours)"),
          tags$li("Minutes"),
          tags$li("Seconds"),
          tags$li("Milliseconds")
        ),
        p("This same timestamp could also be given as ", code("2021/06/09 11:19:25.000"), " or with the date and time in two separate columns.")
      ),
      
      nav_panel("Location Config",
        h2("Location Config"),
        p("The Location Config page displays information about the individual sensors found in your data files. In order to display a complete list of the sensors, your data first needs to be scanned using the ", strong("Scan All Data"), " button in the Format Wizard > Data Check tab."),
        p("The options on the Location Config page depend on which columns are available in your data. If your data includes a Sensor ID column, and Latitude and Longitude columns, the Location Config page will display a table listing each sensor and its location. In this case, no additional location configuration is needed."),
        p("If your data includes a Sensor ID column but not latitude and longitude, the Location Config page will display of list of individual sensors with fields to enter the latitude and longitude for each sensor. After entering the location information, click the ", strong("Save Sensor Information"), " button."),
        p("If your data includes Latitude and Longitude columns but no Sensor ID, the Location Config page will display of list of unique locations with fields to enter the sensor ID for each location. If your data doesn't have sensor IDs or coordinates, the data is assumed to contain observations for a single location, and the Location Config page will allow you to enter the sensor ID and coordinates for that location.")
      ),
      
      nav_panel("Data Flagging",
        h2("Data Flagging"),
        p("The Data Flagging page allows you to set up rules for checking your data, and to specify how those conditions should be handled. You can set up flags for each data column in your dataset's format. Use the ", em("Flags for Data Column"), " pull-down menu to switch between the different data columns."),
        p("There are five data flags that can be applied to each data column:"),
        tags$ul(
          tags$li(strong("Missing value: "), "Check for missing values and either drop the record or replace the missing value."),
          tags$li(strong("Below minimum value: "), "Check for values below the minimum value you specify. Actions for this flag are to drop the record, replace the low value, or just report the condition."),
          tags$li(strong("Above maximum value: "), "Check for values above the maximum value you specify. Like the minimum value flag, the action options are to drop the record, replace the high value, or just report the condition."),
          tags$li(strong("Repeated value: "), "Check for the value repeating a specified number of times. This check looks at the values for the selected data column for each sensor, then checks for repeating values for that sensor when ordered by the timestamp. Records where the value repeats more than the specified number of times can either be dropped or just flagged for reporting."),
          tags$li(strong("Outlier value: "), "Check for values that are more than the specified number of standard deviations away from the mean. This flag is applied on a sensor-by-sensor basis, and considers values across all timestamps when calculating the standard deviation and mean for the sensor. Records where the data value exceeds the threshold can either be dropped or just reported.")
        ),
        p("Each flag has an identifier based on the data column's index (starting with 1) and the flag (letters A through E). This identifier is reported when the flags are applied to your dataset to tell you which flags matched each record."),
        p("Click the ", strong("Apply Flags"), " button to apply the data flags to your dataset. If there are any problems detected in your data, an error will be displayed. Otherwise, scroll down to see a summary of the data flags applied. The Data Flagging Summary will list how many records from the dataset were flagged, how many records would be dropped when the data is exported, and how many records would have replacement values used during export."),
        p("Below the Data Flagging Summary, a table shows you the records from your dataset. The \"flags\" column contains the identifiers of any flags applied to that record. You can select how many entries to show per page, use the Search field to locate values in your dataset, and use the pagination buttons below the table to navigate through the dataset."),
        p("If you'd like to download your dataset with the \"flags\" column, click the ", strong("Download Flagged Data"), " button at the bottom of the page. This will save the data from the table into a CSV file. You can set the file name using the ", em("Flagged Data Filename"), " text field.")
      ),
      
      nav_panel("Export Options",
        h2("Export Options"),
        p("The Export Options page allows you to select how you want your data to be exported and create your exported files. The Air Sensor Data Unifier can export your data in the following formats:"),
        tags$ul(
          tags$li("ASNAT Standard Format File"),
          tags$li("KML (for use in Google Earth or GIS programs)"),
          tags$li("RETIGO")
        ),
        p("Use the ", em("Export format"), " pull-down menu to set your desired format."),
        p("The ", em("Export timestamp"), " pull-down menu sets the averaging period for the exported data. The output options are:"),
        tags$ul(
          tags$li("Raw: No averaging is done."),
          tags$li("Hourly: Values are averaged by hour."),
          tags$li("Daily: Values are averaged by day.")
        ),
        p("Hourly averaging groups together records with the same hour in their timestamp. For instance, the output for the hour \"2022-10-01T07:00:00-0000\" would include records from Oct. 1, 2022 07:00:00 through 07:59:59. For daily averaging, all timestamps from the same day are grouped. So the output for timestamp \"2022-10-01T00:00:00-0000\" would include records from Oct. 1, 2022 00:00:00 through 23:59:59. Note that the timestamps are converted to UTC before the grouping is done."),
        p("The Export Options page displays information about the data flagging rules to be applied. If you've set up your own custom rules, the page will note that. If you want to review or change any data flagging rules, click the ", strong("Go to Data Flagging"), " button to switch to the Data Flagging page."),
        p("Information entered in the ", em("Notes about this data"), " text field will be included in the export log file. The export log file includes the export date, a list of imported files, the name of the exported output file, and any notes provided."),
        p("The ", em("Filename"), " text field allows you to set the name of the exported file when it's downloaded. The appropriate extension will be added based on your selected export format: .tsv for ASNAT Standard Format file, .kml for KML, and .csv for RETIGO. Your entered filename is also used to name the export log file with \"_log.txt\" appended. If you don't enter a filename, the default name \"export\" will be used (e.g. export.tsv, export_log.txt)."),
        p("Click the ", strong("Generate Export Data"), " button to start the export process. If any problems are found with your data, an error message will be displayed. If the generation process is successful, two new buttons will be displayed. Click the ", strong("Export Sensor Data"), " button to download your exported data and click the ", strong("Download Log File"), " button to download the export log file.")
      )
    )
  )
)
