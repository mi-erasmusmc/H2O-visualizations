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


# Added By Adnan Feb 2026
# start here ===> 
# Calculate total counts across DB columns robustly:
numericCols <- setdiff(names(dfAgeCombined), "ageGroups")

if (length(numericCols) == 0) {
  # No numeric columns found -> create a zero column
  dfAgeCombined$n <- 0
} else {
  # Ensure numeric columns are numeric (handle factors/characters)
  dfAgeCombined[numericCols] <- lapply(dfAgeCombined[numericCols], function(x) {
    xNum <- suppressWarnings(as.numeric(as.character(x)))
    xNum
  })
  # Replace NAs with 0 so rowSums treats missing as zero contribution
  dfAgeCombined[numericCols] <- lapply(dfAgeCombined[numericCols], function(x) {
    x[is.na(x)] <- 0
    x
  })
  # Force a 2-D matrix even when there's only one numeric column
  dfAgeCombined$n <- rowSums(as.matrix(dfAgeCombined[, numericCols, drop = FALSE]))
}
#<=== end here



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
