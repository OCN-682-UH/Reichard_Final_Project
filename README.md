
# Reichard_Final_Project

Final project for OCN-682 created by Jake Reichard.

# Introduction

The Division of Aquatic Resources (DAR) conducted 313 transects from
October 2024 to January 2025. Transects were 5m x 25m and encompassed
fish and benthic surveys.

# Data Dictionary

## Overview

This document describes the data structure and variables used in the
Oahu Fish & Benthic Transect Analysis Shiny application. The application
analyzes fish biomass and benthic habitat characteristics across four
coastal sites in Oahu, Hawaii.

View the [interactive
application](https://jakereichard.shinyapps.io/maunalua_bay_fish_assessments/).

## Input Data Files

### 1. Mbay_fish.csv

The data is exported from the DAR Marine Database. The raw fish survey
data containing species observations and biomass measurements. The
database export had extra information not used for the app. The
following table lays out all the data used for this project.

| Variable | Type | Description |
|----|----|----|
| `Site` | Character | Site code (DHFM, MBAY, HBAY, WIKI) |
| `Year` | Numeric | Year of survey |
| `SurveyID` | Character | Unique identifier for each transect |
| `Taxon` | Character | Scientific name of fish species |
| `bio_line_gm2` | Numeric | Fish biomass in grams per square meter |
| `use4biomass` | Numeric | Flag (0/1) indicating whether species should be included in biomass calculations |
| `Habitat_Category` | Character | Benthic habitat classification (e.g., Coral_Reef, Mixed_Substrate) |
| `Rugosity` | Character | Substrate complexity category (Low, Medium, High) |
| `Latitude` | Numeric | GPS latitude coordinate (decimal degrees) |
| `Longitude` | Numeric | GPS longitude coordinate (decimal degrees) |
| `Depth` | Numeric | Water depth in meters |

### 2. spp_ferl.csv

Species reference table linking taxonomic information to functional
groups.

| Variable   | Type      | Description                                         |
|------------|-----------|-----------------------------------------------------|
| `Taxon`    | Character | Scientific name of fish species                     |
| `Family`   | Character | Taxonomic family (Acanthuridae, Labridae, Scaridae) |
| `Consumer` | Character | Trophic/functional group classification             |

## Processed Data Structures

### fish_sum_0

Family-level biomass summarized by transect with zeros added for missing
families.

| Variable | Type | Description |
|----|----|----|
| `Site` | Character | Site code |
| `Year` | Numeric | Survey year |
| `SurveyID` | Character | Transect identifier |
| `Habitat_Category` | Character | Original habitat name with underscores |
| `Habitat_Display` | Character | Habitat name formatted for display (spaces instead of underscores) |
| `Rugosity` | Character | Substrate complexity category |
| `Depth` | Numeric | Depth in meters |
| `Depth_Bin` | Character | Depth category (Shallow 0-10m, Mid 10-20m, Deep 20m+) |
| `Family` | Character | Fish family name |
| `Biomass` | Numeric | Total biomass (g/m²) for that family on that transect |

### site_sum_hab

Mean biomass by site, year, habitat, and family.

| Variable           | Type      | Description                          |
|--------------------|-----------|--------------------------------------|
| `Site`             | Character | Site code                            |
| `Year`             | Numeric   | Survey year                          |
| `Habitat_Category` | Character | Original habitat classification      |
| `Habitat_Display`  | Character | Display-formatted habitat name       |
| `Family`           | Character | Fish family                          |
| `Depth_Bin`        | Character | Depth category                       |
| `mean_biomass`     | Numeric   | Mean biomass (g/m²) across transects |
| `sd_biomass`       | Numeric   | Standard deviation of biomass        |

### site_sum_rug

Mean biomass by site, year, rugosity, and family.

| Variable       | Type      | Description                          |
|----------------|-----------|--------------------------------------|
| `Site`         | Character | Site code                            |
| `Year`         | Numeric   | Survey year                          |
| `Rugosity`     | Character | Substrate complexity                 |
| `Family`       | Character | Fish family                          |
| `Depth_Bin`    | Character | Depth category                       |
| `mean_biomass` | Numeric   | Mean biomass (g/m²) across transects |
| `sd_biomass`   | Numeric   | Standard deviation of biomass        |

### transect_data

Unique GPS locations and characteristics for each transect.

| Variable           | Type      | Description                     |
|--------------------|-----------|---------------------------------|
| `Site`             | Character | Site code                       |
| `SurveyID`         | Character | Transect identifier             |
| `Habitat_Category` | Character | Original habitat classification |
| `Habitat_Display`  | Character | Display-formatted habitat name  |
| `Rugosity`         | Character | Substrate complexity            |
| `Latitude`         | Numeric   | GPS latitude                    |
| `Longitude`        | Numeric   | GPS longitude                   |
| `Depth`            | Numeric   | Depth in meters                 |
| `Depth_Bin`        | Character | Depth category                  |

## Site Code Reference

| Code | Full Name        |
|------|------------------|
| DHFM | Diamond Head FMA |
| MBAY | Maunalua Bay FMA |
| HBAY | Hanauma Bay MLCD |
| WIKI | Waikiki MLCD     |

*FMA = Fisheries Management Area; MLCD = Marine Life Conservation
District*

## Fish Family Reference

The analysis focuses on three herbivorous fish families:

-   **Acanthuridae** - Surgeonfishes and tangs
-   **Labridae** - Wrasses
-   **Scaridae** - Parrotfishes

## Habitat Categories

Benthic habitat classifications based on substrate composition and coral
coverage. Examples include: - Coral_Reef - Mixed_Substrate -
Pavement_Scattered_Coral - Aggregate_Reef - Sand

*Note: Underscores in habitat names are replaced with spaces for display
purposes.*

## Rugosity Categories

Substrate structural complexity classifications: - **Low** - Relatively
flat, low relief - **Medium** - Moderate structural complexity -
**High** - High structural complexity with many crevices

## Depth Bins

Depth categories created from continuous depth measurements: - **Shallow
(0-10m)** - 0 to \<10 meters - **Mid (10-20m)** - 10 to \<20 meters -
**Deep (20m+)** - 20 meters and deeper

## Data Processing Notes

1.  **Zero-filling**: Species not observed on a transect are assigned a
    biomass of 0 (rather than being omitted) to ensure accurate mean
    calculations.

2.  **Exclusions**:

    -   Species with `use4biomass = 0` are excluded from biomass
        calculations
    -   Transects with `NA` rugosity values are excluded from rugosity
        analyses

3.  **Aggregation**: Individual fish observations are summed by family
    for each transect before calculating site-level means.

4.  **Units**: All biomass measurements are in grams per square meter
    (g/m²).
