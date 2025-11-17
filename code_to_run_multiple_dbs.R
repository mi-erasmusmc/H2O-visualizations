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
dbNames <- c("db1","db2","db3","db4")

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
      server = paste0(server,"/", db),
      user = user,
      password = password,
      port = port,
      pathToDriver = pathToDriver
    )
    
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  
  ###Collect the relevant data--------------------------------------------------
  source("R/concept_sets.R")
  source("R/conversion_tables.R")
  source("R/statistics_insights_centre.R")
  source("R/statistics_PROMIS_GLOBAL_10.R")

  disconnect(connection)
}
resultsDirectory = resultsDir

###Combine results--------------------------------------------------------------
source("R/combine_results.R")

#Delete the separate folders
for (db in dbNames){
  resultsDirectory <- paste0(resultsDir, db)
  unlink(resultsDirectory, recursive=TRUE)
  }


###Create plots-----------------------------------------------------------------
resultsDirectory = resultsDir
source("R/visualizations_insights_centre.R")
source("R/visualizations_PROMIS_GLOBAL_10.R")
