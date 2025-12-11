###Therapy concepts diabetes----------------------------------------------------
#General query to retrieve the descendant concept ids---------------------------
sqlDiseaseDescendants <-  translate(
  "select concept_id from @databaseSchema.concept_ancestor 
  join @databaseSchema.concept
    on concept_ancestor.descendant_concept_id = concept.concept_id
  where ancestor_concept_id in (@concepts)",
  targetDialect = sqlDialect
)

#Get the concept sets-----------------------------------------------------------
#Diet & Exercise
dietExerciseCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants,
    databaseSchema = databaseSchema,
    concepts = c(4027003, 4198096)
  )
)

#oracle returns upper case column names
names(dietExerciseCS) <- tolower(names(dietExerciseCS))

#Oral Agents
oralAgentsCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants,
    databaseSchema = databaseSchema,
    concepts = 21600744
  )
)

names(oralAgentsCS) <- tolower(names(oralAgentsCS))

#Insulin
insulinCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants,
    databaseSchema = databaseSchema,
    concepts = 21600713
  )
)

names(insulinCS) <- tolower(names(insulinCS))

#Other Injectables
otherInjectablesCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants,
    databaseSchema = databaseSchema,
    concepts = 955112
  )
)

names(otherInjectablesCS) <- tolower(names(otherInjectablesCS))

#Observation Concept Set
observationCS <- querySql(
  connection,
  render(
    sqlDiseaseDescendants,
    databaseSchema = databaseSchema,
    concepts = c(46234708, 1340204)
  )
)
names(observationCS) <- tolower(names(observationCS))

#Queries for therapy counts-----------------------------------------------------
#Look for the drugs in the Drug Exposure table or the Observation table
#and for the diet and exercise in the observation table

query <-  "select ((
    select count(distinct person_id)
      from @databaseSchema.drug_exposure
      where condition_concept_id in (@drug_therapy_concepts)
    )
    + (
    select count(distinct person_id)
      from @databaseSchema.observation
      where condition_concept_id in (@non_drug_therapies_concepts)
    )
    + (
    select count(distinct person_id)
      from @databaseSchema.observation
      where observation_concept_id in (@observation_concepts)
        and value_as_concept_id in (@drug_therapy_concepts)
    ))"

if (sqlDialect == "oracle") {
  query <- paste(query, "FROM DUAL")
}

sqlTherapyCS <-  translate(
  query,
  targetDialect = sqlDialect
)

#Get the counts-----------------------------------------------------------------
thereapyCounts <- querySql(
  connection,
  render(
    sqlDiseaseCS,
    databaseSchema = databaseSchema,
    diseaseConceptSet = paste0(diabetesCS$concept_id, collapse = ","),
    observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
  )
)

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
#Write in one file all counts for each centre-----------------------------------
write.csv(dfDiseaseCounts,
  file.path(resultsDirectory, "disease_counts.csv"),
  row.names = FALSE
)
