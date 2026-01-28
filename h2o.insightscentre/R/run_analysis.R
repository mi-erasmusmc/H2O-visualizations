#' Run the full H2O analysis pipeline
#'
#' This function connects to the OMOP CDM database, computes statistics,
#' and generates plots, reproducing the behavior of the original top-level R script.
#'
#' @param dbms The DBMS type (e.g., "postgresql")
#' @param server Server address
#' @param user Username
#' @param password Password
#' @param port Port number
#' @param pathToDriver Path to the JDBC driver directory
#' @param databaseSchema CDM schema name
#' @param resultsDirectory Directory where results are stored
#' @param plotsDirectory Directory where plots are stored
#'
#' @export
run_pipeline <- function(
  dbms = "postgresql",
  server = "localhost/postgres",
  user = "postgres",
  password = "password",
  port = 5434,
  pathToDriver = "/home/ewelina/projects/vantage6/H2O-visualizations/driver/",
  databaseSchema = "omopcdm_synthetic",
  resultsDirectory = "results",
  plotsDirectory = "plots",
  sqlDialect = "postgresql"
) {

  # Directory setup
  if (!dir.exists(resultsDirectory)) dir.create(resultsDirectory, recursive = TRUE)
  if (!dir.exists(plotsDirectory)) dir.create(plotsDirectory, recursive = TRUE)

  # Create connection details
  connectionDetails <- DatabaseConnector::createConnectionDetails(
    dbms = dbms,
    server = server,
    user = user,
    password = password,
    port = port,
    pathToDriver = pathToDriver
  )

  connection <- DatabaseConnector::connect(connectionDetails)

  # ---------------------------
  # Run analysis
  # ---------------------------
  tryCatch({
    # Build concept sets and conversion tables
    cs <- concept_sets(connection = connection, databaseSchema = databaseSchema, sqlDialect = sqlDialect)
    ct <- conversion_tables()

    # Compute statistics
    statistics_insights_centre(
      connection = connection,
      databaseSchema = databaseSchema,
      resultsDirectory = resultsDirectory,
      sqlDialect = sqlDialect,
      conceptSets = cs,
      conversionTables = ct
    )

    statistics_PROMIS_GLOBAL_10(
      connection = connection,
      databaseSchema = databaseSchema,
      resultsDirectory = resultsDirectory,
      sqlDialect = sqlDialect,
      conceptSets = cs,
      conversionTables = ct
    )

  }, finally = {
    # Always disconnect when done
    DatabaseConnector::disconnect(connection)
  })

  # ---------------------------
  # Create plots
  # ---------------------------
  visualizations_insights_centre(resultsDirectory = resultsDirectory, plotsDirectory = plotsDirectory)
  visualizations_PROMIS_GLOBAL_10(resultsDirectory = resultsDirectory, plotsDirectory = plotsDirectory)

  message("Pipeline completed successfully.")
}
