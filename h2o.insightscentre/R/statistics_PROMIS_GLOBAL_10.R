#' Compute PROMIS Global 10 derived datasets and export CSVs
#'
#' @param connection An active DatabaseConnector connection
#' @param databaseSchema CDM schema
#' @param resultsDirectory Directory to write CSV outputs
#' @param sqlDialect Target SQL dialect (default: "postgresql")
#' @param conceptSets List from concept_sets()
#' @param conversionTables List from conversion_tables()
#'
#' @export
statistics_PROMIS_GLOBAL_10 <- function(connection,
                                        databaseSchema,
                                        resultsDirectory,
                                        sqlDialect = "postgresql",
                                        conceptSets,
                                        conversionTables) {
  # Unpack concept sets
  diabetesCS     <- conceptSets$diabetesCS
  ibdCS          <- conceptSets$ibdCS
  bcCS           <- conceptSets$bcCS
  lcCS           <- conceptSets$lcCS
  questionConcepts <- conceptSets$questionConcepts

  # Unpack conversion tables
  conversionQuestionCTS <- conversionTables$conversionQuestionCTS
  conversionAnswerCTN   <- conversionTables$conversionAnswerCTN

  # 1) RAW SQL template (render first, then translate)
  sql_template <- "
   with disease as (
       select distinct on (person_id)
              condition_occurrence.person_id,
              condition_occurrence.condition_concept_id,
              condition_occurrence.condition_start_date
       from @databaseSchema.condition_occurrence
       join @databaseSchema.concept
           on condition_occurrence.condition_concept_id = concept.concept_id
       where {@diseaseConcepts == ''} ? {1 = 0} : {condition_occurrence.condition_concept_id in (@diseaseConcepts)}
   ), response as (
       select person_id,
              observation_concept_id, value_as_concept_id,
              observation_date
       from @databaseSchema.observation
       where {@questionConcepts == ''} ? {1 = 0} : {observation_concept_id in (@questionConcepts)}
   )
   select response.person_id,
       response.observation_concept_id as question_concept_id,
       response.value_as_concept_id as answer_concept_id,
       response.observation_date as questionnaire_date,
       disease.condition_concept_id as disease_concept_id,
       disease.condition_start_date as disease_first_diagnosis_date
   from response
   left join disease
       on disease.person_id = response.person_id
   order by response.person_id, response.observation_date asc"

  sql_rendered <- SqlRender::render(
    sql_template,
    databaseSchema = databaseSchema,
    diseaseConcepts = paste0(c(diabetesCS$concept_id, ibdCS$concept_id,
                               bcCS$concept_id, lcCS$concept_id),
                             collapse = ","),
    questionConcepts = paste0(questionConcepts, collapse = ",")
  )

  sql_translated <- SqlRender::translate(sql_rendered, targetDialect = sqlDialect)

  dfPromis10 <- DatabaseConnector::querySql(connection, sql_translated)
  names(dfPromis10) <- tolower(names(dfPromis10))

  # Group by disease name
  dfPromis10 <- dplyr::mutate(
    dfPromis10,
    disease = dplyr::case_when(
      dfPromis10$disease_concept_id %in% diabetesCS$concept_id ~ "Diabetes",
      dfPromis10$disease_concept_id %in% ibdCS$concept_id      ~ "IBD",
      dfPromis10$disease_concept_id %in% bcCS$concept_id       ~ "Breast cancer",
      dfPromis10$disease_concept_id %in% lcCS$concept_id       ~ "Lung cancer",
      TRUE                                                     ~ "Unspecified disease"
    )
  )

  # Add question numbers and answer numeric scale
  dfPromis10 <- dplyr::left_join(dfPromis10, conversionQuestionCTS, by = "question_concept_id")
  dfPromis10 <- dplyr::left_join(dfPromis10, conversionAnswerCTN,   by = "answer_concept_id")

  # Add answer_time (sequence number per person/question)
  dfPromis10$answer_time <- ave(
    dfPromis10$questionnaire_date,
    interaction(dfPromis10$person_id, dfPromis10$question_concept_id, drop = TRUE),
    FUN = seq_along
  )
  dfPromis10$answer_time <- as.integer(dfPromis10$answer_time)

  # General health (Q1)
  dfPromis10GH <- subset(dfPromis10, dfPromis10$question_number == 'Q1')
  utils::write.csv(dfPromis10GH,
                   file.path(resultsDirectory, "promis10_general_health_score.csv"),
                   row.names = FALSE)

  # Quality of life (Q2)
  dfPromis10QL <- subset(dfPromis10, dfPromis10$question_number == 'Q2')
  utils::write.csv(dfPromis10QL,
                   file.path(resultsDirectory, "promis10_quality_life_score.csv"),
                   row.names = FALSE)

  # Physical health (Q3, Q6, Q7RC, Q8R)
  dfPromis10PH <- subset(dfPromis10, dfPromis10$question_number %in% c('Q3', 'Q6', 'Q7RC', 'Q8R'))
  dfPromis10PHTotal <- dfPromis10PH |>
    dplyr::group_by(person_id, answer_time, disease) |>
    dplyr::summarise(total_score = sum(answer_value, na.rm = TRUE), .groups = "drop")
  utils::write.csv(dfPromis10PHTotal,
                   file.path(resultsDirectory, "promis10_physical_health_total_score.csv"),
                   row.names = FALSE)

  # Mental health (Q2, Q4, Q5, Q10R)
  dfPromis10MH <- subset(dfPromis10, dfPromis10$question_number %in% c('Q2', 'Q4', 'Q5', 'Q10R'))
  dfPromis10MHTotal <- dfPromis10MH |>
    dplyr::group_by(person_id, answer_time, disease) |>
    dplyr::summarise(total_score = sum(answer_value, na.rm = TRUE), .groups = "drop")
  utils::write.csv(dfPromis10MHTotal,
                   file.path(resultsDirectory, "promis10_mental_health_total_score.csv"),
                   row.names = FALSE)

  invisible(list(
    dfPromis10 = dfPromis10,
    dfPromis10GH = dfPromis10GH,
    dfPromis10QL = dfPromis10QL,
    dfPromis10PHTotal = dfPromis10PHTotal,
    dfPromis10MHTotal = dfPromis10MHTotal
  ))
}
