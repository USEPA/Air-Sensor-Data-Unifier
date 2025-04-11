---
title: 'Air Sensor Data Unifier: R-Shiny application'
tags:
  - R
  - Air Quality
  - Quality Control
  - Open source
  - Visualization
date: "2 April 2025"
output: pdf_document
authors:
  - name: Karoline K. Barkjohn
    orcid: 0000-0001-6197-4499
    corresponding: true 
    affiliation: 1     
  - name: Catherine Seppanen
    affiliation: 2
    orcid: 0009-0000-0756-670X  
  - name: Saravanan Arunachalam
    affiliation: 2
  - name: Stephen Krabbe
    affiliation: 3  
  - name: Corey Mocka 
    affiliation: 4    
    orcid: 0000-0002-6836-6944    
  - name: Andrea Clements
    affiliation: 1
    orcid: 0000-0003-0764-5584
bibliography: paper.bib
affiliations:
 - name: United States Environmental Protection Agency Office of Research and Development, United States of America
   index: 1
 - name: Institute for the Environment, The University of North Carolina at Chapel Hill, NC, United States of America
   index: 2
 - name: United States Environmental Protection Agency Region 7, United States of America
   index: 3
 - name: United States Environmental Protection Agency Office of Air Quality Planning and Standards, United States of America
   index: 4
---

## Summary

We developed an R-Shiny application that allows users to import text-based air sensor data, define the format of that data, do basic quality control, and export the data to standard formats. Format information can be saved for re-use to speed up processing of additional sensors of the same type.

## Statement of need

Poor air quality contributes to the burden of disease globally [@RN1]. Air quality measurements are critical to adequately protect health [@RN2; @RN3]. In addition to conventional air monitors, air sensors are widely used for a variety of applications [@RN4; @RN5]. These sensors are often lower in cost and require less maintenance than conventional monitors allowing them to be deployed by more users. Raw data reported by these networks can have issues that require careful analysis to produce credible processed data [@RN6]. Analyzing a wide variety of datasets can be challenging due to large data volume, variable formats, and unique features and issues requiring extensive data analysis skills.

## Overview

The Air Sensor Data Unifier (ASDU) in an R-Shiny application [@RN7; @RN8] including a dataset dashboard, format wizard, data check, data flagging, and export functionality.

## Dataset Dashboard

The Dataset Dashboard allows users to upload raw air sensor data files (Figure 1). It works with comma-separated values, tab-separated values, and plain text files. Files uploaded together should be of the same format.

![Dataset dashboard where batches of air sensor data can be loaded.](Figure1.png)

## Format Wizard

Users can describe the format of their sensor data files. The first (optional) step is to define the data header row. Next, the user can identify the data type and units for the data in each column and the timestamp formatting. When setting up a new sensor format, ASDU will try to detect the components of any timestamp column(s) and the user can adjust them as needed and specify time zone (Figure 2). Finally, the user can save the format information as a JavaScript Object Notation (JSON) file to be used in future runs with data of the same format.

![Format wizard timestamp formatting.](Figure2.png)

## Data Flagging 

Flags can be set up for each data column in the dataset (Figure 3). There are five data flags that can be applied: 1) handling of a missing value, 2) below minimum value, 3) above maximum value, 4) repeated value, and 5) outlier value by user-specified number of standard deviations away from the mean. Each flag has an identifier that is reported in a new “flags” column. The Data Flagging Summary will list how many records from the dataset were flagged, and how many records will be dropped and replaced when the data is exported. The user can export the dataset with or without the flagged data.

![Data Flagging functionality including the ability to apply flags and then see how much data and which points will be removed.](Figure3.png)

## Export Options 

ASDU can export data in the following formats: the Air Sensor Network Analysis Tool (ASNAT) Standard Format File [@RN9], Keyhole Markup Language (KML) (for use in Google Earth or Geographic Information System (GIS) programs), and the format used by Real Time Geospatial Data Viewer (RETIGO) (https://www.epa.gov/hesc/real-time-geospatial-data-viewer-retigo, last accessed February 20, 2025). The current output averaging options are “raw” where no averaging is done, "hourly”, or “daily” (currently 24-hour averages in UTC). This allows sensor data to be reformatted and used for a variety of applications.

## Limitations

• The tool currently works with datasets with one row of data (any number of columns) per timestamp and data associated by column (e.g., PM2.5 data in column X). 

• The data must include a timestamp column and at least one observation column (ozone (O3), nitrogen dioxide (NO2), carbon monoxide (CO), particulate matter (PM), particle count, or meteorology data).

## Acknowledgements

EPA internal funding supported this work. Thank you to those who provided input, example datasets, and testing including: US EPA Amara Holder (ORD), Megan MacDonald (ORD), Ryan Brown (Region 4), Daniel Garver (R4), Chelsey Laurencin (R4), Rachel Kirpes (R5), Dena Vallano (R9), Laura Barry (R9), Nicole Briggs (R10), and Elizabeth Good (OAQPS); South Coast Air Quality Management District Wilton Mui, Vasileios Papapostolou, Randy Lam, Namrata Shanmukh Panji, Ashley Collier-Oxandale (former); Washington Department of Ecology Nate May; Puget Sound Clean Air Agency Graeme Carvlin; and New Jersey Department of Environmental Protection Luis Lim; and Desert Research Institute: Jonathan Callahan. Thank you to Sedona Ryan (UNC) and Eliodora Chamberlain (EPA R7). 

## Disclaimer

The views expressed in this paper are those of the author(s) and do not necessarily represent the views or policies of the US EPA. Any mention of trade names, products, or services does not imply an endorsement by the US Government or the US EPA. The EPA does not endorse any commercial products, services, or enterprises.

## References
