# main script for writing json files in nested format (denormalized). Best for
# Google BigQuery format (probably not Amazon Redshift).

source("./R/q_flat_files_denorm.R")
library(tidyverse)


#' Main main method for writing to json in denormalized nested structure
#' 
#' @param path The directory to write the files to
main <- function(path) {
  sheets <- top_rev_files('key')
  full <- get_full_table(full)
  question <- get_denorm_table(full, 'question')
  axis <- get_denorm_table(full, 'axis')
  write_denorm_tables(question, path, 'question')
  write_denorm_tables(axis, path, 'axis')
}


# run 'er
main("/tmp")