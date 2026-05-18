#Get the counts-----------------------------------------------------------------
diabetesCounts <- querySql(
  connection,
  render(
    sqlCountsDisease,
    databaseSchema = databaseSchema,
    observationConceptSet = 44807982, #Participant in research study
    diseaseConceptSet = 2010000001 #custom concept for H2O Diabetes
  )
)

ibdCounts <- querySql(
  connection,
  render(
    sqlCountsDisease,
    databaseSchema = databaseSchema,
    observationConceptSet = 44807982, #Participant in research study
    diseaseConceptSet = 2010000002 #custom concept for H2O IBD
  )
)

bcCounts <- querySql(
  connection,
  render(
    sqlCountsDisease,
    databaseSchema = databaseSchema,
    observationConceptSet = 44807982, #Participant in research study
    diseaseConceptSet = 2010000003 #custom concept for H2O BC
  )
)

lcCounts <- querySql(
  connection,
  render(
    sqlCountsDisease,
    databaseSchema = databaseSchema,
    observationConceptSet = 44807982, #Participant in research study
    diseaseConceptSet = 2010000004 #custom concept for H2O LC
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
