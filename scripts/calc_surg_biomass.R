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

# calculate the sum of surgeonfish biomass per transect, including zeros
surgeon_sum <- mbay_fish %>% 
  group_by(Site,Year,SurveyID,Habitat_Category,Rugosity,Depth,Family) %>% 
  summarise("biomass"=sum(bio_line_gm2)) %>% ungroup() %>% #sum the biomass for every family and every transect
  pivot_wider(names_from = Family,values_from = biomass,values_fill = 0) %>% #pivot so that each family becomes a column and fill in zeros
  #select(Site,Year,SurveyID,Habitat_Category,Rugosity,Depth)#Acanthuridae) %>% #only keep the metadata and the surgeonfish column 
  ungroup() 
