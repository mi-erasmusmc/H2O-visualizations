# Define the subdirectories for each institution
site1_dir <- "MUW"
site2_dir <- "EMC"

### Read the aggregated dfs for both institutions --------------------
# Institution A (Site 1)
df_hba1c_A <- read.csv(file.path(site1_dir, "hba1c_value_agg.csv"))
df_chol_A  <- read.csv(file.path(site1_dir, "total_cholesterol_value_agg.csv"))
df_trig_A  <- read.csv(file.path(site1_dir, "triglycerides_value_agg.csv"))
df_sys_A   <- read.csv(file.path(site1_dir, "systolic_bp_value_agg.csv"))
df_dia_A   <- read.csv(file.path(site1_dir, "diastolic_bp_value_agg.csv"))

# Institution B (Site 2)
df_hba1c_B <- read.csv(file.path(site2_dir, "hba1c_value_agg.csv"))
df_chol_B  <- read.csv(file.path(site2_dir, "total_cholesterol_value_agg.csv"))
df_trig_B  <- read.csv(file.path(site2_dir, "triglycerides_value_agg.csv"))
df_sys_B   <- read.csv(file.path(site2_dir, "systolic_bp_value_agg.csv"))
df_dia_B   <- read.csv(file.path(site2_dir, "diastolic_bp_value_agg.csv"))


# Convert values
df_hba1c_B[, 2:3] <- lapply(df_hba1c_B[, 2:3], hba1c_to_percent)
df_chol_B[, 2:3]  <- lapply(df_chol_B[, 2:3], convert_lipid)
df_trig_B[, 2:3]  <- lapply(df_trig_B[, 2:3], convert_lipid)

# Create a master plots directory at the root level if it doesn't exist
if (!dir.exists("plots")) dir.create("plots")

# Helper function to plot dual clinical means + dynamic axes
plot_dual_clinical <- function(dfA, dfB, title, y_axis_label) {
  
  # Merge datasets by visit number
  df <- merge(dfA, dfB, by = "answer_time", all = TRUE, suffixes = c("_A", "_B"))
  visits <- df$answer_time
  
  # Calculate bounds
  upperA <- df$mean_value_A + df$sd_value_A
  lowerA <- pmax(df$mean_value_A - df$sd_value_A, 0) # Prevent dropping below 0
  
  upperB <- df$mean_value_B + df$sd_value_B
  lowerB <- pmax(df$mean_value_B - df$sd_value_B, 0)
  
  # Dynamic Y-Axis: Look at both datasets to find the absolute min and max
  y_min <- min(c(lowerA, lowerB), na.rm = TRUE) * 0.9
  y_max <- max(c(upperA, upperB), na.rm = TRUE) * 1.1
  
  # Setup empty plot frame
  plot(visits, df$mean_value_A, type = "n", 
       ylim = c(y_min, y_max), 
       main = title, cex.main = 1.3,
       xlab = "", ylab = y_axis_label, 
       xaxt = "n") 
  
  # Add shaded areas
  validA <- !is.na(df$mean_value_A)
  if(any(validA)) {
    polygon(c(visits[validA], rev(visits[validA])), c(upperA[validA], rev(lowerA[validA])),
            col = rgb(0, 0, 1, 0.15), border = NA) # Red for Site 1
  }
  
  validB <- !is.na(df$mean_value_B)
  if(any(validB)) {
    polygon(c(visits[validB], rev(visits[validB])), c(upperB[validB], rev(lowerB[validB])),
            col = rgb(1, 0.5, 0, 0.15), border = NA) # Teal for Site 2
  }
  
  # Add the mean lines
  lines(visits[validA], df$mean_value_A[validA], col = "blue", lwd = 2, type = "o", pch = 19)
  lines(visits[validB], df$mean_value_B[validB], col = "darkorange", lwd = 2, type = "o", pch = 15)
  
  # Add Legend
  legend("topright", legend = c("MUW (n1)", "EMC (n2)"),
         col = c("blue", "darkorange"), pch = c(19, 15), lwd = 2, bty = "n")
  
  # Add custom X-axis labels
  countsA <- ifelse(is.na(df$patient_count_A), 0, df$patient_count_A)
  countsB <- ifelse(is.na(df$patient_count_B), 0, df$patient_count_B)
  
  countsA <- format_n(df$patient_count_A)
  countsB <- format_n(df$patient_count_B)
  
   
  axis(1, at = visits, labels = paste0("Visit ", visits, "\n(n1=", countsA, " | n2=", countsB, ")"), padj = 0.5)
}

# Wrap all plotting commands
draw_all_plots <- function() {
  par(mfrow = c(5, 1), mar = c(6, 5, 7, 2))
  
  plot_dual_clinical(df_hba1c_A, df_hba1c_B, "Clinical Trend: Hemoglobin A1c (HbA1c)", "HbA1c (%)")
  plot_dual_clinical(df_chol_A, df_chol_B, "Clinical Trend: Total Cholesterol", "Cholesterol (mg/dL)")
  plot_dual_clinical(df_trig_A, df_trig_B, "Clinical Trend: Triglycerides", "Triglycerides (mg/dL)")
  plot_dual_clinical(df_sys_A, df_sys_B, "Clinical Trend: Systolic Blood Pressure", "mmHg")
  plot_dual_clinical(df_dia_A, df_dia_B, "Clinical Trend: Diastolic Blood Pressure", "mmHg")
}




# Save Outputs
jpeg(filename = "plots/Dual_Clinical_Average_Change.jpg", width = 10, height = 24, units = "in", res = 300, quality = 100)
draw_all_plots()
dev.off()

svg(filename = "plots/Dual_Clinical_Average_Change.svg", width = 10, height = 24)
draw_all_plots()
dev.off()

# Save Outputs (EPS)
postscript(file = "plots/Dual_Clinical_Average_Change.eps", width = 10, height = 24, horizontal = FALSE, onefile = FALSE)
draw_all_plots()
dev.off()

print("Clinical plots saved to /plots directory.")