#' Example helper to run the full pipeline with default configuration
#'
#' This function is provided as a convenience wrapper around run_pipeline().
#' It is not executed automatically on package load.
#'
#' @export
example_run_pipeline <- function() {
  run_pipeline(
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
  )
}
