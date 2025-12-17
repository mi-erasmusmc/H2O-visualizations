###Therapies diabetes-----------------------------------------------------------
source("R/insights_centre/sql_queries.R")

#Get the concept sets-----------------------------------------------------------
#Diet & Exercise
dietExerciseCS <- querySql(
  connection,
  render(
    sqlDescendants,
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
    sqlDescendants,
    databaseSchema = databaseSchema,
    concepts = 21600744
  )
)

names(oralAgentsCS) <- tolower(names(oralAgentsCS))

#Insulin
insulinCS <- querySql(
  connection,
  render(
    sqlDescendants,
    databaseSchema = databaseSchema,
    concepts = 21600713
  )
)

names(insulinCS) <- tolower(names(insulinCS))

#Other Injectables
otherInjectablesCS <- querySql(
  connection,
  render(
    sqlDescendants,
    databaseSchema = databaseSchema,
    concepts = 955112
  )
)

names(otherInjectablesCS) <- tolower(names(otherInjectablesCS))

#Observation Concept Set
observationCS <- querySql(
  connection,
  render(
    sqlDescendants,
    databaseSchema = databaseSchema,
    concepts = c(46234708, 1340204)
  )
)

names(observationCS) <- tolower(names(observationCS))

#Get the counts-----------------------------------------------------------------
#Diet and Exercise
dietExerciseCounts <- querySql(
  connection,
  render(
    sqlCountsLifeStyle,
    databaseSchema = databaseSchema,
    conceptSet = paste0(dietExerciseCS$concept_id, collapse = ","),
    observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
  )
)

#Oral Agents
oralAgentsCounts <- querySql(
  connection,
  render(
    sqlCountsDrugs,
    databaseSchema = databaseSchema,
    conceptSet = paste0(oralAgents$concept_id, collapse = ","),
    observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
  )
)

#insulin
insulinCounts <- querySql(
  connection,
  render(
    sqlCountsDrugs,
    databaseSchema = databaseSchema,
    conceptSet = paste0(ibinsulinCSdCS$concept_id, collapse = ","),
    observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
  )
)

#Other Injectables
otherInjectablesCounts <- querySql(
  connection,
  render(
    sqlCountsDrugs,
    databaseSchema = databaseSchema,
    conceptSet = paste0(otherInjectablesCS$concept_id, collapse = ","),
    observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
  )
)

dfTherapyCounts <- data.frame(
  therapy = c("Diet & Exercise", "Oral Agents", "insulin", "Other Injectables"),
  counts = c(
    dietExerciseCounts[[1]],
    oralAgentsCounts[[1]],
    insulinCounts[[1]],
    otherInjectablesCounts[[1]]
  )
)


#Write in one file all counts for each centre-----------------------------------
write.csv(dfTherapyCounts,
  file.path(resultsDirectory, "therapy_counts.csv"),
  row.names = FALSE
)
