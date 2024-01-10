### create dataset for input in Power BI to calculate levelised cost of hydrogen (LCOH)
### total LCOH may not be calculated since the price for electricity is based on real-time data that is stored within Power BI
### split dataset by electrolyser to calculate quantiles of each input parameter for LCOH by electrolyser by quantile and reappend datasets for ease of calculation
### Import necessary libraries

library(readxl)
library(dplyr) 
library(data.table)
library(jsonlite)
library(lubridate)
library(XML)
library(methods)
library(xml2)
library(tidyverse)
library(reshape)
library(readxl)
### Import dataset from OneDrive
dataset <- read_xlsx('C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/Lit_Ref.xlsx')
###

dataset

colnames(dataset)

Electrolysis_ref <- dataset[, c(1,2,3,4,7,8,9)]

Electrolysis_ref <- as.data.frame(Electrolysis_ref)
Electrolysis_ref <- melt(Electrolysis_ref, id = c("Electrolysis_Author", "Electrolysis_Pub_Year", "Electrolysis_DOI", "Electrolysis_Technology"))
Electrolysis_ref$Process <- "Electrolysis"
Electrolysis_ref$State <- "cH2"

head(Electrolysis_ref)


colnames(Electrolysis_ref) <- c("Author", "Year", "DOI", "Technology", "Category", "Value", "Process", "State")
head(Electrolysis_ref)

storage_ref <- as.data.frame(dataset[, c(10,11,13,14,15,16)])


storage_ref <- melt(storage_ref, id = c("Storage_Author", "Storage_Pub_Year", "Storage_DOI", "Storage_Technology", "Storage_State"))
storage_ref$Process <- "Storage"
colnames(storage_ref) <- c("Author", "Year", "DOI", "Technology", "State", "Category", "Value", "Process")



conversion_ref <- as.data.frame(dataset[, 18:23])

colnames(conversion_ref)

conversion_ref <- melt(conversion_ref, id = c("Conversion_Author", "Conversion_Pub_Year", "Conversion_DOI", "Conversion_Technology", "Conversion_Output_State"))
conversion_ref$Process <- "Conversion"
colnames(conversion_ref) <- c("Author", "Year", "DOI", "Technology", "State", "Category", "Value", "Process")


transport_ref <- dataset[, 24:29]
colnames(transport_ref)
transport_ref <- melt(transport_ref, id = c("Transport_Author", "Transport_Pub_Year", "Transport_DOI", "Transport_Technology", "Transport_State"))
transport_ref$process <- "Transport"
colnames(transport_ref) <- c("Author", "Year", "DOI", "Technology", "State", "Category", "Value", "Process")

main <- rbind(Electrolysis_ref,storage_ref,conversion_ref,transport_ref )



main <- drop_na(main)
main <- main %>%
  group_by(Category) %>%
  mutate(normalised = (Value - min(Value))/(max(Value)-min(Value)))

colnames(main)
Literature <- as.data.frame(main)

Literature <- melt(Literature, id = c("Author", "Year", "DOI", "Technology", "Category", "Process", "State"))