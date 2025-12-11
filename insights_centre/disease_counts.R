#Query for disease counts-------------------------------------------------------
sqlcountbydisease <- translate(
  "select count (distinct person_id) 
  from @databaseSchema.observation
  where observation_concept_id=@observation_concept
  and value_as_concept_id=@value_concept",
  targetDialect = sqlDialect
)

#Get the counts-----------------------------------------------------------------
diabetesCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, #Participant in research study
    value_concept = 2010000001 #custom concept for H2O Diabetes patient
  )
)

ibdCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, #Participant in research study
    value_concept = 2010000002 #custom concept for H2O IBD patient
  )
)

bcCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, #Participant in research study
    value_concept = 2010000003 #custom concept for H2O BC patient
  )
)

lcCounts <- querySql(
  connection,
  render(
    sqlcountbydisease,
    databaseSchema = databaseSchema,
    observation_concept = 44807982, #Participant in research study
    value_concept = 2010000004 #custom concept for H2O LC patient
  )
)

dfDiseaseCounts <- data.frame(
  disease = c("diabetes", "ibd", "bc", "lc"),
  counts = c(
    diabetesCounts[[1]],
    ibdCounts[[1]],
    bcCounts[[1]],
    lcCounts[[1]]
  )
)

#Write in one file all counts for each centre-----------------------------------
write.csv(
  dfDiseaseCounts,
  file.path(resultsDirectory, "disease_counts.csv"),
  row.names = FALSE
)
