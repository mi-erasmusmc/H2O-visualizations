###Libraries required-----------------------------------------------------------
#install.packages('DatabaseConnector')
#install.packages('SqlRender')
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
setwd("~/H2O")

#Create results directory
resultsDirectory <- "results"
dir.create(resultsDirectory)
plotsDirectory <- "plots"
dir.create(plotsDirectory)

#Variables
dbms <- ""
server <- ""
user <- ""
password <- ""
port <- 
pathToDriver <- ""

databaseSchema <- ""
sqlDialect <- ""
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

###Collect the relevant data insights centre------------------------------------
source("R/insights_centre/number_of_persons.R")
source("R/insights_centre/sql_queries.R")
source("R/insights_centre/disease_counts.R")
source("R/insights_centre/therapy_counts.R")
source("R/insights_centre/diagnostics_counts.R")
###Collect the relevant data promis global 10-----------------------------------
source("R/promis_global10/conversion_tables.R")
source("R/promis_global10/statistics_promis10.R")

disconnect(connection)

#If results from multiple sites available---------------------------------------
# source("R/extra/combine_results_insights_centre.R")
# source("R/extra/combine_results_promis10.R")

###Create plots insights centre-------------------------------------------------
source("R/insights_centre/visualizations_insights_centre.R")
# source("R/insights_centre/visualizations_insights_centre_additional.R")

###Create plots promis global 10------------------------------------------------
source("R/promis_global10/visualizations_promis10.R")
# source("R/promis_global10/visualizations_promis10_additional.R")
