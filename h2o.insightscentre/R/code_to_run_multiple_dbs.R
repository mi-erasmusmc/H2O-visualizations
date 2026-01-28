#' Run pipeline across multiple databases and combine results
#'
#' @param dbNames Character vector of database schema suffixes (used in server path)
#' @param dbms DBMS type
#' @param server Base server (without trailing /db)
#' @param user Username
#' @param password Password
#' @param port Port
#' @param pathToDriver Path to JDBC driver folder
#' @param baseDatabaseSchema Base schema name (each db will use this schema unless varied)
#' @param sqlDialect Target SQL dialect
#' @param finalResultsDir Directory for combined results
#' @param plotsDirectory Directory for plots
#' @export
run_pipeline_multiple_dbs <- function(dbNames,
                                      dbms = "postgresql",
                                      server = "localhost/postgres",
                                      user = "postgres",
                                      password = "password",
                                      port = 5434,
                                      pathToDriver = "/home/ewelina/projects/vantage6/H2O-visualizations/driver/",
                                      baseDatabaseSchema = "omopcdm_synthetic",
                                      sqlDialect = "postgresql",
                                      finalResultsDir = "results",
                                      plotsDirectory = "plots") {
  if (!dir.exists(finalResultsDir)) dir.create(finalResultsDir, recursive = TRUE)
  if (!dir.exists(plotsDirectory)) dir.create(plotsDirectory, recursive = TRUE)

  tempDirs <- character(0)

  for (db in dbNames) {
    # per-db results temp folder
    perResults <- file.path(paste0("results", db))
    dir.create(perResults, showWarnings = FALSE, recursive = TRUE)
    tempDirs <- c(tempDirs, perResults)

    # Connect to the db
    connectionDetails <- DatabaseConnector::createConnectionDetails(
      dbms = dbms,
      server = paste0(server, "/", db),
      user = user,
      password = password,
      port = port,
      pathToDriver = pathToDriver
    )

    connection <- DatabaseConnector::connect(connectionDetails)

    # Build resources
    cs <- concept_sets(connection = connection, databaseSchema = baseDatabaseSchema, sqlDialect = sqlDialect)
    ct <- conversion_tables()

    # Run stats into perResults
    statistics_insights_centre(
      connection = connection,
      databaseSchema = baseDatabaseSchema,
      resultsDirectory = perResults,
      sqlDialect = sqlDialect,
      conceptSets = cs,
      conversionTables = ct
    )

    statistics_PROMIS_GLOBAL_10(
      connection = connection,
      databaseSchema = baseDatabaseSchema,
      resultsDirectory = perResults,
      sqlDialect = sqlDialect,
      conceptSets = cs,
      conversionTables = ct
    )

    DatabaseConnector::disconnect(connection)
  }

  # Combine results
  combine_results(dbNames = dbNames, tempPrefix = "results", finalResultsDir = finalResultsDir)

  # Clean temp dirs
  for (d in tempDirs) unlink(d, recursive = TRUE)

  # Plots
  visualizations_insights_centre(resultsDirectory = finalResultsDir, plotsDirectory = plotsDirectory)
  visualizations_PROMIS_GLOBAL_10(resultsDirectory = finalResultsDir, plotsDirectory = plotsDirectory)
}
