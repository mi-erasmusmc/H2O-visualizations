###Read the dfs with answers based on the PROMIS score group--------------------
dfPromis10GH <- read.csv(
  file.path(resultsDirectory,"promis10_general_health_score.csv")
  )

dfPromis10QL <- read.csv(
  file.path(resultsDirectory,"promis10_quality_life_score.csv")
  )

dfPromis10PH <- read.csv(
  file.path(resultsDirectory,"promis10_physical_health_total_score.csv")
  )

dfPromis10MH <- read.csv(
  file.path(resultsDirectory,"promis10_mental_health_total_score.csv")
  )


###Histograms with counts-------------------------------------------------------
#General Health
pltHistGH <- 
  ggplot(dfPromis10GH, 
       aes(x = as.factor(answer_time), fill = as.factor(answer_time))) + 
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

jpeg(file.path(plotsDirectory,"freq_responses_general_health.jpg"))
print(pltHistGH)
dev.off()

#Quality of life
pltHistQL <- 
  ggplot(dfPromis10QL, 
         aes(x = as.factor(answer_time), fill = as.factor(answer_time))) + 
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

jpeg(file.path(plotsDirectory,"freq_responses_quality_life.jpg"))
print(pltHistQL)
dev.off()

#Physical health
pltHistPH <- 
  ggplot(dfPromis10PH, 
         aes(x = as.factor(answer_time), fill = as.factor(answer_time))) + 
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

jpeg(file.path(plotsDirectory,"freq_responses_physical_health.jpg"))
print(pltHistPH)
dev.off()

#Mental health
pltHistMH <- 
  ggplot(dfPromis10MH, 
         aes(x = as.factor(answer_time), fill = as.factor(answer_time))) + 
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

jpeg(file.path(plotsDirectory,"freq_responses_mental_health.jpg"))
print(pltHistMH)
dev.off()


###Average trend----------------------------------------------------------------
#Calculate mean and standard error for each answer time
dfSummary <- dfPromis10GH %>% 
  group_by(answer_time, disease) %>% 
  summarise(
    mean_answer_num = mean(answer_value, na.rm = TRUE),
    se_answer_num = sd(answer_value, na.rm = TRUE)/sqrt(n()),
    .groups = "drop"
  )

pltAver <- 
  ggplot(dfSummary, aes(x = answer_time, y = mean_answer_num,
                        group = disease, 
                        color = disease)) + 
  geom_line(stat='summary', fun='mean', size = 1.3) + 
  geom_point(stat='summary', fun='mean', size = 3) +
  geom_errorbar(aes(ymin = mean_answer_num - se_answer_num, 
                    ymax = mean_answer_num + se_answer_num), 
                width = 0.15, linewidth = 1) +
  scale_color_viridis_d(option = "D") +
  labs(
    x = "Number of questionnaires",
    y = "Mean response score +/- SE",
    title = "Mean score over questionnaires"
    ) + 
  ylim(0, 5) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5)
  )
jpeg(file.path(plotsDirectory,"mean_scores_general_health.jpg"))
print(pltAver)
dev.off()

###Transitions------------------------------------------------------------------
#Detect transitions for each person
dfTrans <- dfPromis10GH %>%
  arrange(person_id, answer_time) %>%
  group_by(person_id) %>%
  mutate(
    answer_num_prev = lag(answer_value),
    time_prev = lag(answer_time),
    direction = case_when(
      is.na(answer_num_prev)       ~NA_character_,
      answer_value > answer_num_prev ~"up",
      answer_value < answer_num_prev ~"down",
      TRUE                         ~"no change"
    )
  ) %>%
  ungroup()

#Aggregate transitions across all people
dfAgg <- dfTrans %>%
  filter(!is.na(direction)) %>% # exclude first timepoint (no transition)
  mutate(
    time_interval = paste(time_prev, "->", answer_time)
  ) %>%
  group_by(time_interval, direction) %>%
  summarise(n = n(), .groups = 'drop')

#Visualise transitions
pltTrans <- 
  ggplot(dfAgg, aes(x = time_interval, y = n, fill = direction)) +
  geom_col(position = "dodge") +
  labs(
    title = "Transitions between responses",
    x = "Questionnaires",
    y = "Number of people",
    fill = "Direction"
  ) +
  scale_fill_manual(
    values = c("up" = "blue", "down" = "red", "no change" = "grey")
    ) +
  theme_minimal()
jpeg(file.path(plotsDirectory,"transitions_general_health.jpg"))
print(pltTrans)
dev.off()


###T-scores--------------------------------------------------------------------
#Physical health box plot-------------------------------------------------------
#Add the calculated t-scores
dfPromis10PH <- dfPromis10PH %>%
  left_join(conversionPH, by="total_score")

#Keep only the 1st time the patient responded to the questionnaire
dfPromis10PHFirst <- subset(dfPromis10PH, answer_time == 1)

#Count the number of responses for each disease
xlabsPH <- paste(
  levels(dfPromis10PHFirst$disease),
  "\n(N=",table(dfPromis10PHFirst$disease),")",
  sep = ""
  )

#Plot
pltBoxPH <- 
  ggplot(dfPromis10PHFirst, aes(x=disease, y=tscore, fill=disease)) + 
  geom_boxplot() + 
  scale_x_discrete(labels=xlabsPH) +
  labs(
    title = "PROMIS 10 Physical Health T-scores by disease (only 1st response)",
    x = "Numeber of answers",
    y = "t-score",
    fill = "Direction"
    )
jpeg(file.path(plotsDirectory,"tscore_physical_health.jpg"))
print(pltBoxPH)
dev.off()

#Mental health box plot---------------------------------------------------------
#Add the calculated t-scores
dfPromis10MH <- dfPromis10MH %>%
  left_join(conversionMH, by="total_score")

#Keep only the 1st time the patient responded to the questionnaire
dfPromis10MHFirst <- subset(dfPromis10MH, answer_time == 1)

#Count the number of responses for each disease
xlabsMH <- paste(
  levels(dfPromis10MHFirst$disease),
  "\n(N=",table(dfPromis10MHFirst$disease),")",
  sep = ""
)

#Plot
pltBoxMH <- 
  ggplot(dfPromis10MHFirst, aes(x=disease, y=tscore, fill=disease)) + 
  geom_boxplot() + 
  scale_x_discrete(labels=xlabsMH) +
  labs(
    title = "PROMIS 10 Mental Health T-scores by disease (only 1st response)",
    x = "Numeber of answers",
    y = "t-score",
    fill = "Direction"
  )
jpeg(file.path(plotsDirectory,"tscore_mental_health.jpg"))
print(pltBoxMH)
dev.off()
