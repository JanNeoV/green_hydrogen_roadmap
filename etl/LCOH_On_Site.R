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
dataset <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/Lit_Ref.xlsx")


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
security_token <- "103430d5-c297-444d-915f-50d505bf639a"
domain <- "10Y1001A1001A82H"
period_start <- format(lubridate::floor_date(Sys.time() - days(364), "60 minutes"), "%Y%m%d%H%M")
period_end <- format(lubridate::floor_date(Sys.time(), "60 minutes"), "%Y%m%d%H%M")

url <- paste0("https://transparency.entsoe.eu/api?securityToken=", security_token, "&documentType=A44&in_Domain=", domain, "&out_Domain=", domain, "&periodStart=", period_start, "&periodEnd=", period_end)



# xml_main <- as_list(read_xml(url))
#
#
# xml_df = tibble::as_tibble(xml_main) %>%
#   unnest_longer(Publication_MarketDocument)
#
# xml_prep = xml_df %>%
#   dplyr::filter(Publication_MarketDocument_id == "Period") %>%
#   unnest_wider(Publication_MarketDocument)
#
# xml_unnest = xml_prep %>%
#
#   unnest(cols = names(.)) %>%
#
#   unnest(cols = names(.)) %>%
#
#   unnest(cols = names(.)) %>%
#   readr::type_convert()
#
#
#
#
# df2 <- as.data.frame(xml_unnest)
#
# df2
#
# df2 <- df2[-seq(1,nrow(df2),by=2),]
# df2 <- df2[,-c(2,27)]
#
# df2
# my.result <- melt(df2, id=c("timeInterval"))
# length(my.result)
# nrow(my.result)
# my.result
# colnames(my.result)
# my.result$value <- as.numeric(my.result$value)/1000
# head(my.result)
# quantile(my.result$value,probs = c(0, 0.25, 0.5, 0.75,1), na.rm = TRUE)
#
#
# LCOE <- read_xlsx('C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Diplomarbeit/Literatur/LCOE.xlsx')
#
# trial <- data.frame(
#   Price <- quantile(my.result$value,probs = c(0, 0.25, 0.5, 0.75,1), na.rm = TRUE),
#   Technology_Key <- c(0,25,50,75,100)
#
# )
# trial
#
# colnames(trial) <- c("Price", "Technology_Key")
#
# LCOE <- rbind(LCOE[,2:3],trial)
#
#
#
# LCOE$merger <- 1
# df1$merger <- 1
#
# df1 <- merge(x=df1, y=LCOE, by = 'merger', all = TRUE)

xml_main <- as_list(read_xml(url))

trial <- tibble::as_tibble(xml_main) %>%
  unnest_wider(Publication_MarketDocument) %>%
  unnest(cols = names(.)) %>%
  unnest(cols = names(.)) %>%
  readr::type_convert()



Price <- as.data.frame(trial)


df3 <- unlist(Price$Period)

df3 <- as.data.frame(df3)
colnames(df3) <- c("Price")

df3 <- subset(df3, nchar(as.character(Price)) == 6)



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

LCOE <- LCOE[, 2:3]

LCOE$merger <- 1
df1$merger <- 1
df1 <- merge(x = df1, y = LCOE, by = "merger", all = TRUE)


FLH <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/FLH.xlsx")

FLH$merger <- 1

Electrolysis <- merge(x = df1, y = FLH, by = "merger", all = TRUE)

Electrolysis$Quantity_H2_kg <- (Electrolysis$`Capacity_[kW]` * Electrolysis$FLH) / Electrolysis$`Electrolysis_Energy_Demand_[kWh/kg]`
Electrolysis$Opex <- Electrolysis$`Electrolysis_Energy_Demand_[kWh/kg]` * Electrolysis$Quantity_H2_kg * Electrolysis$Price



LCOH <- function(x, output) {
  Invest <- as.numeric(x[6])

  OpEx <- as.numeric(x[11])

  Quantity <- as.numeric(x[10])

  return(
    (Invest + sum(OpEx / (1.04)^(1:20))) / (Quantity * 20) #### discount energy
  )
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

colnames(Electrolysis_main) <- c("Electrolyser", "Quantile", "LCOH")

Electrolysis_main <- Electrolysis_main[, c(1, 3)]
Electrolysis_main$merger <- 1


### import dataset
dataset <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/Lit_Ref.xlsx")

### extract storage data
storage_dim <- data.frame(dataset$Storage_Technology, dataset$`Storage_Cost_[€/kgH2]`, dataset$Storage_State)
colnames(storage_dim) <- c("Storage_Technology", "Storage_Cost", "Storage_State")

### calculate quantiles by technology and aggregate
storage_dim <- storage_dim %>%
  group_by(Storage_Technology, Storage_State) %>%
  mutate(
    Q0 = quantile(Storage_Cost, probs = 0, na.rm = TRUE),
    Q25 = quantile(Storage_Cost, probs = 0.25, na.rm = TRUE),
    Q50 = quantile(Storage_Cost, probs = 0.5, na.rm = TRUE),
    Q75 = quantile(Storage_Cost, probs = 0.75, na.rm = TRUE),
    Q100 = quantile(Storage_Cost, probs = 1, na.rm = TRUE)
  ) %>%
  distinct(Q0, Q25, Q50, Q75, Q100)


### merge data

storage_dim <- melt(data.table(storage_dim), id = c("Storage_Technology", "Storage_State"))
colnames(storage_dim) <- c("Storage_Technology", "Storage_State", "Storage_Quantile", "Storage_Value")


storage_dim <- storage_dim %>%
  group_by(Storage_Technology) %>%
  mutate(Storage_Technology_Key = cur_group_id())



storage_dim[storage_dim == "cH2"] <- "1"
storage_dim[storage_dim == "LH2"] <- "2"
storage_dim[storage_dim == "NH3"] <- "3"

storage_dim$Storage_State <- as.numeric(storage_dim$Storage_State)

storage_result <- storage_dim[, -c(1, 3)]
storage_result$merger <- 1
drop_na(storage_result)
df1 <- merge(x = Electrolysis_main, y = storage_result, by = "merger", all = TRUE)

df1
######################################


conversion_dim <- data.frame(dataset$Conversion_Input_State, dataset$Conversion_Technology, dataset$`Conversion_Energy_Demand_[kWh/kg H2]`, dataset$Conversion_Output_State)
colnames(conversion_dim) <- c("Storage_State", "Conversion_Technology", "Conversion_Energy_Demand", "Conversion_Output_State")

conversion_dim <- conversion_dim %>%
  group_by(Storage_State, Conversion_Technology, Conversion_Output_State) %>%
  mutate(
    Q0 = quantile(Conversion_Energy_Demand, probs = 0, na.rm = TRUE),
    Q25 = quantile(Conversion_Energy_Demand, probs = 0.25, na.rm = TRUE),
    Q50 = quantile(Conversion_Energy_Demand, probs = 0.5, na.rm = TRUE),
    Q75 = quantile(Conversion_Energy_Demand, probs = 0.75, na.rm = TRUE),
    Q100 = quantile(Conversion_Energy_Demand, probs = 1, na.rm = TRUE)
  ) %>%
  distinct(Q0, Q25, Q50, Q75, Q100)

conversion_dim <- melt(data.table(conversion_dim), id = c("Storage_State", "Conversion_Technology", "Conversion_Output_State"))
colnames(conversion_dim) <- c("Storage_State", "Conversion_Technology", "Conversion_Output_State", "Conversion_Quantile", "Conversion_Value")

conversion_dim <- conversion_dim %>%
  group_by(Conversion_Technology) %>%
  mutate(Conversion_Technology_Key = cur_group_id())

conversion_dim[conversion_dim == "cH2"] <- "1"
conversion_dim[conversion_dim == "LH2"] <- "2"
conversion_dim[conversion_dim == "NH3"] <- "3"

conversion_dim$Storage_State <- as.numeric(conversion_dim$Storage_State)
conversion_dim$Conversion_Output_State <- as.numeric(conversion_dim$Conversion_Output_State)

conversion_result <- conversion_dim[, -c(2, 4)]

df1 <- merge(x = df1, y = conversion_result, by = "Storage_State", all = TRUE)

#####################################
transport_dim <- data.frame(dataset$Transport_Technology, dataset$`Transport_Cost_[€/tkm]`, dataset$Transport_State)
colnames(transport_dim) <- c("Transport_Technology", "Transport_Cost", "Conversion_Output_State")

transport_dim <- transport_dim %>%
  group_by(Transport_Technology, Conversion_Output_State) %>%
  mutate(
    Q0 = quantile(Transport_Cost, probs = 0, na.rm = TRUE),
    Q25 = quantile(Transport_Cost, probs = 0.25, na.rm = TRUE),
    Q50 = quantile(Transport_Cost, probs = 0.5, na.rm = TRUE),
    Q75 = quantile(Transport_Cost, probs = 0.75, na.rm = TRUE),
    Q100 = quantile(Transport_Cost, probs = 1, na.rm = TRUE)
  ) %>%
  distinct(Q0, Q25, Q50, Q75, Q100)

transport_dim <- melt(data.table(transport_dim), id = c("Transport_Technology", "Conversion_Output_State"))
colnames(transport_dim) <- c("Transport_Technology", "Conversion_Output_State", "Transport_Quantile", "Transport_Value")

transport_dim <- transport_dim %>%
  group_by(Transport_Technology) %>%
  mutate(Transport_Technology_Key = cur_group_id())

transport_dim[transport_dim == "cH2"] <- "1"
transport_dim[transport_dim == "LH2"] <- "2"
transport_dim[transport_dim == "NH3"] <- "3"
transport_dim$Conversion_Output_State <- as.numeric(transport_dim$Conversion_Output_State)

transport_result <- transport_dim[, -c(1, 3)]

df1 <- merge(x = df1, y = transport_result, by = "Conversion_Output_State", all = TRUE)

Distance <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/Distance_Ref.xlsx")
Distance$merger <- 1
df1 <- merge(x = df1, y = Distance, by = "merger", all = TRUE)


df1 <- merge(x = df1, y = LCOE, by = "merger", all = TRUE)


df1$Conversion_Cost <- df1$Conversion_Value * df1$Price



df1$Transport_Cost <- (df1$Transport_Value * df1$Distance_km) / 1000
df1$Total_Cost <- df1$Transport_Cost + df1$Conversion_Cost + df1$Storage_Value + df1$LCOH

df1
