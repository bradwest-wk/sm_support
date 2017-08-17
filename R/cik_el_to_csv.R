# write csv of ciks and element names

library(googlesheets)
library(tidyverse)
library(stringr)
library(roxygen2)


el <- read_csv("./data/lv1_els.csv", col_names = FALSE)
sss <- gs_title("Sample Selection Support")
comp <- sss %>% gs_read(ws = 4, skip = 4)
top_thirty <- comp[1:30,]
top_cik <- as.character(top_thirty$CIK)
top_cik <- str_pad(top_cik, 10, side = "left", pad = "0")

df <- read_csv("cik,elname\n", col_types = "cc")
for (i in 1:length(top_cik)) {
  for (j in 1:nrow(el)) {
    dfa <- tibble(top_cik[i], el$X1[j])
    colnames(dfa) <- c("cik", "elname")
    df <- bind_rows(df, dfa)
  }
}

write_csv(df, "./data/top_thirty_rev.csv")

df <- read_csv("./data/top_thirty_rev.csv", col_names = FALSE)
sum(!is.na(df[,3]))

large <- read_csv("./data/lv1_data_cik_el.csv", col_names = FALSE)
large <- large[!is.na(large$X1),]
large$X1 <- str_pad(large$X1, 10, side = "left", pad = "0")
alpha <- c("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q",
           "R","S","T","U","V","W","X","Y","Z")
for (letter in alpha) {
  df <- large[startsWith(large$X2, letter),]
  outname <- paste0("./data/lv1_cik_el_", letter, ".csv")
  write_csv(df, outname, col_names = FALSE)
}
