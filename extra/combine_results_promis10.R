#General Health-----------------------------------------------------------------
fileName <- "promis10_general_health_score.csv"
dfPromis10GHCombined <- data.frame()

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  dfPromis10GHCombined <- rbind(dfPromis10GHCombined, df)
}

write.csv(
  dfPromis10GHCombined,
  file.path(resultsDirectory, "promis10_general_health_score.csv"),
  row.names = FALSE
)

#Quality of life----------------------------------------------------------------
fileName <- "promis10_quality_life_score.csv"
dfPromis10QLCombined <- data.frame()

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  dfPromis10QLCombined <- rbind(dfPromis10QLCombined, df)
}

write.csv(
  dfPromis10QLCombined,
  file.path(resultsDirectory, "promis10_quality_life_score.csv"),
  row.names = FALSE
)

#Physical Health----------------------------------------------------------------
fileName <- "promis10_physical_health_total_score.csv"
dfPromis10PHCombined <- data.frame()

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  dfPromis10PHCombined <- rbind(dfPromis10PHCombined, df)
}

write.csv(
  dfPromis10PHCombined,
  file.path(resultsDirectory, "promis10_physical_health_total_score.csv"),
  row.names = FALSE
)

#Mental Health------------------------------------------------------------------
fileName <- "promis10_mental_health_total_score.csv"
dfPromis10MHCombined <- data.frame()

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  dfPromis10MHCombined <- rbind(dfPromis10MHCombined, df)
}

write.csv(
  dfPromis10MHCombined,
  file.path(resultsDirectory, "promis10_mental_health_total_score.csv"),
  row.names = FALSE
)
