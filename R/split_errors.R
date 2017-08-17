# converts large csv errors file to multiple smaller csv files based on rule

library(tidyverse)
library(stringr)

setwd("~/Google_Drive/Projects/DQ_requests/sm_support")
large <- read_csv("./data/errors_2016_parsed.csv")
rules <- unique(large$general_rule)
sum(is.na(large$general_rule))
sum(is.null(large$general_rule))
dqc_01 <- large %>% filter(general_rule == rules[1])
dqc_else <- large %>% filter(general_rule != rules[1])

dqc001 <- large %>% filter(general_rule == rules[1])
dqc015 <- large %>% filter(general_rule == rules[2])
dqc013 <- large %>% filter(general_rule == rules[3])
dqc041 <- large %>% filter(general_rule == rules[4])
dqc033 <- large %>% filter(general_rule == rules[5])
dqc046 <- large %>% filter(general_rule == rules[6])
dqc005 <- large %>% filter(general_rule == rules[7])
dqc011 <- large %>% filter(general_rule == rules[8])
dqc018 <- large %>% filter(general_rule == rules[9])
dqc008 <- large %>% filter(general_rule == rules[10])
dqc014 <- large %>% filter(general_rule == rules[11])
dqc004 <- large %>% filter(general_rule == rules[12])
dqc006 <- large %>% filter(general_rule == rules[13])
dqc009 <- large %>% filter(general_rule == rules[14])
dqc036 <- large %>% filter(general_rule == rules[15])

write_csv(dqc004, "./data/split_errors/dqc004_2016_errors.csv")
write_csv(dqc005, "./data/split_errors/dqc005_2016_errors.csv")
write_csv(dqc006, "./data/split_errors/dqc006_2016_errors.csv")
write_csv(dqc008, "./data/split_errors/dqc008_2016_errors.csv")
write_csv(dqc009, "./data/split_errors/dqc009_2016_errors.csv")
write_csv(dqc011, "./data/split_errors/dqc011_2016_errors.csv")
write_csv(dqc013, "./data/split_errors/dqc013_2016_errors.csv")
write_csv(dqc018, "./data/split_errors/dqc018_2016_errors.csv")
write_csv(dqc033, "./data/split_errors/dqc033_2016_errors.csv")
write_csv(dqc036, "./data/split_errors/dqc036_2016_errors.csv")
write_csv(dqc041, "./data/split_errors/dqc041_2016_errors.csv")
write_csv(dqc046, "./data/split_errors/dqc046_2016_errors.csv")
write_csv(dqc014, "./data/split_errors/dqc014_2016_errors.csv")

cik_quant_015 <- quantile(as.numeric(dqc015$cik), probs = seq(0,1,.2))
dqc015_1 <- dqc015 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_015[1] & cik < cik_quant_015[2]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc015_2 <- dqc015 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_015[2] & cik < cik_quant_015[3]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc015_3 <- dqc015 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_015[3] & cik < cik_quant_015[4]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc015_4 <- dqc015 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_015[4] & cik < cik_quant_015[5]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc015_5 <- dqc015 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_015[5] & cik < cik_quant_015[6]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)

write_csv(
  dqc015_1, "./data/split_errors/dqc015_2016_cik0000001750-0000798370.csv")
write_csv(
  dqc015_2, "./data/split_errors/dqc015_2016_cik0000798371-0001037130.csv")
write_csv(
  dqc015_3, "./data/split_errors/dqc015_2016_cik0001037131-0001310440.csv")
write_csv(
  dqc015_4, "./data/split_errors/dqc015_2016_cik0001310441-0001490635.csv")
write_csv(
  dqc015_5, "./data/split_errors/dqc015_2016_cik0001490636-0001688315.csv")

cik_quant_001 <- quantile(as.numeric(dqc001$cik), probs = seq(0,1,.1))
dqc001_1 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[1] & cik < cik_quant_001[2]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_2 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[2] & cik < cik_quant_001[3]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_3 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[3] & cik < cik_quant_001[4]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_4 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[4] & cik < cik_quant_001[5]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_5 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[5] & cik < cik_quant_001[6]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_6 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[6] & cik < cik_quant_001[7]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_7 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[7] & cik < cik_quant_001[8]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_8 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[8] & cik < cik_quant_001[9]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_9 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[9] & cik < cik_quant_001[10]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
dqc001_10 <- dqc001 %>% mutate(cik = as.numeric(cik)) %>% 
  filter(cik >= cik_quant_001[10] & cik < cik_quant_001[11]) %>% 
  mutate(cik = str_pad(as.character(cik), 10, pad = "0")) %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)

write_csv(
  dqc001_1, "./data/split_errors/dqc001_2016_cik0000001800-0000054479.csv")
write_csv(
  dqc001_2, "./data/split_errors/dqc001_2016_cik0000054480-0000726600.csv")
write_csv(
  dqc001_3, "./data/split_errors/dqc001_2016_cik0000726601-0000833443.csv")
write_csv(
  dqc001_4, "./data/split_errors/dqc001_2016_cik0000833444-0000929007.csv")
write_csv(
  dqc001_5, "./data/split_errors/dqc001_2016_cik0000929008-0001057876.csv")
write_csv(
  dqc001_6, "./data/split_errors/dqc001_2016_cik0001057877-0001156038.csv")
write_csv(
  dqc001_7, "./data/split_errors/dqc001_2016_cik0001156039-0001333140.csv")
write_csv(
  dqc001_8, "./data/split_errors/dqc001_2016_cik0001333141-0001457736.csv")
write_csv(
  dqc001_9, "./data/split_errors/dqc001_2016_cik0001457737-0001550376.csv")
write_csv(
  dqc001_10, "./data/split_errors/dqc001_2016_cik0001550377-0001688315.csv")



write_csv(dqc_else, "./data/errors_2016_ex001.csv")
dqc_01_sml <- dqc_01 %>% 
  select(company_name, cik, accession_number, element_name, 
         exact_rule, message_value)
write_csv(dqc_01_sml, "./data/errors_2016_0001.csv")
