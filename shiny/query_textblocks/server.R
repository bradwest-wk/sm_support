library(shiny)
library(DT)
library(RPostgreSQL)
library(pool)

cred <- Sys.getenv(c('DB_NAME', 'DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD'))

pool <- dbPool(
  drv = RPostgreSQL::PostgreSQL(),
  dbname = cred[1], 
  host = cred[2],
  port = cred[3],
  user = cred[4],
  password = cred[5],
  maxSize = 7, # max size for DBI is 16
  idleTimeout = 360000,
  validateQuery = 'SELECT 1'
)

shinyServer(function(input, output, session) {
  
  rv <- reactiveValues(db_return = NULL)
  # ====
  # Query on action button
  # ====
  observeEvent(input$query, {
    
    # notification for missing keywords
    if (input$keywords == "") {
      showNotification('Need at least one keyword to search for',
                       duration = 10,
                       closeButton = TRUE,
                       id = 'no_keyword',
                       type = 'error')
    }
    req(input$keywords)
    
    # query
    keywords <-  paste0("'(", paste0(
      trimws(strsplit(
        input$keywords,
        # sub("'", "\\\\'", input$keywords), 
        ",")[[1]]), collapse = "|"), ")'")
    
    sql <- paste0(
          "SELECT 
            name,
            company_name,
            cik,
            filer_status,
            sic,
            form_type,
            filing_date,
            taxonomy,
            creation_software,
            value
          FROM _mv_textblocks
          WHERE value ~* ",
          paste0(keywords, " "),
          if (input$element != "") {
            paste0("AND name = '", input$element, "' ")
            },
          if (input$sic != "") {
            paste0("AND sic = ", input$sic)
            },
          if (input$cik != "") {
            paste0("AND cik = '", input$cik, "' ")
            },
          if (input$form_type != "") {
            paste0("AND form_type = '", input$form_type, "' ")
            },
          if (input$taxonomy != "") {
            paste0("AND taxonomy = '", input$taxonomy, "' ")
            },
          # if (input$filer_status != "All") {
          #   paste0("AND filer_status = '", input$filer_status)
          #   },
          if (input$creation_software != "") {
            paste0(" AND creation_software = '", input$creation_software, "' ")
            },
          if (input$limit != "") {
            paste0(" LIMIT ", input$limit)
          },
          ";"
    )
    
    cat(paste('\nExecuting query:\n', sql, "\n"))
    
    updateTabsetPanel(session, "inTabset", selected = 'Data')
    
    # execute query
    rv$db_return <- dbGetQuery(pool, sql)
    
    # log
    cat(paste('\nThe query returned', nrow(rv$db_return),
              'text blocks matching those keywords\n'))
    active_connections <- dbListConnections(PostgreSQL())
    cat(paste('\nActive Connections:', length(active_connections), "\n"))
    
    # handle too many connections
    if (length(active_connections) > 15) {
      lapply(active_connections[1:4], dbDisconnect)
      cat("Connections deleted")
    }
    
  })

  # ==== 
  # Table Output
  # ====
  output$results <- renderDataTable({
    if (nrow(rv$db_return)==0) {
      showNotification('The query executed successfully, but no text blocks 
                       containing the keyword(s) were found.', 
                       duration = 10,
                       closeButton = TRUE,
                       type = 'warning')
      # print for log
      data.frame(Whoops = c("No results found"))
    } else {
      showNotification(paste('The query returned', nrow(rv$db_return),
                             'text blocks matching those keywords'),
                       duration = 20,
                       closeButton = TRUE,
                       type = 'message')
      datatable(rv$db_return[,c('name', 'company_name', 'cik', 'filer_status',
                                'sic', 'form_type', 'filing_date', 'taxonomy',
                                'creation_software')],
                options = list(scrollX = TRUE, pageLength = 5),
                selection = list(mode = 'single', 
                                 selected = 1, 
                                 target = 'row')
      )
    }
  },
  server = FALSE)
  
  # ====
  # HTML Output
  # ====
  output$html_out <- renderUI({
    validate(
      need(!is.null(rv$db_return), 
           message = "No textblock to show, execute a query first")
    )
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
# TODO: Try catch for database connection issues
# TODO: Write the query with dplyr
# TODO: fix multiple filer status'
# TODO: Why does pool not close connections properly?
# TODO: Add download button
# TODO: Style Datatable

# validate(
#   need(try(rv$db_return <- dbGetQuery(pool, sql)),
#        message = "That query could not be executed as is.")
# )
# rv$db_return <- dbGetQuery(pool, sql)
# validate(
#   need(!is.null(rv$db_return),
#        message = "That query could not be executed as is. Make sure your 
#        keywords are as desired, and contain no apostrophes")
# )
# get_data <- function() {
#   df <- tryCatch(
#     {
#       dbGetQuery(pool, sql)
#     },
#     error = function(cond) {
#       message(paste("The query failed for the following keyword(s):",
#                            input$keywords))
#       message("Check that your keywords do not contain apostrophes")
#       message("Here's the original error message:")
#       message(cond)
#       # showNotification(paste(one, two, three, four),
#       #                  duration = 60,
#       #                  closeButton = TRUE,
#       #                  type = 'error')
#       return(NULL)
#     },
#     warning = function(cond) {
#       message(paste("The query returned a warning for the following
#                     keyword(s)", input$keywords))
#       message("Here's the original warning message:")
#       message(cond)
#       return(NULL)
#     }, 
#     finally = print('done querying')
#   )
#   return(df)
# }
# 
# rv$db_return <- get_data()