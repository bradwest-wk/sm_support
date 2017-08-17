# combine 2016 fiscal year report_ids from debug3_db with table codes of
# interest for level 1 companies

library(tidyverse)

setwd("~/Google_Drive/Projects/DQ_requests/sm_support/")
reports <- read_csv("./data/fy_2016_reports.csv")
# drop cik
reports <- reports$report_id

# table_codes in debug3_db: Income statement, balance sheet, cash flow,
# comprehensive income, shareholder equity
table_codes <- c("IS", "BS", "CF", "CI", "EQ")

out <- cbind.data.frame(reports[1], table_codes, stringsAsFactors = FALSE)
colnames(out) <- c("report", "tcode")
for (i in 2:length(reports)) {
  tmp <- cbind(reports[i], table_codes)
  colnames(tmp) <- c("report", "tcode")
  out <- rbind(out, tmp)
}

out <- out %>% arrange(tcode, desc(report))
write_csv(out, "./data/lv1_reports_tcodes.csv", col_names = FALSE)

out_is <- out %>% filter(tcode=="IS")
write_csv(out_is, "./data/lv1_relations/lv1_reports_is.csv", col_names = F)

out_cf <- out %>% filter(tcode=="CF")
write_csv(out_cf, "./data/lv1_relations/lv1_reports_cf.csv", col_names = F)

out_ci <- out %>% filter(tcode=="CI")
write_csv(out_ci, "./data/lv1_relations/lv1_reports_ci.csv", col_names = F)

out_bs <- out %>% filter(tcode=="BS")
write_csv(out_bs, "./data/lv1_relations/lv1_reports_bs.csv", col_names = F)

out_se <- out %>% filter(tcode=="EQ")
write_csv(out_se, "./data/lv1_relations/lv1_reports_se.csv", col_names = F)

