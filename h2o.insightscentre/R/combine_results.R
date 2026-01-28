#' Combine per-database results into a single set of CSVs
#'
#' @param dbNames Character vector of database name suffixes (e.g., c("db1","db2"))
#' @param tempPrefix Prefix for temporary per-db results directories (default: "results")
#' @param finalResultsDir Directory to write the combined results (default: "results")
#' @export
combine_results <- function(dbNames, tempPrefix = "results", finalResultsDir = "results") {
  if (!dir.exists(finalResultsDir)) dir.create(finalResultsDir, recursive = TRUE)

  # Insights centre results -----------------------------------------------------
  # Total persons
  fileName <- "num_persons.csv"
  numPersonsCombined <- NULL
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    colnames(df) <- paste0(colnames(df), "_", db)
    if (is.null(numPersonsCombined)) {
      numPersonsCombined <- df
    } else {
      numPersonsCombined <- cbind(numPersonsCombined, df)
    }
  }
  numPersonsCombined$count <- rowSums(numPersonsCombined)
  utils::write.csv(numPersonsCombined, file.path(finalResultsDir, "num_persons.csv"), row.names = FALSE)

  # Stratified by age
  fileName <- "num_persons_strat_age.csv"
  dfAgeCombined <- NULL
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    commonCol <- "ageGroups"
    otherCol <- setdiff(names(df), commonCol)
    names(df)[names(df) %in% otherCol] <- paste0(colnames(df), "_", db)
    if (is.null(dfAgeCombined)) {
      dfAgeCombined <- df
    } else {
      dfAgeCombined <- merge(dfAgeCombined, df, by = commonCol, all = TRUE)
    }
  }
  dfAgeCombined$n <- rowSums(dfAgeCombined[, names(dfAgeCombined) != "ageGroups"])
  utils::write.csv(dfAgeCombined, file.path(finalResultsDir, "num_persons_strat_age.csv"), row.names = FALSE)

  # Stratified by gender
  fileName <- "num_persons_strat_gender.csv"
  dfGenderCombined <- NULL
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    commonCol <- "gender_concept_name"
    otherCol <- setdiff(names(df), commonCol)
    names(df)[names(df) %in% otherCol] <- paste0(colnames(df), "_", db)
    if (is.null(dfGenderCombined)) {
      dfGenderCombined <- df
    } else {
      dfGenderCombined <- merge(dfGenderCombined, df, by = commonCol, all = TRUE)
    }
  }
  dfGenderCombined$n <- rowSums(dfGenderCombined[, names(dfGenderCombined) != "gender_concept_name"])
  utils::write.csv(dfGenderCombined, file.path(finalResultsDir, "num_persons_strat_gender.csv"), row.names = FALSE)

  # Disease counts
  fileName <- "disease_counts.csv"
  dfDiseaseCombined <- NULL
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    commonCol <- "disease"
    otherCol <- setdiff(names(df), commonCol)
    names(df)[names(df) %in% otherCol] <- paste0(colnames(df), "_", db)
    if (is.null(dfDiseaseCombined)) {
      dfDiseaseCombined <- df
    } else {
      dfDiseaseCombined <- merge(dfDiseaseCombined, df, by = commonCol, all = TRUE)
    }
  }
  dfDiseaseCombined$counts <- rowSums(dfDiseaseCombined[, names(dfDiseaseCombined) != "disease"])
  utils::write.csv(dfDiseaseCombined, file.path(finalResultsDir, "disease_counts.csv"), row.names = FALSE)

  # PROMIS 10 results -----------------------------------------------------------
  # General Health
  fileName <- "promis10_general_health_score.csv"
  dfPromis10GHCombined <- data.frame()
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    dfPromis10GHCombined <- rbind(dfPromis10GHCombined, df)
  }
  utils::write.csv(dfPromis10GHCombined, file.path(finalResultsDir, "promis10_general_health_score.csv"), row.names = FALSE)

  # Quality of life
  fileName <- "promis10_quality_life_score.csv"
  dfPromis10QLCombined <- data.frame()
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    dfPromis10QLCombined <- rbind(dfPromis10QLCombined, df)
  }
  utils::write.csv(dfPromis10QLCombined, file.path(finalResultsDir, "promis10_quality_life_score.csv"), row.names = FALSE)

  # Physical Health
  fileName <- "promis10_physical_health_total_score.csv"
  dfPromis10PHCombined <- data.frame()
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    dfPromis10PHCombined <- rbind(dfPromis10PHCombined, df)
  }
  utils::write.csv(dfPromis10PHCombined, file.path(finalResultsDir, "promis10_physical_health_total_score.csv"), row.names = FALSE)

  # Mental Health
  fileName <- "promis10_mental_health_total_score.csv"
  dfPromis10MHCombined <- data.frame()
  for (db in dbNames) {
    filePath <- file.path(paste0(tempPrefix, db), fileName)
    df <- utils::read.csv(filePath)
    dfPromis10MHCombined <- rbind(dfPromis10MHCombined, df)
  }
  utils::write.csv(dfPromis10MHCombined, file.path(finalResultsDir, "promis10_mental_health_total_score.csv"), row.names = FALSE)
}
