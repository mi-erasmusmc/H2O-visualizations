###Number of persons------------------------------------------------------------
#Total--------------------------------------------------------------------------
numPersons <- read.csv(
  file.path(resultsDirectory,"num_persons.csv"),
  stringsAsFactors = FALSE, check.names = FALSE
)

#Plot the number of number of persons stratified by Age-------------------------
stratAge <- read.csv(
  file.path(resultsDirectory, "num_persons_strat_age.csv")
)

pltAge <-
  ggplot(stratAge, aes(x = n, y = ageGroups, fill = ageGroups)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(
    x = "Number of persons",
    y = "Age group",
    title = "Number of persons stratified by age"
  )
jpeg(file.path(plotsDirectory,"num_persons_strat_age.jpg"))
print(pltAge)
dev.off()

#Plot the number of number of persons stratified by Gender----------------------
stratGender <- read.csv(
  file.path(resultsDirectory, "num_persons_strat_gender.csv")
)

pltGender <-
  ggplot(
    stratGender,
    aes(x = n, y = gender_concept_name, fill = gender_concept_name)
  ) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(
    x = "Number of persons",
    y = "Gender",
    title = "Number of persons stratified by gender"
  )
jpeg(file.path(plotsDirectory, "num_persons_strat_gender.jpg"))
print(pltGender)
dev.off()

###Disease counts---------------------------------------------------------------
diseaseCounts <- read.csv(
  file.path(resultsDirectory, "disease_counts.csv")
)

pltDisease <-
  ggplot(
    diseaseCounts,
    aes(x = counts, y = disease, fill = disease)
  ) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(
    x = "Number of persons",
    y = "H2O disease group",
    title = "Number of persons per disease"
  )
jpeg(file.path(plotsDirectory,"num_persons_disease.jpg"))
print(pltDisease)
dev.off()

###Therapy counts---------------------------------------------------------------
#Diabetes therapy---------------------------------------------------------------
therapyCounts <- read.csv(
  file.path(resultsDirectory, "therapy_counts.csv")
)

pltDisease <-
  ggplot(
    therapyCounts,
    aes(x = counts, y = therapy, fill = therapy)
  ) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  labs(
    x = "Number of persons",
    y = "Diabetes therapy group",
    title = "Number of persons per therapy"
  )
jpeg(file.path(plotsDirectory, "num_persons_diabetes_therapy.jpg"))
print(pltDisease)
dev.off()
