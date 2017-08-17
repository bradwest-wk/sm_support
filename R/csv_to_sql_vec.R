# cat a vector of labels into sql format

#' Labels to Elements
#' 
#' Takes a set of concept labels and finds the corresponding concept name
#' from a given taxonomy
#' @param taxonomy The file of the taxonomy
#' @param labels The csv of the labels
#' @param out_file
#' @return A csv file with element names
lbl_to_el <- function(taxonomy, labels, out_file) {
  el <- readxl::read_excel(
    taxonomy, sheet = 1, col_types = "text")[, c("name","label")]
  lbls <- read.csv(labels, stringsAsFactors = FALSE, header = FALSE)
  colnames(lbls) <- "label"
  data <- dplyr::left_join(lbls, el, by = "label")
  readr::write_csv(as.data.frame(data[,2]), out_file, col_names = FALSE)
}


#' CSV to SQL Vector
#' 
#' Concatenates a set of values in csv into a comma separated list of those
#' values with appropriate single quotes.
#' 
#' @param file the input file
#' @param out_file the optional output text file
#' @return the concatenated vector to std output
csv_to_sql_vec <- function(file, out_file = NULL) {
  data <- read.csv(file, stringsAsFactors = FALSE, header = FALSE)[,1]
  my_str <- paste0("\n(", "'", data[1], "')", ",\n")
  for (i in 2:(length(data)-1)) {
    my_str <- paste0(my_str, "('", data[i], "'),\n")
  }
  my_str <- paste0(my_str, "('", data[length(data)], "')\n")
  if (!is.null(out_file)) {
    fileConn <- file(out_file)
    writeLines(my_str, fileConn)
    close(fileConn)
  } else {
    cat(my_str) 
  }
}


#' Append Label Names
#' 
#' Takes a given raw file and joins the correct taxonomy label names to it.
#' 
#' @param file The input raw file
#' @param taxonomy The taxonomy to use
#' @param outfile The outputed file
#' @param check In not null, the given filename will be used to check if all
#' labels are there
#' @return A csv file with label names appended
appnd_label <- function(file, taxonomy, out_file, check = NULL) {
  raw <- readr::read_csv(file)
  tx <- readxl::read_excel(
    taxonomy, sheet = 1, col_types = "text")[, c("name","label")]
  raw <- dplyr::left_join(raw, tx, by = "name")
  raw <- dplyr::select(raw, name, label, company_name, cik, sic, filer_status)
  if (sum(is.na(raw$label)) > 0) {
    warning("Not all names matched to label")
  }
  if (!is.null(check)) {
    data <- read.csv(check, stringsAsFactors = FALSE, header = FALSE)[,1]
    print("...checking labels")
    for (i in 1:length(data)) {
      if (!(data[i] %in% raw$label)) {
        warning(paste(data[i], "not found in dataset"))
      }
    }
    print("...done checking labels")
  }
  readr::write_csv(raw, out_file, col_names = TRUE)
}


# functionalize appnd
letters <- c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
             "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "Y")
for (i in 1:3) {
  file <- paste0("./data/",letters[i], ".csv")
  outfile <- paste0("./data/2016_companies_by_element/",letters[i], "_full.csv")
  appnd_label(file, "./data/Taxonomy_2017Amended.xlsx", outfile)
}
