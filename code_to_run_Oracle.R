### Clean environment, memory, and consoles ------------------------------------
# clean all environment variables 
rm(list = ls(all.names = TRUE))
# free memory
gc()
#clean the consoles
cat("\014")



### Create the connection & output directory------------------------------------
# IMPORTANT: you might need to set it for the first time at least
#setwd("H2O-visualizations-ADJ")


### Libraries required----------------------------------------------------------
# install.packages('DatabaseConnector')
# install.packages('dplyr')
# install.packages('ggplot2')
# install.packages('viridis')
# install.packages("viridis_0.6.5.tar.gz", repos = NULL, type="source")

if (!require("viridis")) install.packages("viridis_0.6.5.tar.gz", repos = NULL, type = "source")
#if (!require("tidyverse")) install.packages("tidyverse_2.0.0.tar.gz", repos = NULL, type = "source")

library(DatabaseConnector)
library(SqlRender)
library(dplyr)
library(ggplot2)
library(viridis)




### Import MUW db credentials, ignore if not available -------------------------


#Pass the separate database names with the relevant data
dbNames <- c("db1")

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


if (file.exists(file.path(getwd(), 'muw.db.R'))) {
  source(file.path(getwd(), 'muw.db.R'))
}

my_driver_path <- "C:\\Oracle\\instantclient_21_3"

connectionString1 <- paste0("jdbc:oracle:thin:@//", db_host, ":", db_port, "/", db_service)

db <- dbNames[1]
#Create results directory
resultsDirectory <- paste0(resultsDir, db)
dir.create(resultsDirectory)
#Connect to the db: MUW style
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = dbms,
  connectionString = connectionString1,
  user = db_user,
  password = db_password,
  pathToDriver = my_driver_path  
)
connection <- DatabaseConnector::connect(connectionDetails)
databaseSchema <- schemas[db]







##Collect the relevant data insights centre
#source(file.path(getwd(), "insights_centre/sql_queries.R"))
#source(file.path(getwd(), "insights_centre/number_of_persons.R"))


##Collect the relevant data PAID5
source(file.path(getwd(), "PAID5/01_conversion_tables.R"))
source(file.path(getwd(), "PAID5/01_collect_PRO_and_clinical.R"))

disconnect(connection)

resultsDirectory <- resultsDir


# Copy results from disease folder to "results" folder
mainResultsFolder <- resultsDir
DMResultsFolder <- paste0(resultsDir, db)
file.copy(list.files(DMResultsFolder, full.names = TRUE), mainResultsFolder, overwrite = TRUE)

## Aggregate Results for Exchange
source(file.path(getwd(), "PAID5/02_aggregate_PRO.R"))
source(file.path(getwd(), "PAID5/03_aggregate_clinical.R"))



#Delete the separate folders
resultsDirectory <- paste0(resultsDir, db)
unlink(resultsDirectory, recursive = TRUE)

resultsDirectory <- resultsDir

###Create plots-----------------------------------------------------------------

#source(file.path(getwd(), "insights_centre/visualizations_insights_centre.R"))

source(file.path(getwd(), "PAID5/02_visualize_agg_PRO.R"))
source(file.path(getwd(), "PAID5/03_visualize_clinical.R"))

