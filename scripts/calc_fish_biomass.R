library(dplyr)
library(tidyr)
library(here)
library(tidyverse)

# read in fish data
mbay_fish <- read.csv(here("data","Mbay_fish.csv"))
head(mbay_fish)

# check the sample sizes
mbay_fish %>% distinct(Site, SurveyID) %>% group_by(Site) %>% tally()

# format the species filters
mbay_fish$bio_line_gm2[mbay_fish$use4biomass==0] <- 0 #dont include these species in biomass estimates
spp.ferl <- read.csv(here("data","spp_ferl.csv")) #read in a species table to link to Family
mbay_fish <- mbay_fish %>% left_join(spp.ferl %>% select(Taxon,Family,Consumer)) #add a column for Family to the dataset and link it (join) using Taxon

# calculate the sum by Family biomass per transect, including zeros

fish_sum_0 <- mbay_fish %>% 
  group_by(Site,Year,SurveyID,Habitat_Category,Rugosity,Depth,Family) %>% 
  summarise("biomass"=sum(bio_line_gm2)) %>% ungroup() %>% #sum the biomass for every family and every transect
  pivot_wider(names_from = Family,values_from = biomass,values_fill = 0) %>% #pivot so that each family becomes a column and fill in zeros
  pivot_longer(cols = c(Acanthuridae, Labridae, Scaridae), #pivot to longer so you can plot easier
               names_to = "Family",
               values_to = "Biomass") %>% 
select(Site,Year,SurveyID,Habitat_Category,Rugosity,Depth,Family,Biomass) %>% 
  ungroup()
 
# site summary for habitat
  site_sum_hab <- fish_sum_0 %>% 
   group_by(Site,Year, Habitat_Category, Family) %>% 
summarise(mean_biomass = mean(Biomass, na.rm=TRUE),
          sd_biomass = sd(Biomass, na.rm = TRUE)) %>% 
  ungroup()
  
  #site summary for rugosity
  site_sum_rug <- fish_sum_0 %>% 
    group_by(Site,Year, Rugosity, Family) %>% 
    summarise(mean_biomass = mean(Biomass, na.rm=TRUE),
              sd_biomass = sd(Biomass, na.rm = TRUE)) %>% 
    ungroup()
 
   #make a plot
 site_sum_hab %>%  
 ggplot(aes(x = Habitat_Category, y = mean_biomass, fill = Family)) +
  geom_boxplot()

 site_sum_rug %>%  
   ggplot(aes(x = Rugosity, y = mean_biomass, fill = Family)) +
   geom_boxplot()
 
 