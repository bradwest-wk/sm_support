# Functions for creating flat files for loading questions database

# In the shared sheets (e.g. ASC 225 Income Statement), the ultimate format of
# the data are in the `Checklist/Taxonomy Query` tab.  These data are derived
# from the `Disclosure Requirements` tab, and filtered to include only those
# rows that have questions.

# This file defines functions for pulling the data from the given sheet, 
# splitting the data into tables that correspond to the PostgresDB, and user
# defining the primary and foreign keys for those tables

library(tidyverse)

#' Get Disclosure Requirements
#' 
#' Accesses the google sheets workbook and the correct sheet, returning a 
#' dataframe
#' 
#' @param id The title or key of the spreadsheet
#' @param id_type the type of the identifier one of 'title' or 'key'
#' @param tab The specific tab wished to grab
#' @param taxonomy The applicable taxonomy
#' @return a dataframe
sheet_to_df <- function(id, id_type, tab, taxonomy) {
  if (id_type == 'title') {
    sht <- googlesheets::gs_title(id, verbose = FALSE)  
  } else if (id_type == 'key') {
    sht <- googlesheets::gs_key(id, verbose = FALSE)
  } else {
    stop('id_type must be one of title or key')
  }
  df <- googlesheets::gs_read(sht, ws = tab)
  df <- df[, c(2,3,4,11,13,16,17,18,19,20,21,22,23,24)]
  dscl_vec <- rep(sht$sheet_title, nrow(df))
  tx_vec <- rep(taxonomy, nrow(df))
  unit_vec <- rep(NA, nrow(df))
  axis_vec <- rep(NA, nrow(df))
  axis_namespace <- rep(NA, nrow(df))
  mbr_vec <- rep(NA, nrow(df))
  mbr_namespace <- rep(NA, nrow(df))
  df <- cbind.data.frame(dscl_vec, tx_vec, df, unit_vec, axis_vec, 
                         axis_namespace, mbr_vec, mbr_namespace, 
                         stringsAsFactors = FALSE)
  colnames(df) <- c('disclosure', 'taxonomy', 'asc_paragraph_ref1', 'sx_paragraph_ref', 
                    'asc_paragraph_ref2', 'ref_id', 'question', 'presentation_parent', 
                    'calculation_parent', 'element_name',
                    'element_label', 'balance_type', 'period_type', 'data_type',
                    'namespace', 'definition', 'unit', 'axis_name', 
                    'axis_namespace', 'member_name', 
                    'member_namespace')
  # need to sort so that get_single_record works
  df <- df %>% arrange(disclosure, element_name, question, axis_name)
  df
}


#' Filter Rows without Elements and Questions
#' 
#' Because every question is associated with only one element (by taxonomy
#' design), the rows without elements are incomplete.  We can exclude them
#'  
#' @param df The dataframe (usually from \code{sheet_to_df}) that should have
#' its rows filtered
#' @return A df with complete element name field
filter_no_elements <- function(df) {
  df <- dplyr::filter(df, !is.na(element_name) & !is.na(question))
  df <- df[!duplicated(df), ] # get rid of potentially duplicated columns
  df
}


#' Add Unique IDs
#' 
#' Adds user defined sequences to the df as a replacement for primary keys in
#' a RDBMS. We need four sequences of ids, element_id, question_id, axis_id, 
#' and member_id.  They cannot overlap, and we need to be able to add them to 
#' the db in a way that each add to the db does not overwrite the current 
#' element names.  One way is to hash the element and question strings as they
#' will be unique. Axis names will not be unique, but users can join elements
#' to the axis table by element_id.  In turn they can join the member and axis
#' tables by element_id, axis_id ensuring that there is only one combination
#' of axis and element for that member. In practice, element names need not be
#' unique due to extensions, however element namespaces should be unique.  The
#' hash functions are run on the element namespaces for this reason.  Hash
#' is
#' 
#' @param df the dataframe to create keys for, with element_namespace, question,
#' axis_namespace, member_namespace fields
#' @return A df with primary keys in place
add_unique_ids <- function(df) {
  
  #' Create Vector of hashed namespace values
  #' 
  #' To use digest function, need to pass it an object individually (i.e. it's 
  #' not vectorized)
  #' @param namespace_vec A vector of namespaces to hash
  #' @return a vector of hashed namespaces as characters
  hash_namespace <- function(namespace_vec) {
    
    #' Helper function for hashing a single string
    hash_one <- function(x) {
      as.character(gmp::as.bigz(
        paste0('0x', digest::digest(x, algo = 'xxhash32'))
      ))
    }
    
    result <- character()
    for (i in 1:length(namespace_vec)) {
      if (!is.na(namespace_vec[i])) {
        result <- c(result, hash_one(namespace_vec[i]))  
      } else {
        result <- c(result, NA)
      }
    }
    
    result
  }
  
  cnames <- colnames(df)
  df <- cbind(df, hash_namespace(df$namespace), 
              hash_namespace(paste0(df$question, df$element_name)), # questions are not unique, but element name and question together should be unique
              hash_namespace(df$axis_namespace), 
              hash_namespace(df$member_namespace))
  colnames(df) <- c(cnames, 'element_id', 'question_id', 'axis_id', 'member_id')
  df
}

#' Split into DB tables
#' 
#' Splits into DB tables based off of user input table name
#' @param df a df with hashed id and whatnot
#' @param table the table of information to get
#' @return A dataframe containing just the desired columns
get_table <- function(df, table) {
  if (!(table %in% c('element', 'question', 'axis', 'member', 
                     'reference', 'disclosure'))) {
    stop("table not recognized")
  } else if (table=='element') {
    tbl <- df %>% 
      select(element_id, element_name, label, period_type, unit, balance_type,
             data_type, namespace, definition)
    tbl <- tbl[!duplicated(tbl), ]
    return(tbl)
  } else if (table=='question') {
    tbl <- df %>%
      select(question_id, element_id, question, disclosure, taxonomy)
    tbl <- tbl[!duplicated(tbl), ]
    return(tbl)
  } else if (table == 'reference') {
    tbl <- df %>%
      select(question_id, asc_ref_1, sx_ref, asc_ref_2)
    tbl <- tbl[!duplicated(tbl), ]
    return(tbl)
  } else if (table == 'disclosure') {
    tbl <- df %>% 
      select(question_id, disclosure)
    tbl <- tbl[!duplicated(tbl), ]
    return(tbl)
  } else if (table == 'axis') {
    tbl <- df %>% 
      select(axis_id, axis_name, axis_namespace, element_id)
    tbl <- tbl[!duplicated(tbl), ]
    return(tbl)
  } else {
    tbl <- df %>% 
      select(member_id, axis_id, element_id, member_name, member_namespace)
    tbl <- tbl[!duplicated(tbl), ]
    return(tbl)
  }
}


#' Write to CSVs
#' 
#' Execute the writes of tables to CSV
#' @param path directory to write tables to
#' @param df dataframe containing all the necessary table information
write_db_tables_csv <- function(df, path) {
  try(
    write.csv(get_table(df, 'element'), file = paste0(path, '/element.csv')
              , row.names = FALSE, na = "NULL")
  )
  try(
    write.csv(get_table(df, 'question'), file = paste0(path, '/question.csv')
              , row.names = FALSE, na = "NULL")
  )
  try(
    write.csv(get_table(df, 'reference'), file = paste0(path, '/reference.csv')
              , row.names = FALSE, na = "NULL")
  )
  try(
    write.csv(get_table(df, 'disclosure'), file = paste0(path, '/disclosure.csv')
              , row.names = FALSE, na = "NULL")
  )
  try(
    write.csv(get_table(df, 'axis'), file = paste0(path, '/axis.csv')
              , row.names = FALSE, na = "NULL")
  )
  try(
    write.csv(get_table(df, 'member'), file = paste0(path, '/member.csv')
              , row.names = FALSE, na = "NULL")
  )
}


