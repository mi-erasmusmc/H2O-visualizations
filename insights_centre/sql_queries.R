#General query to retrieve the descendant concept ids---------------------------
sqlDescendants <-  translate(
  "select concept_id from @databaseSchema.concept_ancestor 
  join @databaseSchema.concept
    on concept_ancestor.descendant_concept_id = concept.concept_id
  where ancestor_concept_id in (@concepts)",
  targetDialect = sqlDialect
)

#Query for disease counts-------------------------------------------------------
sqlCountsDisease <- translate(
  "select count (distinct person_id) 
  from @databaseSchema.observation
  where observation_concept_id = @observationConceptSet
  and value_as_concept_id = @diseaseConceptSet",
  targetDialect = sqlDialect
)

#Queries for therapy counts-----------------------------------------------------
#Look in the Observation table
queryCountsLifeStyle <-  "select count(distinct person_id)
      from @databaseSchema.observation
      where observation_concept_id in (@conceptSet)"

if (sqlDialect == "oracle") {
  query <- paste(sqlCounts, "FROM DUAL")
}

sqlCountsLifeStyle <-  translate(
  queryCountsLifeStyle,
  targetDialect = sqlDialect
)

#Look in the drug_exposure or the Observation table
queryCountsDrugs <-  "select count(distinct person_id)
      from(
        select person_id
        from @databaseSchema.drug_exposure
        where drug_concept_id in (@conceptSet)
      union
        select person_id
        from @databaseSchema.observation
        where observation_concept_id in (@observationConceptSet)
          and value_as_concept_id in (@conceptSet)
      )"

if (sqlDialect == "oracle") {
  query <- paste(sqlCounts, "FROM DUAL")
}

sqlCountsDrugs <-  translate(
  queryCountsDrugs,
  targetDialect = sqlDialect
)


#Query for diagnostics counts---------------------------------------------------
#Look in the measurment or the Observation table
queryCountsDiagnostics <-  "select count(distinct person_id)
      from (
        select person_id
        from @databaseSchema.measurement
        where measurement_concept_id in (@conceptSet)
      union
        select person_id
        from @databaseSchema.observation
        where observation_concept_id in (@observationConceptSet)
          and value_as_concept_id in (@conceptSet)
      )"

if (sqlDialect == "oracle") {
  query <- paste(sqlCounts, "FROM DUAL")
}

sqlCountsDiagnostics <-  translate(
  queryCountsDiagnostics,
  targetDialect = sqlDialect
)
