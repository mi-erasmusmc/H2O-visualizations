library(dplyr)

  min_patient_threshold <- 5 # Standard privacy threshold for OMOP studies

# Function to aggregate a single dataframe securely
aggregate_paid_data <- function(input_file, output_file) {
  
  # Read the raw patient-level data
  df <- read.csv(input_file)
  
  # Aggregate by answer_time (visit number)
  df_agg <- df %>%
    group_by(answer_time) %>%
    summarise(
      mean_value = mean(answer_value, na.rm = TRUE),
      sd_value = sd(answer_value, na.rm = TRUE),
      patient_count = n(),
      .groups = 'drop'
    )
  
  # Privacy Filter: Remove visits with too few patients to prevent re-identification
  df_agg <- df_agg %>%
    filter(patient_count >= min_patient_threshold)
  
  # Handle cases where sd_value is NA (happens if only 1 patient is left at a visit)
  # Though the filter above makes this highly unlikely, it's a safe fallback.
  df_agg$sd_value[is.na(df_agg$sd_value)] <- 0
  
  # Save the aggregated, privacy-safe data
  write.csv(df_agg, output_file, row.names = FALSE)
}

# Loop through all 5 files to process them automatically
for (i in 1:5) {
  # Looking for the "_mix" files as defined in your original visualization script
  input_path <- file.path("Z:/Matthijs/Git/H2O-visualizations/results", paste0("5_", i, "_mix.csv"))
  output_path <- file.path("Z:/Matthijs/Git/H2O-visualizations/results", paste0("5_", i, "_agg.csv"))
  
  if (file.exists(input_path)) {
    aggregate_paid_data(input_path, output_path)
    print(paste("Aggregated securely:", output_path))
  } else {
    warning(paste("File not found, skipping:", input_path))
  }
}