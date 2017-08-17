# functions for creating flat csv files for loading the denormalized questions
# database (BigQuery or Redshift)

library(tidyverse)

# for loading sheet_to_df and filter_no_elements
source("./q_flat_file.R")


#' all the topical review files 
#' 
#' @param type return sheet titles or keys? One of 'title' or 'key'
#' @return a vector of sheet identifiers
top_rev_files <- function(type) {
  if (type == 'title') {
    sheets <- googlesheets::gs_ls() %>% 
      filter(substr(sheet_title, 1,3) == 'ASC') %>% 
      select(sheet_title) %>% 
      arrange(sheet_title) %>%
      pull(sheet_title)
  } else if (type == 'key') {
    sheets <- googlesheets::gs_ls() %>% 
      filter(substr(sheet_title, 1,3) == 'ASC') %>% 
      arrange(sheet_title) %>%
      select(sheet_key) %>% 
      pull(sheet_key)
  } else {
    stop('type must be one of title or key')
  }
  return(sheets)
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
get_full_table <- function(sheets, type, tab, taxonomy) {
  dframes <- list()
  for (id in sheets) {
    d_name <- id
    try({
      df <- sheet_to_df(id, type, tab, taxonomy)
      df <- filter_no_elements(df)
      dframes[[d_name]] <- df
    }, silent = TRUE)
  }
  full <- do.call(rbind, dframes)
  return(full)
}


#' Create tables
#' 
#' Creates a question and an axis_member table from the dataset
#' 
#' @param df The dataframe, usually originating from sheet_to_df
#' @param table The table of interest, one of 'question' or 'axis'
#' @return a dataframe of the table of interest
get_denorm_table <- function(df, table) {
  if (!(table %in% c('question', 'axis'))) {
    stop("table must be one of axis or question")
  } else if (table == 'question') {
    tbl <- df %>% 
      select(question, asc_paragraph_ref1, sx_paragraph_ref, 
             asc_paragraph_ref2, ref_id, disclosure, 
             taxonomy, presentation_parent, calculation_parent, 
             element_name, element_label, 
             balance_type, period_type, data_type, unit, namespace, definition)
    tbl <- tbl[!duplicated(tbl), ]
  } else {
    tbl <- df %>% 
      select(axis_name, axis_namespace, element_name, member_name, 
             member_namespace)
    tbl <- tbl[!duplicated(tbl), ]
  }
  
  tbl
}


#' Multiple Records to Nested List
#' 
#' We wish to take multiple records in which we have a constant axis name, 
#' namespace, etc, and varying members and member_namespaces and create a 
#' nested JSON structure.  The first step is a helper function that works to
#' grab a single row
#' 
#' @param df The dataframe of interest
#' @param i The index of the the row of the first occurance of a new axis name,
#' or what will become a single record
#' @return the index of the last row plus 1 (the index to start the next
#' record gathering), and the record as a nested list of lists 
get_single_record <- function(df, i) {
  name <- df$axis_name[i]
  axis_namespace <- df$axis_namespace[i]
  el_name <- df$element_name[i]
  if (is.na(name)) {
    return(list('index' = i+1, 'record' = NA))
  }
  lst <- list('axis_name' = name, 'axis_namespace' = axis_namespace, 
              'element_name' = el_name)
  j <- 1
  while (i <= nrow(df) & 
         df$axis_name[i] == name & 
         df$element_name[i] == el_name &
         df$axis_namespace[i] == axis_namespace) {
    lst$defined_members[[j]] <- 
      list('member_name' = df$member_name[i], 'member_namespace' = df$member_namespace[i])
    i <-  i + 1
    j <- j + 1 
  }
  return(list('index' = i, 'record' = lst))
}


#' Records from Dataframe
#' 
#' Applies the get_single_record across a dataframe to get all the unique records
#' in a list of lists
#' 
#' @param df the dataframe to get records from
#' @param i the index to start from (passed to get_single_record), defaults to 
#' one
#' @return a list of lists with each sublist containing a record. Can be passed 
#' directly to \code{toJSON(x, 'columns', auto_unbox=TRUE)} for conversion to 
#' JSON.
get_all_records <- function(df, i = 1) {
  full <- list()
  j <- 1
  i <- 1
  while (i <= nrow(df)) {
    tmp <- get_single_record(df, i)
    i <- tmp$index
    record <- tmp$record
    if (!is.na(record[1])) {
      full[[j]] <- record
      j <- j + 1 
    }
  }
  return(full)
}


#' Format as json
#' 
#' Execute the writes of the denormalized tables to JSON
#' @param df The dataframe containing all the necessary table information
#' @param path The directory to write to
#' @param table The table to write to, one of 'question' or 'axis'
write_denorm_tables <- function(df, path, table) {
  conn <- file(paste0(path, "/", table, ".json"))
  if (table=='question') {
    jsonlite::stream_out(df, conn)
  } else if (table=='axis') {
    lst <- get_all_records(df)
    js_records <- jsonlite::toJSON(lst, 'columns', auto_unbox = TRUE)
    js_df <- jsonlite::fromJSON(js_records)
    jsonlite::stream_out(js_df, conn)
  } else {
    stop('table parameter must be one of \'question\' or \'axis\'')
  }
}



# =============================================================================
# # Toy examples for experimenting with conversion to JSON format for loading into
# # BigQuery
# 
# # toy dataset
# df <- data.frame('axis_name' = c(rep('us', 3), rep('eu', 2)),
#                  'member_name' = c('mn', 'mt', 'wy', 'gb', 'fr'),
#                  'member_namespace' = c('us_mn', 'us_mt', 'us_wy', 'eu_gb', 'eu_fr'),
#                  stringsAsFactors = FALSE)
# 
# df <- data.frame('question' = c('Bonus', 'Profit Sharing', 'Other Adjustments'),
#                  'asc_ref_1' = c(1,2,3),
#                  'element_name' = c('SalesRevenueNet', 'UtilityRev', 'Revenues'),
#                  stringsAsFactors = FALSE)
# x <- toJSON(df, 'rows', auto_unbox = TRUE)
# 
# # get this list of lists into json
# lst <- list("axis_name" = 'US',
#             'defined_mbrs' = list(
#               list('name' = 'AL', 'namespace' = 'us_AL'),
#               list('name' = 'MN', 'namespace' = 'us_MN'),
#               list('name' = 'MT', 'namespace' = 'us_MT')
#               )
#             )
# x <- toJSON(full, 'columns', auto_unbox = TRUE)
# prettify(x)
# 
# # old function
# write_denorm_tables <- function(df, path, table) {
#   if (table=='question') {
#     js_records <- jsonlite::toJSON(df, 'rows', auto_unbox = TRUE)
#   } else if (table=='axis') {
#     lst <- get_all_records(df)
#     js_records <- jsonlite::toJSON(lst, 'columns', auto_unbox = TRUE)
#   } else {
#     stop('table parameter must be one of \'question\' or \'axis\'')
#   }
#   jsonlite::write_json(js_records, paste0(path, "/", table, ".json"))
# }

