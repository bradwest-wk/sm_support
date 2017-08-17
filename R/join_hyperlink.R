library(tidyverse)
library(lubridate)
library(stringr)

setwd("~/Google_Drive/Projects/DQ_requests/sm_support/data/")

raw <- read_csv("./lv1_relations/lv1_relations_IS.csv", 
                col_types = "cccicccc??cc")
raw$period_end <- as.Date(raw$period_end, format = "%m/%d/%y")
raw$period_start <- as.Date(raw$period_start, format = "%m/%d/%y")
raw$cik <- str_pad(raw$cik, 10, side = "left", pad = "0")

url <- read_csv("./sec_url.csv", col_types = "ccicDc")

out <- raw %>% left_join(url[, c('cik', 'url_hyperlink')], by = 'cik')
sum(is.na(out$url_hyperlink))

out <- out %>% 
  select(report, company_name, cik, url_hyperlink, sic, element_name,
         line_item_description, source, period_end, period_start,
         parent_name, parent_line_item_description)

write_csv(out, path = "./lv1_relations/lv1_relations_IS.csv", col_names = TRUE)

test <- read_csv("./lv1_relations/lv1_relations_IS.csv", 
                 col_types = "ccccicccDDcc")
