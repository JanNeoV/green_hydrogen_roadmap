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
dataset <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Diplomarbeit/Literatur/Lit_Ref.xlsx")


df <- dataset[, 1:4] ### filter main dataset to get only necessary columns for calculation
quants <- c(seq(0, 1, 1 / 4)) ### define quantiles

colnames(df)
###  split dataset by electrolyser
X <- df[df$Electrolysis_Technology == "SOE", ]
Y <- df[df$Electrolysis_Technology == "AE", ]
Z <- df[df$Electrolysis_Technology == "PEM", ]

### calculate quantiles for each input component: CapEx, Energy Demand, Capacity
X <- as.data.frame(apply(X[2:4], 2, quantile, probs = quants, na.rm = TRUE))
Y <- as.data.frame(apply(Y[2:4], 2, quantile, probs = quants, na.rm = TRUE))
Z <- as.data.frame(apply(Z[2:4], 2, quantile, probs = quants, na.rm = TRUE))



### crossjoin quantiles to account for each possible combination
X <- as.data.frame(CJ(X$`CapEx_[€/kW]`, X$`Electrolysis_Energy_Demand_[kWh/kg]`, X$`Capacity_[kW]`))
Y <- as.data.frame(CJ(Y$`CapEx_[€/kW]`, Y$`Electrolysis_Energy_Demand_[kWh/kg]`, Y$`Capacity_[kW]`))
Z <- as.data.frame(CJ(Z$`CapEx_[€/kW]`, Z$`Electrolysis_Energy_Demand_[kWh/kg]`, Z$`Capacity_[kW]`))


### rename columns
X$Elektrolyseur <- 1
Y$Elektrolyseur <- 2
Z$Elektrolyseur <- 3


### append datasets
df1 <- rbind(X, Y, Z)


### rename columns
colnames(df1) <- c("CapEx_[€/kW]", "Electrolysis_Energy_Demand_[kWh/kg]", "Capacity_[kW]", "Electrolyser")

### calculate initial investment cost
df1$Invest <- df1$`CapEx_[€/kW]` * df1$`Capacity_[kW]`

################
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


LCOE <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Diplomarbeit/Literatur/LCOE.xlsx")


LCOE <- rbind(LCOE, trial)

LCOE$Technology_Key <- 1:nrow(LCOE)

LCOE_dim <- LCOE

LCOE <- LCOE[, 2:3]

LCOE$merger <- 1
df1$merger <- 1
df1 <- merge(x = df1, y = LCOE, by = "merger", all = TRUE)


FLH <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Diplomarbeit/Literatur/FLH.xlsx")

FLH$merger <- 1

Electrolysis <- merge(x = df1, y = FLH, by = "merger", all = TRUE)

Electrolysis$Quantity_H2_kg <- (Electrolysis$`Capacity_[kW]` * Electrolysis$FLH) / Electrolysis$`Electrolysis_Energy_Demand_[kWh/kg]`
Electrolysis$Opex <- Electrolysis$`Electrolysis_Energy_Demand_[kWh/kg]` * Electrolysis$Quantity_H2_kg * Electrolysis$Price



LCOH <- function(x, output) {
    Invest <- as.numeric(x[6])

    OpEx <- as.numeric(x[11])

    Quantity <- as.numeric(x[10])

    return((Invest + sum(OpEx / (1.04)^(1:20))) / (Quantity * 20))
}

Electrolysis$LCOH <- apply(Electrolysis, 1, LCOH)
Electrolysis

Electrolysis_main <- Electrolysis %>%
    group_by(Electrolyser) %>%
    mutate(
        Q0 = quantile(LCOH, probs = 0, na.rm = TRUE),
        Q25 = quantile(LCOH, probs = 0.25, na.rm = TRUE),
        Q50 = quantile(LCOH, probs = 0.5, na.rm = TRUE),
        Q75 = quantile(LCOH, probs = 0.75, na.rm = TRUE),
        Q100 = quantile(LCOH, probs = 1, na.rm = TRUE)
    ) %>%
    distinct(Q0, Q25, Q50, Q75, Q100)


Electrolysis_main <- melt(data.table(Electrolysis_main), id = c("Electrolyser"))