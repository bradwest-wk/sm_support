# label analysis

library(googlesheets)
library(tidyverse)
library(stringr)

ws <- gs_title("ASC 225 Income Statement") %>% gs_read(ws = 'Stress Testing')
ws$CIK <- as.character(ws$CIK)
ws$CIK <- str_pad(ws$CIK, 10, side = "left", pad = "0")
ws <- ws %>% 
  select(Company, url_hyperlink, CIK, `Industryper SIC`, 
         `Line item description`, `Existing Element Name (include prefix)`, 
         `Existing Element Name (Standard or Extension)`)

# get ciks for query
for (cik in unique(ws$CIK)) {
  cat(paste0("'", cik, "',"))
}

# ============================================================================ #
# read in query 
query <- 
  read_csv(
    "~/Google_Drive/Projects/DQ_requests/sm_support/data/asc_225_labels.csv")

# no prefix for element name
ws <- ws %>% 
  mutate(el_name = unname(sapply(`Existing Element Name (include prefix)`, 
                                 function(x) str_split(x, "_")[[1]][2])))

full <- ws %>% 
  inner_join(
    query, by = c("Company" = "company_name", 
                  "CIK" = "cik", 
                  "el_name" = "name")) %>% 
  select(Company, `Existing Element Name (include prefix)`, el_name, `Line item description`, line_item_description)


write_csv(unique(ws[,3]), path = "/tmp/ciks.csv")
