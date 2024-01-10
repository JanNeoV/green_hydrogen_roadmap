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
library(RPostgres)


###############
format(lubridate::floor_date(Sys.time(), "30 minutes"), "%Y%m%d%H%M")
security_token <- "c48428c5-69ed-42d8-bb65-271b18972769"
domain <- "10Y1001A1001A82H"
period_start <- format(lubridate::floor_date(Sys.time() - days(364), "60 minutes"), "%Y%m%d%H%M")
period_end <- format(lubridate::floor_date(Sys.time(), "60 minutes"), "%Y%m%d%H%M")

url <- paste0("https://web-api.tp.entsoe.eu/api?securityToken=", security_token, "&documentType=A44&in_Domain=", domain, "&out_Domain=", domain, "&periodStart=", period_start, "&periodEnd=", period_end)



# Load XML data
xml_data <- read_xml(url)

# Find Perriods
periods <- xml_find_all(xml_data, ".//d1:Period", ns = xml_ns(xml_data))
cat("Number of Period elements found:", length(periods), "\n")

# Parse points within period
parse_point <- function(point_node) {
      period_node <- xml_find_first(point_node, "parent::d1:Period", ns = xml_ns(xml_data))
      start_date <- xml_text(xml_find_first(period_node, ".//d1:timeInterval/d1:start", ns = xml_ns(xml_data)))
      resolution <- xml_text(xml_find_first(period_node, ".//d1:resolution", ns = xml_ns(xml_data)))
      position <- xml_text(xml_find_first(point_node, ".//d1:position", ns = xml_ns(xml_data)))
      price_amount <- xml_text(xml_find_first(point_node, ".//d1:price.amount", ns = xml_ns(xml_data)))

      tibble(
            date = start_date,
            period = as.integer(position),
            price_amount = as.numeric(price_amount),
            resolution = resolution
      )
}

### start timer
start_time <- Sys.time()


cat("Extracting and processing data...\n")


# Extract and process data
points <- xml_find_all(xml_data, ".//d1:Point", ns = xml_ns(xml_data))
extracted_data <- map_dfr(points, parse_point)



print(head(extracted_data))


con <- dbConnect(RPostgres::Postgres(),
                 dbname = db_name,
                 host = db_host,
                 port = db_port,
                 user = db_user,
                 password = db_password)

dbExecute(con, "SET search_path TO hydrogen_roadmap_stag")


dbWriteTable(con, "electricity_prices", extracted_data, overwrite = TRUE)

dbReadTable(con, "electricity_prices") %>% head()

# Close the connection when done
dbDisconnect(con)

end_time <- Sys.time()
cat("Data extraction and processing completed.\n")
cat("Time taken: ", end_time - start_time, "\n")
