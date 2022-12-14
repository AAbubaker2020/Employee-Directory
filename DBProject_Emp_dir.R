

# Name:  Abuabker Ahmed

###########################################################
#                            Libraries and db connection
###########################################################
library(DT)
library(DBI)
library(RSQLite)
library(shinyjs)
library(shinycssloaders)
library(lubridate)
library(shinyFeedback)
library(dplyr)
library(dbplyr)


# Create database connection
conn <- dbConnect(RSQLite::SQLite(), "employeesdir.db")

# Stop database connection when application stops
shiny::onStop(function() {
  dbDisconnect(conn)
})

# Turn off scientific notation
options(scipen = 999)

# Set spinner type (for loading)
options(spinner.type = 8)









################################################################
#                            Employess _table_module_iu
###############################################################






employees_table_module_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(
        width = 2,
        actionButton(
          ns("add_employee"),
          "Employee",
          class = "btn-success",
          style = "color: #fff;",
          icon = icon('plus'),
          width = '100%'
        ),
        tags$br(),
        tags$br()
      )
    ),
    fluidRow(
      column(
        width = 12,
        title = "Employees Data",
        DTOutput(ns('employees')) %>%
          withSpinner(),
        tags$br(),
        tags$br()
      )
    ),
    tags$script(src = "employees_table_module.js"),
    tags$script(paste0("employees_table_module_js('", ns(''), "')"))
  )
}




################################################################
#                            Employees_table_module_js
###############################################################



employees_table_module_js<- function(ns_prefix) {
  
 ' ("#" + ns_prefix + "employees").on("click", ".delete_btn", function() {
    Shiny.setInputValue(ns_prefix + "employee_id_to_delete", this.id, { priority: "event"});
    (this).tooltip("hide");
  });
  
  ("#" + ns_prefix + "employee").on("click", ".edit_btn", function() {
    Shiny.setInputValue(ns_prefix + "employee_id_to_edit", this.id, { priority: "event"});
    (this).tooltip("hide");
  });'
}




#####################################################
#                emoployees_table_module
####################################################


employees_table_module <- function(input, output, session) {
  
  # trigegr to reload data from the "employees" table
  session$userData$employees_trigger <- reactiveVal(0)
  
  # Read in "employees" table from the database
  employees <- reactive({
    session$userData$employees_trigger()
    
    out <- NULL
    tryCatch({
      out <- conn %>%
        tbl('employees') %>%
        collect() %>%
        mutate(
          created_at = as.POSIXct(created_at, tz = "UTC"),
          modified_at = as.POSIXct(modified_at, tz = "UTC")
        ) %>%
        arrange(desc(modified_at))
    }, error = function(err) {
      
      
      msg <- "Database Connection Error"
      # print `msg` so that we can find it in the logs
      print(msg)
      # print the actual error to log it
      print(error)
      # show error `msg` to user.  User can then tell us about error and we can
      # quickly identify where it cam from based on the value in `msg`
      showToast("error", msg)
    })
    
    out
  })

}





####################################################



'output$employees <- renderDT({
  #req(employees)
  out <- employees
  
  datatable(
    out,
    rownames = FALSE,
    colnames = c("emp_id", "address_id", "name_prefix", "first_name", "middle_inital", "gender", "data_of_join", "salary", "ssn"),
    selection = "none",
    class = "Employees",
    # Escape the HTML in all except 1st column (which has the buttons)
    escape = -1,
    extensions = c("Buttons"),
    options = list(
      scrollX = TRUE,
      dom = ".tooltip",
      buttons = list(
        list(
          extend = "excel",
          text = "Download",
          title = paste0("mtcars-", Sys.Date()),
          exportOptions = list(
            columns = 1:(length(out) - 1)
          )
        )
      ),
      columnDefs = list(
        list(targets = 0, orderable = FALSE)
      ),
      drawCallback = JS("function(settings) {
          // removes any lingering tooltips
          $(".tooltip").remove()
        }")
    )
  ) %>%
    formatDate(
      columns = c("created_at", "modified_at"),
      method = "toLocaleString"
    )
  
})'


#####################################################
#                            IU.R
####################################################






ui <- fluidPage(
  
  shinyFeedback::useShinyFeedback(),
  shinyjs::useShinyjs(),
  # Application Title
  titlePanel(
    h1("Employee Directory App", align = 'center'),
    windowTitle = "Employee Directory App"
  ),
  employees_table_module_ui("employees")
)




#####################################################
#                            SERVER.R
####################################################


server <- function(input, output, session) {
  
    
    # Use session$userData to store user data that will be needed throughout
    # the Shiny application
    session$userData$email <- 'AAbubaker@live.com'
    
    # Call the server function portion of the `employees_table_module.R` module file
    callModule(
      employees_table_module,
      "employees"
    )
  }

shinyApp(ui, server)
  
