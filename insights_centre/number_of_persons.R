###Total number of persons-----------------------------------------------------
#Queries for person counts-----------------------------------------------------
sqlNumPersons <- translate(
  "select count(person_id) from @databaseSchema.person",
  targetDialect = sqlDialect
)

#Get the counts-----------------------------------------------------------------
numPersons <- querySql(
  connection,
  render(
    sqlNumPersons,
    databaseSchema = databaseSchema
  )
)

names(numPersons)[names(numPersons) == "COUNT"] <- "number_of_persons"

# additional for oracle db
names(numPersons)[
  names(numPersons) == "COUNT(PERSON_ID)"
] <- "number_of_persons"

#Write in one file all counts for each centre-----------------------------------
write.csv(
  numPersons,
  file.path(resultsDirectory, "num_persons.csv"),
  row.names = FALSE
)

###Number of persons stratified by age------------------------------------------
#Query for person counts--------------------------------------------------------
sqlAge <- translate(
  "select person_id, year_of_birth from @databaseSchema.person",
  targetDialect = sqlDialect
)

#Get the counts-----------------------------------------------------------------
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

#Write in one file all counts for each centre-----------------------------------
write.csv(
  dfAge %>% count(ageGroups),
  file.path(resultsDirectory, "num_persons_strat_age.csv"),
  row.names = FALSE
)

###Stratified by gender---------------------------------------------------------
#Map concept_ids to the corresponding names for readability---------------------
conversionGenderCTS <- tibble(
  gender_concept_id = c(8507, 8532),
  gender_concept_name = c('Male', 'Female')
)

#Query for person counts--------------------------------------------------------
sqlGender <- translate(
  "select person_id, gender_concept_id from @databaseSchema.person",
  targetDialect = sqlDialect
)

#Get the counts-----------------------------------------------------------------
dfGender <- querySql(
  connection,
  render(
    sqlGender,
    databaseSchema = databaseSchema
  )
)

names(dfGender) <- tolower(names(dfGender))

dfGender <- dfGender %>%
  left_join(conversionGenderCTS, by = "gender_concept_id")

#Write in one file all counts for each centre-----------------------------------
write.csv(
  dfGender %>% count(gender_concept_name),
  file.path(resultsDirectory,"num_persons_strat_gender.csv"),
  row.names = FALSE
)
