library(shiny)
library(DT)
library(RPostgreSQL)
library(pool)



shinyServer(function(input, output, session) {
  
  rv <- reactiveValues(db_return = NULL)
  
  # ====
  # Connection and Query
  # ====
  observeEvent(input$query, {

    updateTabsetPanel(session, "inTabset", selected = 'Data')
    
    # if (input$dbserver == "") {showNotification('Enter a Host')}
    # if (input$dbname == "") {showNotification('Enter a Database')}
    if (input$username == "") {showNotification('Enter a Username')}
    if (input$password == "") {showNotification('Enter a Password')}
    # if (input$port == "") {showNotification('Enter a Port')}
    if (input$keywords == "") {showNotification('Enter keyword(s)')}
   
    # connect
    con <- dbConnect(PostgreSQL(), host='***',
                     port='***',
                     user=input$username,
                     password=input$password,
                     dbname='***')
    
    req(input$keywords, input$username, input$password)
    
    # query
    query <- paste(
      "SELECT * FROM _mv_textblocks
      WHERE value ~*",
      paste0('\'(', paste0(trimws(
        strsplit(input$keywords, ',')[[1]]), collapse = "|"), ')\''),
      if (input$element != "") {paste0("AND name = '", input$element, "'\n")},
      if (input$sic != "") {paste0("AND sic = ", input$sic, "\n")},
      if (input$cik != "") {paste0("AND cik = '", input$cik, "'\n")},
      if (input$form_type != "") {paste0("AND form_type = '", input$form_type, 
                                         "'\n")},
      if (input$taxonomy != "") {paste0("AND taxonomy = '", input$taxonomy, 
                                        "'\n")},
      if (input$filer_status != "All") {paste0("AND filer_status = '", 
                                            input$filer_status, "'\n")},
      if (input$creation_software != "") {paste0("AND creation_software = '",
                                                 input$creation_software,
                                                 "'\n")},
    ";"
    )
    # make sure it closes connection
    # on.exit(dbDisconnect(con), add = TRUE)
    
    # execute query
    rv$db_return <- dbGetQuery(pool, query)
    
  })

  # ==== 
  # Table Output
  # ====
  
  
  output$results <- renderDataTable({
    # TODO Add case when no results
    if (nrow(rv$db_return)==0) {
      data.frame(Whoops = c("No results found"))
    } else {
      datatable(rv$db_return[, c(10, 1:8)], 
                selection = list(mode = 'single', selected = 1, target = 'row')
      )
    }
  },
  server = FALSE)
  
  # ====
  # HTML Output
  # ====
  output$html_out <- renderUI({
    if (!is.null(rv$db_return)) {
      HTML(rv$db_return$value[input$results_rows_selected]) 
    } else {
      tags$p('Execute a query first')
    }
  })
  
})

# TODO: Multiple html files for display
# TODO: css style sheet
# TODO: Add all documents
# TODO: disappearing sidebar after pinning database (login button?)
# TODO: Specify element level
# TODO: Switch to data tab after query exectutes
# TODO: Use isPostgresqlIdCurrent
# TODO: Use pool to
# TODO: Try catch for database connection issues
# TODO: Write the query with dplyr
# TODO: Better logs with dbGetInfo
# TODO: Can you change it up so that when shiny opens it brings the data into memory?