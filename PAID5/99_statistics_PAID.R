

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
names(diabetesCS) <- tolower(names(diabetesCS))  # MUW: since oracle returns upper case column names
diabetesCS <- rbind(diabetesCS, data.frame(concept_id = c(201820,37018196))) # MUW (Diabetes mellitus, Prediabetes)



dfPAID <- querySql(
  connection,
  render(
    sqlPAID,
    databaseSchema = databaseSchema,
    diseaseConcepts = paste0(c(diabetesCS$concept_id), 
                             collapse = ","),
    questionConcepts = questionConcepts
  )
)

names(dfPAID) <- tolower(names(dfPAID))



#Group by disease
dfPAID <- dfPAID %>% 
  mutate(disease = "Diabetes")

#Add the question number to identify the questions easily
dfPAID <- dfPAID %>%
  left_join(conversionQuestionCTS, by = "question_concept_id")

#Add the answer scale number to perform calculations
dfPAID <- dfPAID %>%
  left_join(conversionAnswerCTN, by = "answer_concept_id")

# MUW: ave complained about date conversion's origin
dfPAID$questionnaire_date <- as.numeric(dfPAID$questionnaire_date)

#Add the time (1st time, 2nd repeat, etc.) a person filled the questionnaire
dfPAID$answer_time <- ave(
  dfPAID$questionnaire_date,
  dfPAID$person_id,
  dfPAID$question_concept_id,
  FUN = seq_along
)

dfPAID$answer_time <- as.integer(dfPAID$answer_time)

###  1st question------------------------------------
dfPAIDGH <- subset(
  dfPAID, dfPAID$question_number == '5_1'
)

write.csv(
  dfPAIDGH,
  file.path(resultsDirectory,"5_1.csv"),
  row.names = FALSE
)


### 2nd question-----------------------------------
dfPAIDQL <- subset(
  dfPAID, dfPAID$question_number == '5_2'
)

write.csv(
  dfPAIDQL,
  file.path(resultsDirectory, "5_2.csv"),
  row.names = FALSE
)

###  3st question------------------------------------
dfPAIDGH <- subset(
  dfPAID, dfPAID$question_number == '5_3'
)

write.csv(
  dfPAIDGH,
  file.path(resultsDirectory,"5_3.csv"),
  row.names = FALSE
)


### 4nd question-----------------------------------
dfPAIDQL <- subset(
  dfPAID, dfPAID$question_number == '5_4'
)

write.csv(
  dfPAIDQL,
  file.path(resultsDirectory, "5_4.csv"),
  row.names = FALSE
)

### 5nd question-----------------------------------
dfPAIDQL <- subset(
  dfPAID, dfPAID$question_number == '5_5'
)

write.csv(
  dfPAIDQL,
  file.path(resultsDirectory, "5_5.csv"),
  row.names = FALSE
)
