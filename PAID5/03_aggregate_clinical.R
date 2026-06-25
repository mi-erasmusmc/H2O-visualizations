library(dplyr)

 min_patient_threshold <- 5 # Standard privacy threshold

# 1. Read one of the questionnaire files that contains the clinical columns
# (Since the clinical data is attached to the visit, 5_1_mix.csv works perfectly as the source)
input_file <- file.path(resultsDir, "5_1_mix.csv") 
df_raw <- read.csv(input_file)

# 2. Extract distinct patient visits so we don't double-count clinical values
# if multiple questions were answered at the exact same time
df_clinical <- df_raw %>%
  distinct(person_id, answer_time, 
           hba1c_value, total_cholesterol_value, triglycerides_value, 
           systolic_bp_value, diastolic_bp_value)

# 3. Define the clinical columns we want to aggregate based on your exact header
clinical_metrics <- c("hba1c_value", "total_cholesterol_value", "triglycerides_value", 
                      "systolic_bp_value", "diastolic_bp_value")

# 4. Loop through each metric and securely aggregate it
for (metric in clinical_metrics) {
  
  df_agg <- df_clinical %>%
    # Remove rows where this specific clinical test wasn't performed/recorded
    filter(!is.na(.data[[metric]])) %>%
    group_by(answer_time) %>%
    summarise(
      mean_value = mean(.data[[metric]], na.rm = TRUE),
      sd_value = sd(.data[[metric]], na.rm = TRUE),
      patient_count = n(),
      .groups = 'drop'
    ) %>%
    # Privacy Filter: Remove visits with too few patients
    filter(patient_count >= min_patient_threshold)
  
  # Handle cases where sd_value is NA (e.g., if exactly 1 patient was left before the filter)
  df_agg$sd_value[is.na(df_agg$sd_value)] <- 0
  
  # Save the aggregated, privacy-safe data
  output_path <- file.path(resultsDir, paste0(metric, "_agg.csv"))
  write.csv(df_agg, output_path, row.names = FALSE)
  
  print(paste("Aggregated securely:", output_path))
}