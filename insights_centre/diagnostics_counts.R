###Diagnostics diabetes---------------------------------------------------------
source("R/insights_centre/sql_queries.R")

#Get the concept set------------------------------------------------------------
#Hemoglobin A1c measurement
hA1cCS <- querySql(
  connection,
  render(
    sqlDescendants,
    databaseSchema = databaseSchema,
    concepts = 4184637
  )
)

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
#HA1c
hA1cCounts <- querySql(
  connection,
  render(
    sqlCounts,
    databaseSchema = databaseSchema,
    omopTable = measurement,
    ConceptSet = paste0(hA1cCS$concept_id, collapse = ","),
    observationConceptSet = paste0(observationCS$concept_id, collapse = ",")
  )
)
