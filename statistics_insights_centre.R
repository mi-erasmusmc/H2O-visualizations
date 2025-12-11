### Queries for number of persons-----------------------------------------------
#Total
sqlNumPersons <- translate(
  "select count(person_id) from @databaseSchema.person",
  targetDialect = sqlDialect
  )

numPersons <- querySql(
  connection,
  render(
    sqlNumPersons, 
    databaseSchema = databaseSchema
    )
  )

names(numPersons)[names(numPersons) == "COUNT"] <- "number_of_persons"
names(numPersons)[names(numPersons) == "COUNT(PERSON_ID)"] <- "number_of_persons"  # oracle

write.csv(numPersons, 
          file.path(resultsDirectory,"num_persons.csv"), 
          row.names = FALSE
          )

#Stratified by age
sqlAge <- translate(
  "select person_id, year_of_birth from @databaseSchema.person",
  targetDialect = sqlDialect
  )

dfAge <- querySql(
  connection,
  render(
    sqlAge,
    databaseSchema = databaseSchema
    )
  )

names(dfAge) <- tolower(names(dfAge))

dfAge$calcAge <- as.numeric(format(Sys.Date(), "%Y")) - dfAge$year_of_birth

dfAge$ageGroups <- cut(dfAge$calcAge, breaks = seq (-1,100,by=20))

write.csv(dfAge %>% count(ageGroups), 
          file.path(resultsDirectory,"num_persons_strat_age.csv"), 
          row.names = FALSE
          )

#Stratified by gender
sqlGender <- translate(
  "select person_id, gender_concept_id from @databaseSchema.person",
  targetDialect = sqlDialect
  )

dfGender <- querySql(
  connection,
  render(
    sqlGender,
    databaseSchema = databaseSchema
    )
  )

names(dfGender) <- tolower(names(dfGender))

dfGender <- dfGender %>%
  left_join(conversionGenderCTS, by="gender_concept_id")


write.csv(dfGender %>% count(gender_concept_name), 
          file.path(resultsDirectory,"num_persons_strat_gender.csv"), 
          row.names = FALSE
          )


###Queries for disease counts---------------------------------------------------
diabetesCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, # Participant in research study
    value_concept = 2010000001 #custom concept for H2O Diabetes patient
  )
)

ibdCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, # Participant in research study
    value_concept = 2010000002 #custom concept for H2O IBD patient
  )
)

bcCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, # Participant in research study
    value_concept = 2010000003 #custom concept for H2O BC patient
  )
)

lcCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, # Participant in research study
    value_concept = 2010000004 #custom concept for H2O LC patient
  )
)

dfDiseaseCounts <- data.frame(
  disease = c("diabetes", "ibd", "bc", "lc"),
  counts = c(
    diabetesCounts[[1]],
    ibdCounts[[1]],
    bcCounts[[1]],
    lcCounts[[1]] # since count is not returned by the oracle dbms
  )
)

write.csv(dfDiseaseCounts,
  file.path(resultsDirectory, "disease_counts.csv"),
  row.names = FALSE
)

###Queries for therapy counts---------------------------------------------------
#Sql query
#Look for the conditions in the Condition Occurrence table or the Observation
#table and add the counts

# query <-  "select ((
#     select count(distinct person_id)
#       from @databaseSchema.condition_occurrence
#       where condition_concept_id in (@diseaseConceptSet)
#     )
#     + (
#     select count(distinct person_id)
#       from @databaseSchema.observation
#       where observation_concept_id in (@observationConceptSet)
#         and value_as_concept_id in (@diseaseConceptSet)
#     ))"
#
# if (sqlDialect == "oracle") {
#   query <- paste(query, ' FROM DUAL')
# }
#
# sqlDiseaseCS <-  translate(
#   query,
#   targetDialect = sqlDialect
#   )
#
#Diabetes
# diabetesCounts <- querySql(
#   connection,
#   render(
#     sqlDiseaseCS, 
#     databaseSchema = databaseSchema,
#     diseaseConceptSet = paste0(diabetesCS$concept_id, collapse = ","),
#     observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
#     )
#   )
#
#Inflammatory Bowel Disease
# ibdCounts <- querySql(
#   connection,
#   render(
#     sqlDiseaseCS, 
#     databaseSchema = databaseSchema,
#     diseaseConceptSet = paste0(ibdCS$concept_id, collapse = ","),
#     observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
#     )
#   )
# 
#Breast cancer
# bcCounts <- querySql(
#   connection,
#   render(
#     sqlDiseaseCS, 
#     databaseSchema = databaseSchema,
#     diseaseConceptSet = paste0(bcCS$concept_id, collapse = ","),
#     observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
#     )
#   )
#
# #Lung Cancer
# lcCounts <- querySql(
#   connection,
#   render(
#     sqlDiseaseCS, 
#     databaseSchema = databaseSchema,
#     diseaseConceptSet = paste0(lcCS$concept_id, collapse = ","),
#     observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
#     )
#   )
#
# dfDiseaseCounts <- data.frame(
#   disease=c("diabetes","ibd","bc","lc"),
#   counts=c(
#     diabetesCounts[[1]],ibdCounts[[1]],bcCounts[[1]],  # since count is not returned by the oracle dbms
#     lcCounts[[1]])
#   )
#
#
# write.csv(dfDiseaseCounts,
#   file.path(resultsDirectory, "disease_counts.csv"),
#   row.names = FALSE
# )
