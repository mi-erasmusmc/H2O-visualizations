### Clean environment, memory, and consoles 
# clean all environment variables 
rm(list = ls(all.names = TRUE))
# free memory
gc()
#clean the consoles
cat("\014")



### Create the connection & output directory------------------------------------
#Set working directory to the H2O folder
setwd("~/H2O-visualizations-ADJ")


### Libraries required----------------------------------------------------------
# install.packages('DatabaseConnector')
# install.packages('dplyr')
# install.packages('ggplot2')
# install.packages('viridis')
#install.packages("viridis_0.6.5.tar.gz", repos = NULL, type="source")

if (!require("viridis")) install.packages("viridis_0.6.5.tar.gz", repos = NULL, type = "source")
library(DatabaseConnector)
library(SqlRender)
library(dplyr)
library(ggplot2)
library(viridis)
 


#Pass the separate database names with the relevant data
dbNames <- c("db1", "db2", "db3", "db4")

#Create final results directory (for the combined data)
resultsDir <- "results"
dir.create(resultsDir)
plotsDirectory <- "plots"
dir.create(plotsDirectory)

#Variables
dbms <- ""
server <- ""
user <- ""
password <- ""
port <- ""
pathToDriver <- ""

databaseSchema <- ""
sqlDialect <- ""
#supported dialects:
#sqlserver, oracle, postgresql, pdw, impala, netezza, bigquery, spark, sqlite,
#redshift, hive, sqliteextended, duckdb, snowflake, synapse, iris

### Import MUW db credentials, ignore if not available -------------------------
if (file.exists(file.path(getwd(), 'muw.db.R'))) {
  source(file.path(getwd(), 'muw.db.R'))
}

db <- dbNames[1]
  #Create results directory
  resultsDirectory <- paste0(resultsDir, db)
  dir.create(resultsDirectory)
  if (file.exists(file.path(getwd(), 'muw.db.R'))) {
    #Connect to the db: MUW style
    connectionDetails <- DatabaseConnector::createConnectionDetails(
      dbms = dbms,
      connectionString = connectionString,
      user = user[db],
      password = password[db]
    )
    connection <- DatabaseConnector::connect(connectionDetails)
    databaseSchema <- schemas[db]
  } else {
    #Connect to the db
    #https:://ohdsi.github.io/DatabaseConnector/articles/Connecting.html
    connectionDetails <- DatabaseConnector::createConnectionDetails(
      dbms = bdms,
      server = paste0(server, "/", db),
      user = user,
      password = password,
      port = port,
      pathToDriver = pathToDriver
    )
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  
  
  
  
  
  #Collect the relevant data insights centre
  source(file.path(getwd(), "insights_centre/sql_queries.R"))
  source(file.path(getwd(), "insights_centre/number_of_persons.R"))

  # Therapy and disease count are not relevant for the paper
  #source(file.path(getwd(), "insights_centre/disease_counts.R"))
  #source(file.path(getwd(), "insights_centre/therapy_counts.R"))
  
  #Collect the relevant data promis global 10
  source(file.path(getwd(), "promis_global10/conversion_tables.R"))
  source(file.path(getwd(), "promis_global10/statistics_promis10.R"))
  disconnect(connection)

resultsDirectory <- resultsDir


# Copy results from disease folder to "results" folder
mainResultsFolder <- resultsDir
DMResultsFolder <- paste0(resultsDir, db)
file.copy(list.files(DMResultsFolder, full.names = TRUE), mainResultsFolder, overwrite = TRUE)



###Combine results--------------------------------------------------------------

# Adnan 13.02.2026, we don't need to combine results, since we have now only DM, next twos lines are therefore may be commented. 
#source(file.path(getwd(), "extra/combine_results_insights_centre.R"))
#source(file.path(getwd(), "extra/combine_results_promis10.R"))

#Delete the separate folders
resultsDirectory <- paste0(resultsDir, db)
unlink(resultsDirectory, recursive = TRUE)


###Create plots-----------------------------------------------------------------
resultsDirectory <- resultsDir

source(file.path(getwd(), "insights_centre/visualizations_insights_centre.R"))
source(file.path(getwd(), "promis_global10/visualizations_promis10.R"))
# source(file.path(getwd(), "promis_global10/visualizations_promis10_additional.R"))
