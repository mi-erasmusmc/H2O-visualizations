### Clean environment, memory, and consoles ------------------------------------
# clean all environment variables 
rm(list = ls(all.names = TRUE))
# free memory
gc()
#clean the consoles
cat("\014")

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
setwd("~/H2O-visualizations")

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
  dbms = "",
  server = "",
  user = "",
  password = "",
  port = 5432,
  pathToDriver = ""
)

connection <- DatabaseConnector::connect(connectionDetails)

###Collect the relevant data insights centre------------------------------------
# source("insights_centre/number_of_persons.R")
# source("insights_centre/sql_queries.R")
# source("insights_centre/disease_counts.R")
# source("insights_centre/therapy_counts.R")
# source("insights_centre/diagnostics_counts.R")
# ###Collect the relevant data promis global 10-----------------------------------
# source("promis_global10/conversion_tables.R")
# source("promis_global10/statistics_promis10.R")

##Collect the relevant data PAID5
source(file.path(getwd(), "PAID5/01_conversion_tables.R"))
source(file.path(getwd(), "PAID5/01_collect_PRO_and_clinical.R"))

disconnect(connection)

#If results from multiple sites available---------------------------------------
# source("R/extra/combine_results_insights_centre.R")
# source("R/extra/combine_results_promis10.R")

## Aggregate Results for Exchange
source(file.path(getwd(), "PAID5/02_aggregate_PRO.R"))
source(file.path(getwd(), "PAID5/03_aggregate_clinical.R"))

###Create plots insights centre-------------------------------------------------
# source("insights_centre/visualizations_insights_centre.R")
# # source("R/insights_centre/visualizations_insights_centre_additional.R")
# 
# ###Create plots promis global 10------------------------------------------------
# source("promis_global10/visualizations_promis10.R")
# # source("R/promis_global10/visualizations_promis10_additional.R")

source(file.path(getwd(), "PAID5/02_visualize_agg_PRO.R"))
source(file.path(getwd(), "PAID5/03_visualize_clinical.R"))
