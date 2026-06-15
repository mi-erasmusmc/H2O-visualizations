### Read the aggregated dfs --------------------
df_hba1c <- read.csv(file.path(resultsDirectory, "hba1c_value_agg.csv"))
df_chol  <- read.csv(file.path(resultsDirectory, "total_cholesterol_value_agg.csv"))
df_trig  <- read.csv(file.path(resultsDirectory, "triglycerides_value_agg.csv"))
df_sys   <- read.csv(file.path(resultsDirectory, "systolic_bp_value_agg.csv"))
df_dia   <- read.csv(file.path(resultsDirectory, "diastolic_bp_value_agg.csv"))

if (!dir.exists("plots")) dir.create("plots")

# Helper function for Clinical Data (Dynamic Y-Axis + Red Styling + Counts)
plot_clinical_trend <- function(df, title, y_axis_label) {
  visits <- df$answer_time
  means  <- df$mean_value
  sds    <- df$sd_value
  counts <- df$patient_count 
  
  upper <- means + sds
  lower <- means - sds
  
  lower[lower < 0] <- 0 
  
  y_min <- min(lower, na.rm = TRUE) * 0.9
  y_max <- max(upper, na.rm = TRUE) * 1.1
  
  plot(visits, means, type = "n", 
       #xlim = c(0,10),
       ylim = c(y_min, y_max), 
       main = title, cex.main = 1.3,
       xlab = "", ylab = y_axis_label, 
       xaxt = "n") 
  
  polygon(c(visits, rev(visits)), c(upper, rev(lower)),
          col = rgb(1, 0, 0, 0.2), border = NA) 
  
  lines(visits, means, col = "red", lwd = 2, type = "o", pch = 19)
  
  axis(1, at = visits, labels = paste0("Visit ", visits, "\n(n=", counts, ")"), padj = 0.5)
}

# Wrap all plotting commands in one function to easily export multiple formats
draw_all_plots <- function() {
  par(mfrow = c(5, 1), mar = c(6, 5, 7, 2))
  
  plot_clinical_trend(df_hba1c, "Clinical Trend: Hemoglobin A1c (HbA1c)", "HbA1c (%)")
  plot_clinical_trend(df_chol, "Clinical Trend: Total Cholesterol", "Cholesterol (mg/dL)")
  plot_clinical_trend(df_trig, "Clinical Trend: Triglycerides", "Triglycerides (mg/dL)")
  plot_clinical_trend(df_sys, "Clinical Trend: Systolic Blood Pressure", "mmHg")
  plot_clinical_trend(df_dia, "Clinical Trend: Diastolic Blood Pressure", "mmHg")
}

# 1. Save High-Resolution JPEG (300 DPI)
jpeg(filename = "plots/Clinical_Average_Change_With_STD.jpg", 
     width = 10, height = 24, units = "in", res = 300, quality = 100)
draw_all_plots()
dev.off()

# 2. Save SVG (Vector format for crisp scaling)
svg(filename = "plots/Clinical_Average_Change_With_STD.svg", 
    width = 10, height = 24)
draw_all_plots()
dev.off()

print("Clinical plots saved as High-Res JPEG and SVG.")