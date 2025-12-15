#Total--------------------------------------------------------------------------
fileName <- "num_persons.csv"
numPersonsCombined <- NULL

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  colnames(df) <- paste0(colnames(df), "_", db)
  if (is.null(numPersonsCombined)) {
    numPersonsCombined <- df
  } else {
    numPersonsCombined <- cbind(numPersonsCombined, df)
  }
}

numPersonsCombined$count <- rowSums(numPersonsCombined)

write.csv(
  numPersonsCombined,
  file.path(resultsDirectory, "num_persons.csv"),
  row.names = FALSE
)

#Stratified by age--------------------------------------------------------------
fileName <- "num_persons_strat_age.csv"
dfAgeCombined <- NULL

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  commonCol <- "ageGroups"
  otherCol <- setdiff(names(df), commonCol)
  names(df)[names(df) %in% otherCol] <- paste0(otherCol, "_", db)
  if (is.null(dfAgeCombined)) {
    dfAgeCombined <- df
  } else {
    dfAgeCombined <- merge(dfAgeCombined, df, by = commonCol, all = TRUE)
  }
}

dfAgeCombined$n <- rowSums(
  dfAgeCombined[, names(dfAgeCombined) != "ageGroups"]
)

write.csv(
  dfAgeCombined,
  file.path(resultsDirectory, "num_persons_strat_age.csv"),
  row.names = FALSE
)

#Stratified by gender-----------------------------------------------------------
fileName <- "num_persons_strat_gender.csv"
dfGenderCombined <- NULL

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  commonCol <- "gender_concept_name"
  otherCol <- setdiff(names(df), commonCol)
  names(df)[names(df) %in% otherCol] <- paste0(otherCol, "_", db)
  if (is.null(dfGenderCombined)) {
    dfGenderCombined <- df
  } else {
    dfGenderCombined <- merge(dfGenderCombined, df, by = commonCol, all = TRUE)
  }
}

dfGenderCombined$n <- rowSums(
  dfGenderCombined[, names(dfGenderCombined) != "gender_concept_name"]
)

write.csv(
  dfGenderCombined,
  file.path(resultsDirectory, "num_persons_strat_gender.csv"),
  row.names = FALSE
)

#Disease counts
fileName <- "disease_counts.csv"
dfDiseaseCombined <- NULL

for (db in dbNames){
  filePath <- file.path(paste0("results", db), fileName)
  df <- read.csv(filePath)
  commonCol <- "disease"
  otherCol <- setdiff(names(df), commonCol)
  names(df)[names(df) %in% otherCol] <- paste0(otherCol, "_", db)
  if (is.null(dfDiseaseCombined)) {
    dfDiseaseCombined <- df
  } else {
    dfDiseaseCombined <- merge(
      dfDiseaseCombined, df, by = commonCol, all = TRUE
    )
  }
}

dfDiseaseCombined$counts <- rowSums(
  dfDiseaseCombined[, names(dfDiseaseCombined) != "disease"]
)

write.csv(
  dfDiseaseCombined,
  file.path(resultsDirectory, "disease_counts.csv"),
  row.names = FALSE
)
