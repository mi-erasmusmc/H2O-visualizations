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

###Average trend----------------------------------------------------------------
#Calculate mean and standard error for each answer time
dfSummary <- dfPromis10GH %>% 
  group_by(answer_time, disease) %>% 
  summarise(
    mean_answer_num = mean(answer_value, na.rm = TRUE),
    se_answer_num = sd(answer_value, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

pltAver <-
  ggplot(
    dfSummary,
    aes(x = answer_time, y = mean_answer_num, group = disease, color = disease)
  ) +
  geom_line(stat = 'summary', fun = 'mean', size = 1.3) +
  geom_point(stat = 'summary', fun = 'mean', size = 3) +
  geom_errorbar(
    aes(
      ymin = mean_answer_num - se_answer_num,
      ymax = mean_answer_num + se_answer_num
    ),
    width = 0.15, linewidth = 1
  ) +
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
jpeg(file.path(plotsDirectory, "mean_scores_general_health.jpg"))
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
      is.na(answer_num_prev)         ~ NA_character_,
      answer_value > answer_num_prev ~ "up",
      answer_value < answer_num_prev ~ "down",
      TRUE                           ~ "no change"
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
jpeg(file.path(plotsDirectory, "transitions_general_health.jpg"))
print(pltTrans)
dev.off()
