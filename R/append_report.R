# append report ID's to ciks for fiscal year 2016

library(tidyverse)
library(stringr)
setwd("~/Google_Drive/Projects/DQ_requests/sm_support/")

# these are the 2016 Fiscal Yyear 10K reports
reports_2016 <- read_csv("./data/fy_2016_reports.csv", col_names = TRUE)
# check if duplicated reports
if (sum(duplicated(reports_2016$cik)) > 0) {
  warning("Multiple reports per company.  Check Data")
} else if (sum(duplicated(reports_2016$report_id)) > 0) {
  warning("Multiple ciks per report. Investigate issue")
}

# these are the ciks and textblock element names to join with 
ciks_el <- read_csv("./data/top_thirty_rev.csv", col_names = TRUE)
tmp <- left_join(ciks_el, reports_2016, by = "cik")

write_csv(tmp, "./data/top_thirty_cik_report.csv", col_names = FALSE)

file_names <- dir("./data/lv1_data_cik_el/", pattern = ".csv")
for (file in file_names) {
  cik <- read_csv(paste0("./data/lv1_data_cik_el/", file), col_names = FALSE)
  colnames(cik) <- c("cik", "elname")
  tmp <- left_join(cik, reports_2016, by = "cik")
  tmp <- tmp[!is.na(tmp$report_id),]
  out_name <- paste0(str_split(file, "[.]")[[1]][1], "_report", ".csv")
  write_csv(tmp, paste0("./data/lv1_data_cik_el/", out_name), col_names = F)
} 

