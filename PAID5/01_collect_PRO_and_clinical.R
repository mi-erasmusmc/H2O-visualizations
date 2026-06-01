library(tidyr)
library(dplyr)

# ==============================================================================
# 0. Global Settings
# ==============================================================================
siteFlag       <- "EMC"             # Set to "MUW" or "EMC"
matchStrategy  <- "closest_overall"   # Set to "strict_window" or "closest_overall"
timeWindowDays <- 100                # Maximum allowable days (only applies if matchStrategy is "strict_window")

# ==============================================================================
# 1. Define SQL Queries
# ==============================================================================

sqlPAID <- translate(
  "with disease as (
      SELECT DISTINCT
        person_id, 
        condition_concept_id
      FROM @databaseSchema.condition_occurrence
          WHERE 1=1
             and condition_concept_id IN (@diseaseConcepts)
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
       disease.condition_concept_id as disease_concept_id
   from response
   left join disease
       on disease.person_id = response.person_id
   order by response.person_id, response.observation_date asc",
  targetDialect = sqlDialect
)

# SQL Query to retrieve all required clinical measurements based on site
if (siteFlag == "MUW") {
  sqlClinical <- translate(
    "select person_id, 
            measurement_concept_id, 
            value_as_number, 
            measurement_date
     from @databaseSchema.measurement
     where measurement_concept_id in (@clinicalConcepts)",
    targetDialect = sqlDialect
  )
  clinicalConceptsToUse <- clinicalConcepts_MUW
} else if (siteFlag == "EMC") {
  # For EMC, fetch from observation but alias to measurement columns
  sqlClinical <- translate(
    "select person_id, 
            measurement_concept_id, 
            value_as_number, 
            measurement_date
     from @databaseSchema.measurement
     where measurement_concept_id in (@clinicalConcepts)",
    #"select person_id, 
    #        observation_concept_id as measurement_concept_id, 
    #        value_as_number, 
    #        observation_date as measurement_date
    # from @databaseSchema.observation
    # where observation_concept_id in (@clinicalConcepts)",
    targetDialect = sqlDialect
  )
  clinicalConceptsToUse <- clinicalConcepts_EMC
} else {
  stop("Invalid siteFlag. Must be 'MUW' or 'EMC'.")
}

sqlDiseaseDescendants <-  translate(
  "select concept_id from @databaseSchema.concept_ancestor 
  join @databaseSchema.concept
    on concept_ancestor.descendant_concept_id = concept.concept_id
  where ancestor_concept_id in (@concepts)", 
  targetDialect = sqlDialect
)

# ==============================================================================
# 2. Execute Queries and Retrieve Data
# ==============================================================================

# Diabetes Concept Set
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

# Retrieve Clinical Values
dfMeasurements <- querySql(
  connection,
  render(
    sqlClinical,
    databaseSchema = databaseSchema,
    clinicalConcepts = paste0(clinicalConceptsToUse, collapse = ",")
  )
)
names(dfMeasurements) <- tolower(names(dfMeasurements))

# ==============================================================================
# 3. Process and Clean Data
# ==============================================================================

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


# ==============================================================================
# 4. Join PROs with Clinical Values based on Match Strategy
# ==============================================================================

# 1. Base join: calculate distance for all possible matches
clinical_matches_base <- dfPAID %>%
  left_join(dfMeasurements, by = "person_id", relationship = "many-to-many") %>%
  mutate(date_diff = abs(questionnaire_date - measurement_date)) %>%
  filter(!is.na(measurement_date)) # Drop NAs to prevent errors for patients with zero clinical data

# 2. Apply window filter ONLY if the strict strategy is selected
if (matchStrategy == "strict_window") {
  clinical_matches_base <- clinical_matches_base %>%
    filter(date_diff <= timeWindowDays)
} else if (matchStrategy != "closest_overall") {
  stop("Invalid matchStrategy. Must be 'strict_window' or 'closest_overall'.")
}

# 3. Isolate the absolute closest record
valid_clinical_matches <- clinical_matches_base %>%
  group_by(person_id, question_concept_id, questionnaire_date, measurement_concept_id) %>%
  arrange(date_diff, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  select(person_id, question_concept_id, questionnaire_date, measurement_concept_id, value_as_number)

# 4. Pivot valid measurements and merge back to the unaltered PRO data
if (nrow(valid_clinical_matches) > 0) {
  clinical_wide <- valid_clinical_matches %>%
    pivot_wider(
      names_from = measurement_concept_id, 
      values_from = value_as_number,
      names_prefix = "clinical_concept_"
    )
  
  # By left joining back to the original dfPAID, we NEVER drop a PRO visit.
  dfPAID <- dfPAID %>%
    left_join(clinical_wide, by = c("person_id", "question_concept_id", "questionnaire_date"))
}

# 5. Apply naming conventions dynamically based on the site flag
if (siteFlag == "MUW") {
  rename_map <- c(
    hba1c_value               = paste0("clinical_concept_", hba1cConcept_MUW),
    total_cholesterol_value   = paste0("clinical_concept_", cholesterolTotalConcept_MUW),
    ldl_cholesterol_value     = paste0("clinical_concept_", cholesterolLdlConcept_MUW),
    hdl_cholesterol_value     = paste0("clinical_concept_", cholesterolHdlConcept_MUW),
    triglycerides_value       = paste0("clinical_concept_", triglyceridesConcept_MUW),
    systolic_bp_value         = paste0("clinical_concept_", bpSystolicConcept_MUW),
    diastolic_bp_value        = paste0("clinical_concept_", bpDiastolicConcept_MUW)
  )
} else {
  rename_map <- c(
    hba1c_value               = paste0("clinical_concept_", hba1cConcept_EMC),
    total_cholesterol_value   = paste0("clinical_concept_", cholesterolTotalConcept_EMC),
    ldl_cholesterol_value     = paste0("clinical_concept_", cholesterolLdlConcept_EMC),
    hdl_cholesterol_value     = paste0("clinical_concept_", cholesterolHdlConcept_EMC),
    triglycerides_value       = paste0("clinical_concept_", triglyceridesConcept_EMC),
    systolic_bp_value         = paste0("clinical_concept_", bpSystolicConcept_EMC),
    diastolic_bp_value        = paste0("clinical_concept_", bpDiastolicConcept_EMC)
  )
}

# Apply mapping (any_of safely ignores missing ones)
dfPAID <- dfPAID %>% rename(any_of(rename_map))

# Failsafe: Ensure all expected clinical columns exist in the dataframe 
expected_cols <- names(rename_map)
missing_cols <- setdiff(expected_cols, names(dfPAID))
if(length(missing_cols) > 0) {
  dfPAID[missing_cols] <- NA
}

# Add answer time (1st time, 2nd repeat, etc.)
dfPAID$answer_time <- ave(
  dfPAID$questionnaire_date,
  dfPAID$person_id,
  dfPAID$question_concept_id,
  FUN = seq_along
)

dfPAID$answer_time <- as.integer(dfPAID$answer_time)

# ==============================================================================
# 5. Write standard CSV outputs
# ==============================================================================

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