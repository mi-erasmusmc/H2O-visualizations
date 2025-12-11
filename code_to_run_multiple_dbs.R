### Libraries required----------------------------------------------------------
# install.packages('DatabaseConnector')
# install.packages('dplyr')
# install.packages('ggplot2')
# install.packages('viridis')
# install.packages("~/viridis_0.6.5.tar.gz", repos = NULL, type="source")
library(DatabaseConnector)
library(SqlRender)
library(dplyr)
library(ggplot2)
library(viridis)

### Create the connection & output directory------------------------------------
#Set working directory to the H2O folder
setwd("~/H2O")

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
if (file.exists('R/muw.db.R')) {
  source("R/muw.db.R")
}

for (db in dbNames){
  #Create results directory
  resultsDirectory <- paste0(resultsDir, db)
  dir.create(resultsDirectory)
  if (file.exists('R/muw.db.R')) {
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
  source("R/insights_centre/number_of_persons.R")
  source("R/insights_centre/disease_counts.R")
  source("R/insights_centre/therapy_counts.R")
  #Collect the relevant data promis global 10
  source("R/promis_global10/conversion_tables.R")
  source("R/promis_global10/statistics_promis10.R")
  disconnect(connection)
}
resultsDirectory <- resultsDir

###Combine results--------------------------------------------------------------
source("R/extra/combine_results_insights_centre.R")
source("R/extra/combine_results_promis10.R")

#Delete the separate folders
for (db in dbNames){
  resultsDirectory <- paste0(resultsDir, db)
  unlink(resultsDirectory, recursive = TRUE)
}

###Create plots-----------------------------------------------------------------
resultsDirectory <- resultsDir

source("R/insights_centre/visualizations_insights_centre.R")
source("R/promis_global10/visualizations_promis10.R")
# source("R/promis_global10/visualizations_promis10_additional.R")
