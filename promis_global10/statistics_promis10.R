###PROMIS_GLOBAL_10 questionnaire (all questions)-------------------------------
###PROMIS_10 questionnaire concepts---------------------------------------------
promis10Concepts <- c(
  40764338, 40764339, 40764340, 40764341, 40764342,
  40764343, 40764344, 40764345, 40764346, 40764347
)

dfPromis10 <- querySql(
  connection,
  render(
    sqlPromis10,
    databaseSchema = databaseSchema,
    diseaseConcepts = c(2010000001, 2010000002, 2010000003, 2010000004),
    questionConcepts = questionConcepts
  )
)

names(dfPromis10) <- tolower(names(dfPromis10))

#Group by disease
dfPromis10 <- dfPromis10 %>% 
  mutate(
    disease = case_when(
      disease_concept_id %in% 2010000001 ~ "Diabetes",
      disease_concept_id %in% 2010000002 ~ "IBD",
      disease_concept_id %in% 2010000003 ~ "Breast cancer",
      disease_concept_id %in% 2010000004 ~ "Lung cancer",
      TRUE                               ~ "Unspecified disease"
    )
  )

#Add the question number to identify the questions easily
dfPromis10 <- dfPromis10 %>%
  left_join(conversionQuestionCTS, by = "question_concept_id")

#Add the answer scale number to perform calculations
dfPromis10 <- dfPromis10 %>%
  left_join(conversionAnswerCTN, by = "answer_concept_id")

# MUW: ave complained about date conversion's origin
dfPromis10$questionnaire_date <- as.numeric(dfPromis10$questionnaire_date)

#Add the time (1st time, 2nd repeat, etc.) a person filled the questionnaire
dfPromis10$answer_time <- ave(
  dfPromis10$questionnaire_date,
  dfPromis10$person_id,
  dfPromis10$question_concept_id,
  FUN = seq_along
)

dfPromis10$answer_time <- as.integer(dfPromis10$answer_time)

### General health score (Only 1st question)------------------------------------
dfPromis10GH <- subset(
  dfPromis10, dfPromis10$question_number == 'Q1'
)

write.csv(
  dfPromis10GH,
  file.path(resultsDirectory,"promis10_general_health_score.csv"),
  row.names = FALSE
)


### Quality of life score (Only 2nd question)-----------------------------------
dfPromis10QL <- subset(
  dfPromis10, dfPromis10$question_number == 'Q2'
)

write.csv(
  dfPromis10QL,
  file.path(resultsDirectory, "promis10_quality_life_score.csv"),
  row.names = FALSE
)


### Physical health score (Only 3rd, 6th, 7th and 8th questions)----------------
dfPromis10PH <- subset(
  dfPromis10, dfPromis10$question_number %in% c('Q3', 'Q6', 'Q7RC', 'Q8R')
)

dfPromis10PHTotal <- dfPromis10PH %>%
  group_by(person_id, answer_time, disease) %>%
  summarise(total_score = sum(answer_value, na.rm = TRUE),
            .groups = "drop")

write.csv(
  dfPromis10PHTotal,
  file.path(resultsDirectory, "promis10_physical_health_total_score.csv"),
  row.names = FALSE
)


### Mental health score (Only 2nd, 4th, 5th and 10th questions)-----------------
dfPromis10MH <- subset(
  dfPromis10, dfPromis10$question_number %in% c('Q2', 'Q4', 'Q5', 'Q10R')
)

dfPromis10MHTotal <- dfPromis10MH %>%
  group_by(person_id, answer_time, disease) %>%
  summarise(total_score = sum(answer_value, na.rm = TRUE),
            .groups = "drop")

write.csv(
  dfPromis10MHTotal,
  file.path(resultsDirectory, "promis10_mental_health_total_score.csv"),
  row.names = FALSE
)
