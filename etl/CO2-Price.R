### create dataset for input in Power BI to calculate levelised cost of hydrogen (LCOH)
### total LCOH may not be calculated since the price for electricity is based on real-time data that is stored within Power BI
### split dataset by electrolyser to calculate quantiles of each input parameter for LCOH by electrolyser by quantile and reappend datasets for ease of calculation
### Import necessary libraries

install.packages("dplyr")
install.packages("data.table")
install.packages("jsonlite")
install.packages("lubridate")
install.packages("XML")
install.packages("methods")
install.packages("xml2")
install.packages("tidyverse")
install.packages("reshape")
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



exchange_rate <- 1.0703

CSV_URL <- "https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=off&txtcolor=%23444444&ts=12&tts=12&width=1318&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=PNGASEUUSDM&scale=left&cosd=1990-01-01&coed=2023-09-01&line_color=%234572a7&link_values=false&line_style=solid&mark_type=none&mw=3&lw=2&ost=-99999&oet=99999&mma=0&fml=a&fq=Monthly&fam=avg&fgst=lin&fgsnd=2020-02-01&line_index=1&transformation=lin&vintage_date=2023-11-08&revision_date=2023-11-08&nd=1990-01-01"



df <- read_csv(CSV_URL)
colnames(df) <- c("Date", "Value")
water_cost <- 0.14 / exchange_rate
df$NG_Price_EUR <- df$Value / exchange_rate
df$NG_Price_EUR_kg <- (df$NG_Price_EUR / 26.4) / (0.8)
df$Investment <- 0.15 / exchange_rate
df$OM <- 0.81 * 0.249 / exchange_rate
df$carbon <- (8.5 * 50) / 1000

df$raw <- df$Investment + df$OM + df$NG_Price_EUR_kg * 3.2

df$fif <- df$Investment + df$OM + df$NG_Price_EUR_kg * 3.2 + 8.5 * 50 / 1000

df$hun <- df$Investment + df$OM + df$NG_Price_EUR_kg * 3.2 + 8.5 * 100 / 1000

df$hunfif <- df$Investment + df$OM + df$NG_Price_EUR_kg * 3.2 + 8.5 * 150 / 1000

df$two <- df$Investment + df$OM + df$NG_Price_EUR_kg * 3.2 + 8.5 * 200 / 1000
