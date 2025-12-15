#General query to retrieve the descendant concept ids---------------------------
sqlDescendants <-  translate(
  "select concept_id from @databaseSchema.concept_ancestor 
  join @databaseSchema.concept
    on concept_ancestor.descendant_concept_id = concept.concept_id
  where ancestor_concept_id in (@concepts)",
  targetDialect = sqlDialect
)

#Query for diagnostics counts---------------------------------------------------
#Look in the measurment or the Observation table

queryCounts <-  "select ((
    select count(distinct person_id)
      from @databaseSchema.@omopTable
      where @omopTable_concept_id in (@ConceptSet)
    )
    select count(distinct person_id)
      from @databaseSchema.observation
      where observation_concept_id in (@observationConceptSet)
        and value_as_concept_id in (@ConceptSet)
    ))"

if (sqlDialect == "oracle") {
  query <- paste(sqlCounts, "FROM DUAL")
}

sqlCounts <-  translate(
  queryCounts,
  targetDialect = sqlDialect
)
