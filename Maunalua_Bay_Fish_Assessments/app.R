#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(leaflet)
library(dplyr)
library(tidyr)
library(ggplot2)
library(bslib)
library(here)
library(tidyverse)


# processing data ---------------------------------------------------------


# Read and process data
mbay_fish <- read.csv(here("data", "Mbay_fish.csv"))
spp.ferl <- read.csv(here("data", "spp_ferl.csv"))

# Create site name lookup
site_names <- c(
  "DHFM" = "Diamond Head FMA",
  "MBAY" = "Maunalua Bay FMA",
  "HBAY" = "Hanauma Bay MLCD",
  "WIKI" = "Waikiki MLCD"
)

# Format the species filters
mbay_fish$bio_line_gm2[mbay_fish$use4biomass == 0] <- 0

# Add Family column
mbay_fish <- mbay_fish %>% 
  left_join(spp.ferl %>% select(Taxon, Family, Consumer), by = "Taxon")

# Calculate sum by Family biomass per transect, including zeros
fish_sum_0 <- mbay_fish %>% 
  group_by(Site, Year, SurveyID, Habitat_Category, Rugosity, Depth, Family) %>% 
  summarise(biomass = sum(bio_line_gm2), .groups = "drop") %>%
  pivot_wider(names_from = Family, values_from = biomass, values_fill = 0) %>%
  pivot_longer(cols = c(Acanthuridae, Labridae, Scaridae),
               names_to = "Family",
               values_to = "Biomass") %>% 
  select(Site, Year, SurveyID, Habitat_Category, Rugosity, Depth, Family, Biomass) %>% 
  ungroup() %>%
 # add depth bins
   mutate(
    Depth_Bin = case_when(
      Depth < 10 ~ "Shallow (0-10m)",
      Depth >= 10 & Depth < 20 ~ "Mid (10-20m)",
      Depth >= 20 ~ "Deep (20m+)",
      TRUE ~ NA_character_
    ),
    # clean up the habitat names
    Habitat_Display = gsub("_", " ", Habitat_Category)
  )

# Site summary for habitat
site_sum_hab <- fish_sum_0 %>% 
  group_by(Site, Year, Habitat_Category, Habitat_Display, Family, Depth_Bin) %>% 
  summarise(mean_biomass = mean(Biomass, na.rm = TRUE),
            sd_biomass = sd(Biomass, na.rm = TRUE),
            .groups = "drop")

# Site summary for rugosity
site_sum_rug <- fish_sum_0 %>% 
  filter(!is.na(Rugosity)) %>%  # Remove NA rugosity values
  group_by(Site, Year, Rugosity, Family, Depth_Bin) %>% 
  summarise(mean_biomass = mean(Biomass, na.rm = TRUE),
            sd_biomass = sd(Biomass, na.rm = TRUE),
            .groups = "drop")

# Create transect location data (unique GPS points per transect)
transect_data <- mbay_fish %>%
  filter(!is.na(Rugosity)) %>%  # Remove NA rugosity values
  select(Site, SurveyID, Habitat_Category, Rugosity, Latitude, Longitude, Depth) %>%
  distinct() %>%
  mutate(
    Depth_Bin = case_when(
      Depth < 10 ~ "Shallow (0-10m)",
      Depth >= 10 & Depth < 20 ~ "Mid (10-20m)",
      Depth >= 20 ~ "Deep (20m+)",
      TRUE ~ NA_character_
    ),
    Habitat_Display = gsub("_", " ", Habitat_Category)
  )

# Get unique values for filters
sites <- unique(fish_sum_0$Site)
site_choices <- setNames(sites, site_names[sites])  # Named vector for display
years <- unique(fish_sum_0$Year)
families <- c("Acanthuridae", "Labridae", "Scaridae")
depth_bins <- c("Shallow (0-10m)", "Mid (10-20m)", "Deep (20m+)")


# UI ----------------------------------------------------------------------


# UI
ui <- page_navbar(
  title = "Oahu Fish & Benthic Assessments",
  theme = bs_theme(bootswatch = "flatly"),
  
  # make buttons on the top to changes to 3 pages
  nav_panel(
    "Transect Map",
    layout_sidebar(
      sidebar = sidebar(
        width = 250,
        selectInput("map_category", "Display Category:",
                    choices = c("Habitat Type" = "Habitat_Category", 
                                "Rugosity Type" = "Rugosity")),
        checkboxGroupInput("map_sites", "Filter by Site:",
                           choices = site_choices,
                           selected = sites),
        selectInput("map_year", "Filter by Year:",
                    choices = c("All Years", years),
                    selected = "All Years"),
        checkboxGroupInput("map_depth", "Filter by Depth:",
                           choices = depth_bins,
                           selected = depth_bins)
      ),
      leafletOutput("map", height = "600px")
    )
  ),
  
  nav_panel(
    "Biomass by Habitat",
    layout_sidebar(
      sidebar = sidebar(
        width = 250,
        checkboxGroupInput("habitat_families", "Fish Families:",
                           choices = families,
                           selected = families),
        checkboxGroupInput("habitat_sites", "Filter by Site:",
                           choices = site_choices,
                           selected = sites),
        selectInput("habitat_year", "Filter by Year:",
                    choices = c("All Years", years),
                    selected = "All Years"),
        checkboxGroupInput("habitat_depth", "Filter by Depth:",
                           choices = depth_bins,
                           selected = depth_bins)
      ),
      plotOutput("habitat_plot", height = "600px"),
      verbatimTextOutput("habitat_n")
    )
  ),
  
  nav_panel(
    "Biomass by Rugosity",
    layout_sidebar(
      sidebar = sidebar(
        width = 250,
        checkboxGroupInput("rugosity_families", "Fish Families:",
                           choices = families,
                           selected = families),
        checkboxGroupInput("rugosity_sites", "Filter by Site:",
                           choices = site_choices,
                           selected = sites),
        selectInput("rugosity_year", "Filter by Year:",
                    choices = c("All Years", years),
                    selected = "All Years"),
        checkboxGroupInput("rugosity_depth", "Filter by Depth:",
                           choices = depth_bins,
                           selected = depth_bins)
      ),
      plotOutput("rugosity_plot", height = "600px"),
      verbatimTextOutput("rugosity_n")
    )
  )
)

# server ------------------------------------------------------------------

server <- function(input, output, session) {
  
  # Reactive data for map
  map_data <- reactive({
    data <- transect_data %>%
      filter(Site %in% input$map_sites,
             Depth_Bin %in% input$map_depth)
    
    # Default to all years
    if(input$map_year != "All Years") {
      data <- data %>%
        filter(SurveyID %in% (fish_sum_0 %>% 
                                filter(Year == as.numeric(input$map_year)) %>% 
                                pull(SurveyID)))
    }
    
    data
  })
  
  # Leaflet map
  output$map <- renderLeaflet({
    data <- map_data()
    
    # Color palette based on selected category
    if(input$map_category == "Habitat_Category") {
      categories <- unique(data$Habitat_Category)
      display_categories <- unique(data$Habitat_Display)
      pal <- colorFactor(palette = "Set2", domain = categories)
      # Create a palette function that maps to display names
      pal_display <- colorFactor(palette = "Set2", domain = display_categories)
      legend_title <- "Habitat Type"
      legend_values <- data$Habitat_Display
      use_habitat <- TRUE
    } else {
      categories <- unique(data$Rugosity)
      pal <- colorFactor(palette = "YlOrRd", domain = categories)
      legend_title <- "Rugosity Type"
      legend_values <- data$Rugosity
      use_habitat <- FALSE
    }
    
    leaflet(data, options = leafletOptions(maxZoom = 19)) %>%
      addProviderTiles(providers$Esri.WorldImagery, 
                       options = providerTileOptions(maxZoom = 18, maxNativeZoom = 18)) %>%
      addCircleMarkers(
        lng = ~Longitude,
        lat = ~Latitude,
        color = ~pal(get(input$map_category)),
        fillOpacity = 0.8,
        radius = 8,
        stroke = TRUE,
        weight = 2,
        popup = ~paste0(
          "<strong>Site:</strong> ", site_names, "<br>",
          "<strong>Transect:</strong> ", SurveyID, "<br>",
          "<strong>Habitat:</strong> ", Habitat_Display, "<br>",
          "<strong>Rugosity:</strong> ", Rugosity, "<br>",
          "<strong>Depth:</strong> ", round(Depth, 1), "m (", Depth_Bin, ")"
        )
      ) %>%
      addScaleBar(position = "bottomleft",
                  options = scaleBarOptions(imperial = FALSE)) %>%
      addLegend(
        position = "bottomright",
        pal = if(use_habitat) pal_display else pal,
        values = legend_values,
        title = legend_title,
        opacity = 1
      )
  })
  
  # Reactive data for habitat plot
  habitat_data <- reactive({
    data <- site_sum_hab %>%
      filter(Family %in% input$habitat_families,
             Site %in% input$habitat_sites,
             Depth_Bin %in% input$habitat_depth)
    
    if(input$habitat_year != "All Years") {
      data <- data %>% filter(Year == as.numeric(input$habitat_year))
    }
    
    data
  })
  
  # Habitat biomass plot
  output$habitat_plot <- renderPlot({
    data <- habitat_data()
    
    # Meat of boxplot
    ggplot(data, aes(x = Habitat_Display, y = mean_biomass, fill = Family)) +
      geom_boxplot(position = position_dodge(0.8)) +
      scale_fill_manual(values = c("#2E86AB", "#A23B72", "#F18F01")) +
      labs(title = "Fish Biomass by Habitat Type",
           x = "Habitat Category",
           y = "Mean Biomass (g/m²)",
           fill = "Fish Family") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "bottom",
            plot.title = element_text(hjust = 0.5, face = "bold", size = 18),
            axis.text.x = element_text(angle = 45, hjust = 1))
  })
  
  # Habitat sample size text
  output$habitat_n <- renderText({
    # Get raw transect data with filters applied
    raw_data <- fish_sum_0 %>%
      filter(Family %in% input$habitat_families,
             Site %in% input$habitat_sites,
             Depth_Bin %in% input$habitat_depth)
    
    if(input$habitat_year != "All Years") {
      raw_data <- raw_data %>% filter(Year == as.numeric(input$habitat_year))
    }
    
    # Count unique transects per habitat
    n_summary <- raw_data %>%
      group_by(Habitat_Display) %>%
      summarise(n = n_distinct(SurveyID), .groups = "drop") %>%
      arrange(Habitat_Display)
    
    # Format output
    paste0("Sample sizes (n = number of transects):\n",
           paste(n_summary$Habitat_Display, ": n =", n_summary$n, collapse = "\n"))
  })
  
  # Reactive data for rugosity plot
  rugosity_data <- reactive({
    data <- site_sum_rug %>%
      filter(Family %in% input$rugosity_families,
             Site %in% input$rugosity_sites,
             Depth_Bin %in% input$rugosity_depth)
    
    if(input$rugosity_year != "All Years") {
      data <- data %>% filter(Year == as.numeric(input$rugosity_year))
    }
    
    data
  })
  
  # Rugosity biomass plot
  output$rugosity_plot <- renderPlot({
    data <- rugosity_data()
    
    ggplot(data, aes(x = Rugosity, y = mean_biomass, fill = Family)) +
      geom_boxplot(position = position_dodge(0.8)) +
      scale_fill_manual(values = c("#2E86AB", "#A23B72", "#F18F01")) +
      labs(title = "Fish Biomass by Rugosity Type",
           x = "Rugosity Type",
           y = "Mean Biomass (g/m²)",
           fill = "Fish Family") +
      theme_minimal(base_size = 14) +
      theme(legend.position = "bottom",
            plot.title = element_text(hjust = 0.5, face = "bold", size = 18))
  })
  
  # Rugosity sample size text
  output$rugosity_n <- renderText({
    # Get raw transect data with filters applied
    raw_data <- fish_sum_0 %>%
      filter(Family %in% input$rugosity_families,
             Site %in% input$rugosity_sites,
             Depth_Bin %in% input$rugosity_depth,
             !is.na(Rugosity))  # Exclude NA rugosity)
              
    
    if(input$rugosity_year != "All Years") {
      raw_data <- raw_data %>% filter(Year == as.numeric(input$rugosity_year))
    }
    
    # Count unique transects per rugosity
    n_summary <- raw_data %>%
      group_by(Rugosity) %>%
      summarise(n = n_distinct(SurveyID), .groups = "drop") %>%
      arrange(Rugosity)
    
    # Format output
    paste0("Sample sizes (n = number of transects):\n",
           paste(n_summary$Rugosity, ": n =", n_summary$n, collapse = "\n"))
  })
}


# shinyApp ----------------------------------------------------------------


shinyApp(ui = ui, server = server)