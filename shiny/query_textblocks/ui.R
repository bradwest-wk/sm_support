library(shiny)
library(DT)
library(shinysky)

shinyUI(fluidPage(
  
  titlePanel("Query Text Blocks"),
  
  sidebarLayout(
    sidebarPanel(width = 2,
       textInput('keywords', label = 
                   'Keywords - Comma Delimited/Case Insensitive'),
       textInput('limit', label = 'Max number of Rows/Use this for quicker 
                 querying if you just want a few examples'),
       textInput('element', 'Element (optional)'),
       textInput('sic', label = 'SIC (optional)'),
       textInput('cik', label = 'CIK (optional)'),
       textInput('form_type', label = 'Form Type (optional)'),
       textInput('taxonomy', label = 'Taxonomy (optional)'),
       # selectInput('filer_status', label = 'Filer Status (optional)', 
       #             choices = c('Large Accelerated Filer',
       #                         'Accelerated Filer',
       #                         'Smaller Reporting Company',
       #                         'Non-accelerated Filer',
       #                         'All'), selected = 'All'),
       textInput('creation_software', label = 'Creation Software (optional)'),
       shiny::actionButton('query', 'Execute Query', 
                    style = "color: #fff; background-color: #ff0800; 
                    border-color: #000000")
       
    ),
    
    mainPanel(
      tabsetPanel(id = "inTabset",
        tabPanel("Data",
                 dataTableOutput('results'),
                 busyIndicator(text = "Importing Data"),
                 HTML('<hr style="height:5px;border:none;color:#2a2dc0;
                      background-color:#2a2dc0;">'),
                 tags$div(
                  uiOutput('html_out')
                  )
                 ),
        # tabPanel('Text Block',
        #          tags$div(
        #            uiOutput('html_out')
        #          ),
        #          busyIndicator('Importing Data')
        #         ),
        tabPanel("Instructions", value = 'instructions',
                 tags$div(
                   tags$h3("Summary"),
                   tags$p("This app allows the user to search text blocks for 
                          certain keywords. Currently only 2016 10-Ks are 
                          accessible."),
                   tags$h3("Query Information"),
                   tags$p("The user must specify at least one keyword to search 
                          the text blocks for, Comma delimit keywords, which 
                          precludes you from using commas in the keywords. Also
                          the app will fail if you use apostrophes. The search
                          matches if the textblock contains any of the keywords
                          "),
                   tags$p("None of the other filtering information is needed to 
                          execute a query."),
                   tags$h3("Executing Query"),
                   tags$p("Be patient, there were a lot of footnotes in 
                          2016 10-Ks."),
                   tags$h3("Results"),
                   tags$p("There are two tabs, 'Data' and 'Text Block'.  
                          The data shows the metadata of the text block.  You 
                          can sort on each column, and filter. If you click 
                          on a row, the 'Text Block' tab is populated with the 
                          text block for that row. I know this a bit of an 
                          unweildly interface, and I'll try to change
                          it into something a bit more cohesisve."),
                   tags$h3("Other"),
                   tags$p("The html text blocks for the files should be in the 
                          level_1_html file in the Google Drive Project 
                          Management folder. If you'd like functionality to
                          download the html file, let me know. I'll try to add 
                          it anyway, but I might not get around to it for a 
                          while."),
                   tags$p("As always, let me know when things go wrong and 
                          I'll try to fix them.")
                 ),
                 busyIndicator("Importing Data")
          
        ),
        selected = 'instructions'
      )
    )
  )
))


