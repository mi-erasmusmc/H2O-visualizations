#' Compute basic counts and disease group counts for Insights Centre
#'
#' @param connection An active DatabaseConnector connection
#' @param databaseSchema CDM schema name
#' @param resultsDirectory Directory to write CSV outputs
#' @param sqlDialect Target SQL dialect (default: "postgresql")
#' @param conceptSets List returned by concept_sets()
#' @param conversionTables List returned by conversion_tables()
#'
#' @export
statistics_insights_centre <- function(connection,
                                       databaseSchema,
                                       resultsDirectory,
                                       sqlDialect = "postgresql",
                                       conceptSets,
                                       conversionTables) {
  # Unpack concept sets
  diabetesCS    <- conceptSets$diabetesCS
  ibdCS         <- conceptSets$ibdCS
  bcCS          <- conceptSets$bcCS
  lcCS          <- conceptSets$lcCS
  observationCS <- conceptSets$observationCS

  # Unpack conversion tables
  conversionGenderCTS <- conversionTables$conversionGenderCTS

  # Queries for number of persons ----------------------------------------------
  # Total
  sqlNumPersons <- SqlRender::translate(
    "select count(person_id) from @databaseSchema.person",
    targetDialect = sqlDialect
  )

  numPersons <- DatabaseConnector::querySql(
    connection,
    SqlRender::render(
      sqlNumPersons,
      databaseSchema = databaseSchema
    )
  )

  names(numPersons)[names(numPersons) == "COUNT"] <- "number_of_persons"

  utils::write.csv(
    numPersons,
    file.path(resultsDirectory, "num_persons.csv"),
    row.names = FALSE
  )

  # Stratified by age
  sqlAge <- SqlRender::translate(
    "select person_id, year_of_birth from @databaseSchema.person",
    targetDialect = sqlDialect
  )

  dfAge <- DatabaseConnector::querySql(
    connection,
    SqlRender::render(
      sqlAge,
      databaseSchema = databaseSchema
    )
  )

  names(dfAge) <- tolower(names(dfAge))

  dfAge$calcAge <- as.numeric(format(Sys.Date(), "%Y")) - dfAge$year_of_birth

  dfAge$ageGroups <- cut(dfAge$calcAge, breaks = seq(-1, 100, by = 20))

  utils::write.csv(
    dplyr::count(dfAge, ageGroups),
    file.path(resultsDirectory, "num_persons_strat_age.csv"),
    row.names = FALSE
  )

  # Stratified by gender
  sqlGender <- SqlRender::translate(
    "select person_id, gender_concept_id from @databaseSchema.person",
    targetDialect = sqlDialect
  )

  dfGender <- DatabaseConnector::querySql(
    connection,
    SqlRender::render(
      sqlGender,
      databaseSchema = databaseSchema
    )
  )

  names(dfGender) <- tolower(names(dfGender))

  dfGender <- dplyr::left_join(dfGender, conversionGenderCTS, by = "gender_concept_id")

  utils::write.csv(
    dplyr::count(dfGender, gender_concept_name),
    file.path(resultsDirectory, "num_persons_strat_gender.csv"),
    row.names = FALSE
  )

  # Queries for disease counts --------------------------------------------------
  # Look for the conditions in the Condition Occurrence table or the Observation table and add the counts
  sqlDiseaseCS <- SqlRender::translate(
    "select (
      select count(distinct person_id)
        from @databaseSchema.condition_occurrence
        where {@diseaseConceptSet == ''} ? {1 = 0} : {condition_concept_id in (@diseaseConceptSet)}
      ) 
      + (
      select count(distinct person_id)
        from @databaseSchema.observation
        where {@observationConceptSet == '' | @diseaseConceptSet == ''} ? {1 = 0} : {
          observation_concept_id in (@observationConceptSet)
          and value_as_concept_id in (@diseaseConceptSet)
        }
      ) AS count",
    targetDialect = sqlDialect
  )

  # Diabetes
  diabetesCounts <- DatabaseConnector::querySql(
    connection,
    SqlRender::render(
      sqlDiseaseCS,
      databaseSchema = databaseSchema,
      diseaseConceptSet = paste0(diabetesCS$concept_id, collapse = ","),
      observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
    )
  )

  # Inflammatory Bowel Disease
  ibdCounts <- DatabaseConnector::querySql(
    connection,
    SqlRender::render(
      sqlDiseaseCS,
      databaseSchema = databaseSchema,
      diseaseConceptSet = paste0(ibdCS$concept_id, collapse = ","),
      observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
    )
  )

  # Breast cancer
  bcCounts <- DatabaseConnector::querySql(
    connection,
    SqlRender::render(
      sqlDiseaseCS,
      databaseSchema = databaseSchema,
      diseaseConceptSet = paste0(bcCS$concept_id, collapse = ","),
      observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
    )
  )

  # Lung Cancer
  lcCounts <- DatabaseConnector::querySql(
    connection,
    SqlRender::render(
      sqlDiseaseCS,
      databaseSchema = databaseSchema,
      diseaseConceptSet = paste0(lcCS$concept_id, collapse = ","),
      observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
    )
  )

  # Safely extract COUNT value (default to 0 if query returned no rows or missing)
  safeCount <- function(df) {
    if (is.null(df) || nrow(df) == 0) return(0)
    val <- df[["COUNT"]]
    if (is.null(val) || length(val) == 0 || is.na(val[1])) return(0)
    as.numeric(val[1])
  }

  dCount  <- safeCount(diabetesCounts)
  iCount  <- safeCount(ibdCounts)
  bCount  <- safeCount(bcCounts)
  lCount  <- safeCount(lcCounts)

  dfDiseaseCounts <- data.frame(
    disease = c("diabetes", "ibd", "bc", "lc"),
    counts = c(dCount, iCount, bCount, lCount)
  )

  utils::write.csv(
    dfDiseaseCounts,
    file.path(resultsDirectory, "disease_counts.csv"),
    row.names = FALSE
  )
}
