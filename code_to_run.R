###Libraries required-----------------------------------------------------------
#install.packages('DatabaseConnector')
#install.packages('dplyr')
#install.packages('ggplot2')
#install.packages('viridis')
library(DatabaseConnector)
library(SqlRender)
library(dplyr)
library(ggplot2)
library(viridis)


### Create the connection & output directory------------------------------------
#Set working directory to the H2O folder
#setwd("~/H2O")

#Create results directory
resultsDirectory <- "results"
dir.create(resultsDirectory)
plotsDirectory <- "plots"
dir.create(plotsDirectory)

#Variables
dbms <- "postgresql"
server <- "localhost/postgres"
user <- "postgres"
password <- "password"
port <- 5434
pathToDriver <- system.file("driver", package = "h2o.insightscentre")

databaseSchema <- "omopcdm_synthetic"
sqlDialect <- "postgresql"
#supported dialects: 
#sqlserver, oracle, postgresql, pdw, impala, netezza, bigquery, spark, sqlite, 
#redshift, hive, sqliteextended, duckdb, snowflake, synapse, iris


#Connect to the db
#https:://ohdsi.github.io/DatabaseConnector/articles/Connecting.html
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = dbms,
  server = server,
  user = user,
  password = password,
  port = port,
  pathToDriver = pathToDriver
)

connection <- DatabaseConnector::connect(connectionDetails)


###Collect the relevant data----------------------------------------------------
source("./concept_sets.R")
source("./conversion_tables.R")
source("./statistics_insights_centre.R")
source("./statistics_PROMIS_GLOBAL_10.R")

disconnect(connection)

###Create plots-----------------------------------------------------------------
source("./visualizations_insights_centre.R")
source("./visualizations_PROMIS_GLOBAL_10.R")
