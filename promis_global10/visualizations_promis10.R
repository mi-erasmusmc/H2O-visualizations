###Read the dfs with answers based on the PROMIS score group--------------------
dfPromis10GH <- read.csv(
  file.path(resultsDirectory, "promis10_general_health_score.csv")
)

dfPromis10QL <- read.csv(
  file.path(resultsDirectory, "promis10_quality_life_score.csv")
)

dfPromis10PH <- read.csv(
  file.path(resultsDirectory, "promis10_physical_health_total_score.csv")
)

dfPromis10MH <- read.csv(
  file.path(resultsDirectory, "promis10_mental_health_total_score.csv")
)

###Histograms for number of times a questionnaire was answered------------------
#General Health-----------------------------------------------------------------
pltHistGH <-
  ggplot(
    dfPromis10GH,
    aes(x = as.factor(answer_time), fill = as.factor(answer_time))
  ) +
  geom_bar(show.legend = FALSE, width = 0.8) +
  scale_fill_viridis_d() +
  labs(
    x = "Number of times questionnaire answered",
    y = "Number of people",
    title = "Frequency of responses for the general health score"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5)
  )

jpeg(file.path(plotsDirectory, "freq_responses_general_health.jpg"))
print(pltHistGH)
dev.off()

#Quality of life----------------------------------------------------------------
pltHistQL <-
  ggplot(
    dfPromis10QL,
    aes(x = as.factor(answer_time), fill = as.factor(answer_time))
  ) +
  geom_bar(show.legend = FALSE, width = 0.8) +
  scale_fill_viridis_d() +
  labs(
    x = "Number of times questionnaire answered",
    y = "Number of people",
    title = "Frequency of responses for the quality of life score"
  ) +
  theme_minimal(base_size = 14) + 
  theme(
    plot.title = element_text(hjust = 0.5)
  )

jpeg(file.path(plotsDirectory, "freq_responses_quality_life.jpg"))
print(pltHistQL)
dev.off()

#Physical health----------------------------------------------------------------
pltHistPH <-
  ggplot(
    dfPromis10PH,
    aes(x = as.factor(answer_time), fill = as.factor(answer_time))
  ) +
  geom_bar(show.legend = FALSE, width = 0.8) +
  scale_fill_viridis_d() + 
  labs(
    x = "Number of times questionnaire answered",
    y = "Number of people",
    title = "Frequency of responses for the physical health score"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5)
  )

jpeg(file.path(plotsDirectory, "freq_responses_physical_health.jpg"))
print(pltHistPH)
dev.off()

#Mental health
pltHistMH <-
  ggplot(
    dfPromis10MH,
    aes(x = as.factor(answer_time), fill = as.factor(answer_time))
  ) +
  geom_bar(show.legend = FALSE, width = 0.8) +
  scale_fill_viridis_d() +
  labs(
    x = "Number of times questionnaire answered",
    y = "Number of people",
    title = "Frequency of responses for the mental health score"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5)
  )

jpeg(file.path(plotsDirectory, "freq_responses_mental_health.jpg"))
print(pltHistMH)
dev.off()

###Box plots with T-scores------------------------------------------------------
#Physical health----------------------------------------------------------------
#Add the calculated t-scores
dfPromis10PH <- dfPromis10PH %>%
  left_join(conversionPHScore, by = "total_score")

#Keep only the 1st time the patient responded to the questionnaire
dfPromis10PHFirst <- subset(dfPromis10PH, answer_time == 1)

#Count the number of responses for each disease
xlabsPH <- paste(
  levels(dfPromis10PHFirst$disease),
  "\n(N=", table(dfPromis10PHFirst$disease), ")",
  sep = ""
)

pltBoxPH <-
  ggplot(dfPromis10PHFirst, aes(x = disease, y = tscore, fill = disease)) +
  geom_boxplot() +
  scale_x_discrete(labels = xlabsPH) +
  ylim(0, 100) +
  labs(
    title = "PROMIS 10 Physical Health T-scores by disease (only 1st response)",
    x = "Numeber of answers",
    y = "t-score",
    fill = "Direction"
  )
jpeg(file.path(plotsDirectory, "tscore_physical_health.jpg"))
print(pltBoxPH)
dev.off()

#Mental health------------------------------------------------------------------
#Add the calculated t-scores
dfPromis10MH <- dfPromis10MH %>%
  left_join(conversionMHScore, by = "total_score")

#Keep only the 1st time the patient responded to the questionnaire
dfPromis10MHFirst <- subset(dfPromis10MH, answer_time == 1)

#Count the number of responses for each disease
xlabsMH <- paste(
  levels(dfPromis10MHFirst$disease),
  "\n(N=", table(dfPromis10MHFirst$disease), ")",
  sep = ""
)

#Plot
pltBoxMH <-
  ggplot(dfPromis10MHFirst, aes(x = disease, y = tscore, fill = disease)) +
  geom_boxplot() +
  scale_x_discrete(labels = xlabsMH) +
  ylim(0, 100) +
  labs(
    title = "PROMIS 10 Mental Health T-scores by disease (only 1st response)",
    x = "Numeber of answers",
    y = "t-score",
    fill = "Direction"
  )
jpeg(file.path(plotsDirectory, "tscore_mental_health.jpg"))
print(pltBoxMH)
dev.off()
