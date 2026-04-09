library(tidyr)
library(dplyr)

sqlPAID <- translate(
  "with disease as (
      SELECT 
        person_id, 
        value_as_concept_id
      FROM @databaseSchema.observation
          WHERE observation_concept_id = 44807982
             and value_as_concept_id IN (@diseaseConcepts)
   ), response as (
       select person_id, 
              observation_concept_id, 
              value_as_concept_id,
              observation_date
       from @databaseSchema.observation
       where observation_concept_id in (@questionConcepts)
   )
   select response.person_id,
       response.observation_concept_id as question_concept_id, 
       response.value_as_concept_id as answer_concept_id,
       response.observation_date as questionnaire_date,
       disease.value_as_concept_id as disease_concept_id
   from response
   left join disease
       on disease.person_id = response.person_id
   order by response.person_id, response.observation_date asc",
  targetDialect = sqlDialect
)

# SQL Query to retrieve all required clinical measurements
sqlMeasurements <- translate(
  "select person_id, 
          measurement_concept_id, 
          value_as_number, 
          measurement_date
   from @databaseSchema.measurement
   where measurement_concept_id in (@clinicalConcepts)",
  targetDialect = sqlDialect
)

sqlDiseaseDescendants <-  translate(
  "select concept_id from @databaseSchema.concept_ancestor 
  join @databaseSchema.concept
    on concept_ancestor.descendant_concept_id = concept.concept_id
  where ancestor_concept_id in (@concepts)", 
  targetDialect = sqlDialect
)

#Diabetes Concept Set
diabetesCS <- querySql(
  connection, 
  render(
    sqlDiseaseDescendants, 
    databaseSchema = databaseSchema,
    concepts = c(201826,4193704,4008576,201254)
  )
)
names(diabetesCS) <- tolower(names(diabetesCS))  
diabetesCS <- rbind(diabetesCS, data.frame(concept_id = c(201820,37018196))) 

# Retrieve PROs
dfPAID <- querySql(
  connection,
  render(
    sqlPAID,
    databaseSchema = databaseSchema,
    diseaseConcepts = paste0(c(diabetesCS$concept_id), collapse = ","),
    questionConcepts = questionConcepts
  )
)
names(dfPAID) <- tolower(names(dfPAID))

# Retrieve Clinical Measurements
dfMeasurements <- querySql(
  connection,
  render(
    sqlMeasurements,
    databaseSchema = databaseSchema,
    clinicalConcepts = paste0(clinicalConcepts, collapse = ",")
  )
)
names(dfMeasurements) <- tolower(names(dfMeasurements))

# Group by disease
dfPAID <- dfPAID %>% 
  mutate(disease = "Diabetes")

# Add the question number
dfPAID <- dfPAID %>%
  left_join(conversionQuestionCTS, by = "question_concept_id")

# Add the answer scale number
dfPAID <- dfPAID %>%
  left_join(conversionAnswerCTN, by = "answer_concept_id")

# Convert dates to numeric for distance calculations
dfPAID$questionnaire_date <- as.numeric(as.Date(dfPAID$questionnaire_date))
dfMeasurements$measurement_date <- as.numeric(as.Date(dfMeasurements$measurement_date))


### Join PROs with Clinical Measurements using a  window ------------------
timeWindowDays <- 10


# 1. Find valid clinical matches within the time window and isolate the closest ones
valid_clinical_matches <- dfPAID %>%
  left_join(dfMeasurements, by = "person_id", relationship = "many-to-many") %>%
  mutate(date_diff = abs(questionnaire_date - measurement_date)) %>%
  # Keep ONLY matches within the 7 day window
  filter(!is.na(date_diff) & date_diff <= timeWindowDays) %>%
  # Group by person, question, and measurement concept to isolate the absolute closest record
  group_by(person_id, question_concept_id, questionnaire_date, measurement_concept_id) %>%
  arrange(date_diff, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  select(person_id, question_concept_id, questionnaire_date, measurement_concept_id, value_as_number)

# 2. Pivot valid measurements and merge back to the unaltered PRO data
if (nrow(valid_clinical_matches) > 0) {
  clinical_wide <- valid_clinical_matches %>%
    pivot_wider(
      names_from = measurement_concept_id, 
      values_from = value_as_number,
      names_prefix = "clinical_concept_"
    )
  
  # By left joining back to the original dfPAID, we NEVER drop a PRO visit.
  # Visits without a valid clinical match will safely just get NA.
  dfPAID <- dfPAID %>%
    left_join(clinical_wide, by = c("person_id", "question_concept_id", "questionnaire_date"))
}

# Apply naming conventions to mapping (any_of safely ignores missing ones)
dfPAID <- dfPAID %>%
  rename(
    any_of(c(
      hba1c_value               = "clinical_concept_3004410",
      total_cholesterol_value   = "clinical_concept_4008265",
      ldl_cholesterol_value     = "clinical_concept_2212287",
      hdl_cholesterol_value     = "clinical_concept_2212449",
      triglycerides_value       = "clinical_concept_4017787",
      systolic_bp_value         = "clinical_concept_4152194",
      diastolic_bp_value        = "clinical_concept_4154790" 
    ))
  )

# Add answer time (1st time, 2nd repeat, etc.) - NOW ACCURATE FOR ALL VISITS
dfPAID$answer_time <- ave(
  dfPAID$questionnaire_date,
  dfPAID$person_id,
  dfPAID$question_concept_id,
  FUN = seq_along
)

dfPAID$answer_time <- as.integer(dfPAID$answer_time)

### Write standard CSV outputs ------------------------------------

# 1st question
dfPAID5_1 <- subset(dfPAID, dfPAID$question_number == '5_1')
write.csv(dfPAID5_1, file.path(resultsDirectory,"5_1_mix.csv"), row.names = FALSE)

# 2nd question
dfPAID5_2 <- subset(dfPAID, dfPAID$question_number == '5_2')
write.csv(dfPAID5_2, file.path(resultsDirectory, "5_2_mix.csv"), row.names = FALSE)

# 3rd question
dfPAID5_3 <- subset(dfPAID, dfPAID$question_number == '5_3')
write.csv(dfPAID5_3, file.path(resultsDirectory,"5_3_mix.csv"), row.names = FALSE)

# 4th question
dfPAID5_4 <- subset(dfPAID, dfPAID$question_number == '5_4')
write.csv(dfPAID5_4, file.path(resultsDirectory, "5_4_mix.csv"), row.names = FALSE)

# 5th question
dfPAID5_5 <- subset(dfPAID, dfPAID$question_number == '5_5')
write.csv(dfPAID5_5, file.path(resultsDirectory, "5_5_mix.csv"), row.names = FALSE)