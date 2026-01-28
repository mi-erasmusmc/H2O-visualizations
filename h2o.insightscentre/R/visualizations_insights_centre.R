#' Generate Insights Centre plots from computed CSV results
#'
#' @param resultsDirectory Directory where CSV results are stored
#' @param plotsDirectory Directory to write plot images
#' @export
visualizations_insights_centre <- function(resultsDirectory, plotsDirectory) {
  if (!dir.exists(plotsDirectory)) dir.create(plotsDirectory, recursive = TRUE)

  # Total persons (not plotted here but read if needed)
  numPersons <- utils::read.csv(
    file.path(resultsDirectory, "num_persons.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )

  # Stratified by Age
  stratAge <- utils::read.csv(
    file.path(resultsDirectory, "num_persons_strat_age.csv")
  )

  pltAge <-
    ggplot2::ggplot(stratAge, ggplot2::aes(x = n, y = ageGroups, fill = ageGroups)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Number of persons",
      y = "Age group",
      title = "Number of persons stratified by age"
    )
  grDevices::jpeg(file.path(plotsDirectory, "num_persons_strat_age.jpg"))
  print(pltAge)
  grDevices::dev.off()

  # Stratified by Gender
  stratGender <- utils::read.csv(
    file.path(resultsDirectory, "num_persons_strat_gender.csv")
  )

  pltGender <-
    ggplot2::ggplot(stratGender, ggplot2::aes(
      x = n, y = gender_concept_name, fill = gender_concept_name)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Number of persons",
      y = "Gender",
      title = "Number of persons stratified by gender"
    )
  grDevices::jpeg(file.path(plotsDirectory, "num_persons_strat_gender.jpg"))
  print(pltGender)
  grDevices::dev.off()

  # Disease counts
  diseaseCounts <- utils::read.csv(
    file.path(resultsDirectory, "disease_counts.csv")
  )

  pltDisease <-
    ggplot2::ggplot(diseaseCounts, ggplot2::aes(x = counts, y = disease, fill = disease)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      x = "Number of persons",
      y = "H2O disease group",
      title = "Number of persons per disease"
    )
  grDevices::jpeg(file.path(plotsDirectory, "num_persons_disease.jpg"))
  print(pltDisease)
  grDevices::dev.off()
}
