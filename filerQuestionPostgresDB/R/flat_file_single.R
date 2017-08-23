# functions for creating a single table.

# because the finest level of detail in the questions DB is the disclosure, we 
# really just need a record for each question (unique on the disclosure and
# element pair).  Disclosures can cover line items, members, and axes. The data
# model specifies that the presentation parent will be used to indicate the axis
# that a particular line item, domain, or member belongs to.  This ensures the
# database records enough information to identify the hypercube to which a
# member, domain, or line item belongs.  

# Currently we do not have unique integer ids to use as keys

library(tidyverse)

source("./R/q_flat_file.R") # filter_no_elements
source("./R/q_flat_files_denorm.R") # top_rev_files()

#' Get Records
#' 
#' Accesses the google sheets spreadsheet and coorect worksheet, returning a 
#' dataframe with columns destined for database.  Because members and axes
#' are included in the dislosure requirements, we do not need a nested structure
#' to account for dimensions.  Domain members will have a link (via the 
#' presentation element) to their respective Domain.
#' 
#' @param id The id of the spreadsheet, either it's title or key
#' @param id_type the type of the identifier, one of 'title' or 'key'
#' @param wrksht The worksheet wished to grab.  Defaults to 'Disclosure Requirements'
#' @param taxonomy The applicable taxonomy, defaults to '2017_rebuild'
#' @return dataframe
get_records_gs <- function(id, id_type, wrksht, taxonomy) {
  if (id_type == 'title') {
    sht <- googlesheets::gs_title(id, verbose = FALSE)  
  } else if (id_type == 'key') {
    sht <- googlesheets::gs_key(id, verbose = FALSE)
  } else {
    stop('id_type must be one of title or key')
  }
  df <- googlesheets::gs_read(sht, ws = wrksht)
  df <- df[, c(1,2,3,4,11,13,16,17,18,19,20,21,22,23,24)]
  dscl_vec <- rep(sht$sheet_title, nrow(df))
  tx_vec <- rep(taxonomy, nrow(df))
  unit_vec <- rep(NA, nrow(df))
  df <- cbind.data.frame(dscl_vec, tx_vec, df, unit_vec, 
                         stringsAsFactors = FALSE)
  colnames(df) <- c('disclosure', 'taxonomy', 'topic', 'asc_paragraph_ref1', 
                    'sx_paragraph_ref', 'asc_paragraph_ref2', 'ref_id', 
                    'question', 'presentation_parent', 'calculation_parent', 
                    'element_name', 'element_label', 'balance_type', 
                    'period_type', 'data_type', 'namespace', 'definition', 
                    'unit')
  # need to sort
  df <- df %>% arrange(disclosure, element_name, question)
  df
}


#' Get full table
#' 
#' Iterates through vector of topical review sheets and gets the cleaned df
#' from each one.
#' 
#' @param sheets A vector of sheet titles or sheet keys
#' @param type one of 'title' or 'key', specifying the id type of the sheet
#' @param tab The specific tab wished to grab (passed to sheet_to_df)
#' @param taxonomy The applicable taxonomy
#' @return a df with all the information relevant to the questions db
get_full <- function(sheets, type, tab, taxonomy) {
  dframes <- list()
  for (id in sheets) {
    d_name <- id
    try({
      df <- get_records_gs(id, type, tab, taxonomy)
      df <- filter_no_elements(df)
      dframes[[d_name]] <- df
    }, silent = FALSE)
  }
  full <- dplyr::bind_rows(dframes)
  return(full)
}


#' Write single table as JSON
#' 
#' Execute the write of the denormalized table to JSON.  This streams out in
#' newline delimited json, which is necessary for loading google bigquery
#' 
#' @param df The dataframe containing all the necessary table information
#' @param path The output filepath and name
write_json_tbl <- function(df, path) {
  conn <- file(path)
  jsonlite::stream_out(df, conn, null = 'null')
}


#' main method for writing a single denormalized table to a file of newline
#' delimited JSON
#' 
#' @param path the filepath to write to
#' @param sheets a character vector of google sheets to process.  If left null
#' then the function finds and processes all sheets in drive that begin with 
#' 'ASC'
#' @param id_type the type of identifier used for the sheets, one of 'title' or 
#' 'key'
main <- function(path, sheets = NULL, id_type = 'key') {
  if (is.null(sheets)) {
    sheet <- top_rev_files('key')
  } else {
    sheet <- sheets
  }
  full <- get_full(sheet, type = id_type, 'Disclosure Requirements', 
                         '2017_review')
  write_json_tbl(full, path)
}



# run 'er
# main("/tmp/test_json_qdb.json")