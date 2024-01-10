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

###############
security_token <- Sys.getenv("SECURITY_TOKEN")
db_name <- Sys.getenv("DB_NAME")
db_host <- Sys.getenv("DB_HOST")
db_port <- as.numeric(Sys.getenv("DB_PORT"))
db_user <- Sys.getenv("DB_USER")
db_password <- Sys.getenv("DB_PASSWORD")

###############
format(lubridate::floor_date(Sys.time(), "30 minutes"), "%Y%m%d%H%M")

domain <- "10Y1001A1001A82H"
period_start <- format(lubridate::floor_date(Sys.time() - days(364), "60 minutes"), "%Y%m%d%H%M")
period_end <- format(lubridate::floor_date(Sys.time(), "60 minutes"), "%Y%m%d%H%M")

url <- paste0("https://web-api.tp.entsoe.eu/api?securityToken=", security_token, "&documentType=A44&in_Domain=", domain, "&out_Domain=", domain, "&periodStart=", period_start, "&periodEnd=", period_end)



# Load XML data
xml_data <- read_xml(url)

# ##### fixing namespace
periods <- xml_find_all(xml_data, ".//d1:Period", ns = xml_ns(xml_data))
cat("Number of Period elements found:", length(periods), "\n") ### just necessary for debugging in case the operation fails, e.g. due to wrong namespaces

# parse withing points
parse_point <- function(point_node, ts_node) {
  period_node <- xml_find_first(point_node, "parent::d1:Period", ns = xml_ns(ts_node))
  start_date <- xml_text(xml_find_first(period_node, ".//d1:timeInterval/d1:start", ns = xml_ns(ts_node)))
  resolution <- xml_text(xml_find_first(period_node, ".//d1:resolution", ns = xml_ns(ts_node)))
  position <- xml_text(xml_find_first(point_node, ".//d1:position", ns = xml_ns(ts_node)))
  quantity <- xml_text(xml_find_first(point_node, ".//d1:quantity", ns = xml_ns(ts_node)))
  mkt_psr_type <- xml_text(xml_find_first(ts_node, ".//d1:MktPSRType/d1:psrType", ns = xml_ns(ts_node)))

  tibble(
    date = start_date,
    period = as.integer(position),
    quantity = as.numeric(quantity),
    resolution = resolution,
    mkt_psr_type = mkt_psr_type
  )
}


### start timer
start_time <- Sys.time()


cat("Extracting and processing data...\n")

# Extract and process data
time_series_nodes <- xml_find_all(xml_data, ".//d1:TimeSeries", ns = xml_ns(xml_data))

total <- length(time_series_nodes)
current <- 1
# Process each TimeSeries node
extracted_data <- map_dfr(time_series_nodes, ~{
  ts_node <- .
  
  # Print the current status
  cat(sprintf("Processing TimeSeries %d of %d...\n", current, total))
  
  points <- xml_find_all(ts_node, ".//d1:Point", ns = xml_ns(ts_node))
  result <- map_dfr(points, ~parse_point(., ts_node))
  
  # Increment the current counter
  current <<- current + 1
  
  result
})


print(head(extracted_data))

con <- dbConnect(RPostgres::Postgres(),
                 dbname = db_name,
                 host = db_host,
                 port = db_port,
                 user = db_user,
                 password = db_password)

dbExecute(con, "SET search_path TO hydrogen_roadmap_stag")



dbWriteTable(con, "electricity_generation", extracted_data, overwrite = TRUE)

dbReadTable(con, "electricity_generation") %>% head()

# Close the connection when done
dbDisconnect(con)

end_time <- Sys.time()
cat("Data extraction and processing completed.\n")
cat("Time taken: ", end_time - start_time, "\n")