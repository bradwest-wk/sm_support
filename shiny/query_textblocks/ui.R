library(shiny)
library(DT)

load("./test_html.Rdata")

shinyUI(fluidPage(
  
  # Application title
  titlePanel("Query Text Blocks"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(width = 2,
       h3('DB Connection'),
       # textInput(inputId = "dbserver", label = "Database Server:"),
       # textInput(inputId = "dbname", label = "DB name:"),
       textInput(inputId = "username", label = "DB username:"),
       passwordInput(inputId = "password", label = "DB password:"),
       # numericInput(inputId = "dbport", label = "DB port:", value = 8084),
       # actionButton('connect', "Connect DB",
       #              style = "color: #fff; background-color: #2a2dc0; border-color: #000000"),
       actionButton('query', 'Execute Query', 
                    style = "color: #fff; background-color: #ff0800; border-color: #000000"),
       br(),
       h3('Query Parameters'),
       textInput('keywords', 
                 label = 'Keywords - Comma Delimited/Case Insensitive'
                 # placeholder = 'proboscis monkey, dumbo octopus'
                 ),
       textInput('element', 'Element (optional)', 
                 value = NULL),
       textInput('sic', label = 'SIC (optional)', value = NULL),
       textInput('cik', label = 'CIK (optional)', value = NULL),
       textInput('form_type', label = 'Form Type (optional)', 
                 value = NULL),
       textInput('taxonomy', label = 'Taxonomy (optional)', 
                    value = NULL),
       selectInput('filer_status', label = 'Filer Status (optional)', 
                   choices = c('Large Accelerated Filer',
                               'Accelerated Filer',
                               'Smaller Reporting Company',
                               'Non-accelerated Filer',
                               'All'), selected = 'All'),
       textInput('creation_software', label = 'Creation Software (optional)', value = NULL)
       
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(id = "inTabset",
        tabPanel("Data",
                 dataTableOutput('results')
                 ),
        tabPanel('Text Block',
                 tags$div(
                   uiOutput('html_out')
                 )
                ),
        tabPanel("Instructions", value = 'instructions',
                 tags$div(
                   tags$h3("Summary"),
                   tags$p("This app allows the user to search text blocks for certain keywords.  
                          As of this first iteration, it only
                          supports 2016 fiscal year 10-K filings.  This functionality and
                          the UI will be expanded, time permitting."),
                   tags$h3("Database Connection"),
                   tags$p("The user must specify the connection information. Get this information
                          from a team member, or Brad West. Currently the app does not gracefully
                          handle incorrect information. It will throw an error and crash if the 
                          information is not entered correctly."),
                   tags$h3("Query Information"),
                   tags$p("The user must specify at least one keyword to search the text blocks 
                          for. Keywords should be comma delimited; that precludes you from 
                          using commmas in your keywords. If this is a problem, we can change
                          it up, just let me know. The query searches for text blocks containing any 
                          of the keywords.  If you want blocks with at least two, or all of the 
                          keywords, let me know."),
                   tags$p("None of the other filtering information is needed to execute a query. 
                          Currently the underlying data are composed
                          only of 10-K's but this will be changed at some point or on request."),
                   tags$h3("Executing Query"),
                   tags$p("Be patient, there were a lot of footnotes in 2016 10-Ks."),
                   tags$h3("Results"),
                   tags$p("There are two tabs, 'Data' and 'Text Block'.  The data shows the metadata
                          of the text block.  You can sort on each column, and filter. If you click 
                          on a row, the 'Text Block' tab is populated with the text block for that
                          row. I know this a bit of an unweildly interface, and I'll try to change
                          it into something a bit more cohesisve."),
                   tags$h3("Other"),
                   tags$p("The html text blocks for the files should be in the level_1_html file in 
                          the Google Drive Project Management folder. If you'd like functionality to
                          download the html file, let me know. I'll try to add it anyway, but I might
                          not get around to it for a while."),
                   tags$p("As always, let me know when things go wrong and I'll try to fix them.")
                 )
          
        ),
        selected = 'instructions'
      )
    )
  )
))


