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
library(purrr)
library(plyr)

format(lubridate::floor_date(Sys.time(), "30 minutes"), "%Y%m%d%H%M")
security_token <- "c48428c5-69ed-42d8-bb65-271b18972769"
domain <- "10Y1001A1001A82H"
period_start <- format(lubridate::floor_date(Sys.time() - days(364), "60 minutes"), "%Y%m%d%H%M")
period_end <- format(lubridate::floor_date(Sys.time(), "60 minutes"), "%Y%m%d%H%M")

url <- paste0("https://web-api.tp.entsoe.eu/api?securityToken=", security_token, "&documentType=A44&in_Domain=", domain, "&out_Domain=", domain, "&periodStart=", period_start, "&periodEnd=", period_end)

xml_main <- as_list(read_xml(url))


dt <- as.data.table(xml_main)
dt <- dt[, list(list_column = as.character(unlist(Publication_MarketDocument)), by = "Price")]
df3 <- as.data.frame(dt[, 1])
colnames(df3) <- c("Price")
df3
df3$Price <- str_extract(df3$Price, c("\\d+\\.+\\d"))
df3 <- drop_na(df3)

df3$Price <- as.numeric(df3$Price) / 1000

trial <- data.frame(
    Price <- quantile(df3$Price, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE)
)

trial$Technology <- "Mixed"


colnames(trial) <- c("Price", "Technology")

LCOE <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/LCOE.xlsx")



LCOE <- rbind(LCOE, trial)

LCOE$Technology_Key <- 1:nrow(LCOE)

LCOE_dim <- LCOE