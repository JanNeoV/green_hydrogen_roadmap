library(RPostgres)
library(readxl)
library(tidyverse)
library(lubridate)

lit_ref <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/Lit_Ref.xlsx")
lcoe <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/LCOE.xlsx")
flh <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/FLH.xlsx")
distance <- read_xlsx("C:/Users/JanBusse/OneDrive - Neo Vensiles/Privat/Schriftverkehr/TU Dresden/Diplomarbeit/Literatur/Distance_Ref.xlsx")




# Units:
# U.S. Dollars per Million Metric British Thermal Unit,
# Not Seasonally Adjusted
market_date <- format(floor_date(Sys.Date(), "month"), "%Y-%m-%d")
CSV_URL <- paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?bgcolor=%23e1e9f0&chart_type=line&drp=0&fo=open%20sans&graph_bgcolor=%23ffffff&height=450&mode=fred&recession_bars=off&txtcolor=%23444444&ts=12&tts=12&width=1318&nt=0&thu=0&trc=0&show_legend=yes&show_axis_titles=yes&show_tooltip=yes&id=PNGASEUUSDM&scale=left&cosd=1990-01-01&coed=", market_date, "&line_color=%234572a7&link_values=false&line_style=solid&mark_type=none&mw=3&lw=2&ost=-99999&oet=99999&mma=0&fml=a&fq=Monthly&fam=avg&fgst=lin&fgsnd=2020-02-01&line_index=1&transformation=lin&vintage_date=2023-11-08&revision_date=2023-11-08&nd=1990-01-01")
ngas <- read_csv(CSV_URL)


# Create a connection
con <- dbConnect(RPostgres::Postgres(),
                 dbname = db_name,
                 host = db_host,
                 port = db_port,
                 user = db_user,
                 password = db_password)

### Schema festlegen
dbExecute(con, "SET search_path TO hydrogen_roadmap_stag")

lit_ref <- lit_ref %>% rename_with(tolower, everything())
lcoe <- lcoe %>% rename_with(tolower, everything())
flh <- flh %>% rename_with(tolower, everything())
distance <- distance %>% rename_with(tolower, everything())
ngas <- ngas %>% rename_with(tolower, everything())

table_names <- c(lit_ref = "lit_ref_table", lcoe = "lcoe_table", flh = "flh_table", distance = "distance_table", ngas = "ngas_table")

# Data frames
data_frames <- list(lit_ref = lit_ref, lcoe = lcoe, flh = flh, distance = distance, ngas = ngas)

# Upload each data frame to its corresponding table
for (name in names(data_frames)) {
  full_table_name <- paste0(table_names[name])
  tryCatch(
    {
      dbWriteTable(con, full_table_name, data_frames[[name]], overwrite = TRUE)
      print(paste("Upload successful for table:", full_table_name))
    },
    error = function(e) {
      print(paste("Error in upload for table", full_table_name, ":", e$message))
    }
  )
}


# Create table
dbSendQuery(con, "CREATE TABLE energy_sources (
  code VARCHAR(3) PRIMARY KEY,
  meaning VARCHAR(255)
)")

# Insert data
dbSendQuery(con, "INSERT INTO energy_sources (code, meaning) VALUES
(  'A03', 'Mixed'),
(  'A04', 'Generation'),
(  'A05', 'Load'),
(  'B01', 'Biomass'),
(  'B02', 'Fossil Brown coal/Lignite'),
(  'B03', 'Fossil Coal-derived gas'),
(  'B04', 'Fossil Gas'),
(  'B05', 'Fossil Hard coal'),
(  'B06', 'Fossil Oil'),
(  'B07', 'Fossil Oil shale'),
(  'B08', 'Fossil Peat'),
(  'B09', 'Geothermal'),
(  'B10', 'Hydro Pumped Storage'),
(  'B11', 'Hydro Run-of-river and poundage'),
(  'B12', 'Hydro Water Reservoir'),
(  'B13', 'Marine'),
(  'B14', 'Nuclear'),
(  'B15', 'Other renewable'),
(  'B16', 'Solar'),
(  'B17', 'Waste'),
(  'B18', 'Wind Offshore'),
(  'B19', 'Wind Onshore'),
(  'B20', 'Other'),
(  'B21', 'AC Link'),
(  'B22', 'DC Link'),
(  'B23', 'Substation'),
('B24', 'Transformer')")

# Close connection
dbDisconnect(con)