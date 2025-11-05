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
#Sql query
sqlDiseaseCS <-  translate(
  "select count(distinct person_id)
      from @databaseSchema.condition_occurrence
      where condition_concept_id in (@diseaseConceptSet)",
  targetDialect = sqlDialect
  )

#Diabetes
diabetesCounts <- querySql(
  connection,
  render(
    sqlDiseaseCS, 
    databaseSchema = databaseSchema,
    diseaseConceptSet = paste0(diabetesCS$concept_id, collapse = ",")
    )
  )

#Inflammatory Bowel Disease
ibdCounts <- querySql(
  connection,
  render(
    sqlDiseaseCS, 
    databaseSchema = databaseSchema,
    diseaseConceptSet = paste0(ibdCS$concept_id, collapse = ",")
    )
  )

#Breast cancer
bcCounts <- querySql(
  connection,
  render(
    sqlDiseaseCS, 
    databaseSchema = databaseSchema,
    diseaseConceptSet = paste0(bcCS$concept_id, collapse = ",")
    )
  )

#Lung Cancer
lcCounts <- querySql(
  connection,
  render(
    sqlDiseaseCS, 
    databaseSchema = databaseSchema,
    diseaseConceptSet = paste0(lcCS$concept_id, collapse = ",")
    )
  )

dfDiseaseCounts <- data.frame(
  disease=c("diabetes","ibd","bc","lc"),
  counts=c(
    diabetesCounts[["count"]],ibdCounts[["count"]],bcCounts[["count"]],
    lcCounts[["count"]])
  )


write.csv(dfDiseaseCounts, 
          file.path(resultsDirectory,"disease_counts.csv"),
          row.names = FALSE
          )
