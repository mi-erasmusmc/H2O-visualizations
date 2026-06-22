# Define the subdirectories for each institution
site1_dir <- "MUW"
site2_dir <- "EMC"

### Read the aggregated dfs for both institutions --------------------
# Institution A (Site 1)
df1_A <- read.csv(file.path(site1_dir, "5_1_agg.csv"))
df2_A <- read.csv(file.path(site1_dir, "5_2_agg.csv"))
df3_A <- read.csv(file.path(site1_dir, "5_3_agg.csv"))
df4_A <- read.csv(file.path(site1_dir, "5_4_agg.csv"))
df5_A <- read.csv(file.path(site1_dir, "5_5_agg.csv"))

# Institution B (Site 2)
df1_B <- read.csv(file.path(site2_dir, "5_1_agg.csv"))
df2_B <- read.csv(file.path(site2_dir, "5_2_agg.csv"))
df3_B <- read.csv(file.path(site2_dir, "5_3_agg.csv"))
df4_B <- read.csv(file.path(site2_dir, "5_4_agg.csv"))
df5_B <- read.csv(file.path(site2_dir, "5_5_agg.csv"))

# Create a master plots directory at the root level if it doesn't exist
if (!dir.exists("plots")) dir.create("plots")

# Helper function to plot dual means + shaded STDs
plot_dual_paid <- function(dfA, dfB, title) {
  
  # Merge datasets by visit number to ensure alignment
  df <- merge(dfA, dfB, by = "answer_time", all = TRUE, suffixes = c("_A", "_B"))
  visits <- df$answer_time
  
  # Define boundaries, constraining to the 0-4 scale
  upperA <- pmin(df$mean_value_A + df$sd_value_A, 4)
  lowerA <- pmax(df$mean_value_A - df$sd_value_A, 0)
  
  upperB <- pmin(df$mean_value_B + df$sd_value_B, 4)
  lowerB <- pmax(df$mean_value_B - df$sd_value_B, 0)
  
  # Setup empty plot frame with larger fonts (main title stays at 2)
  plot(visits, df$mean_value_A, type = "n", 
       ylim = c(0, 4), 
       main = title, cex.main = 2,
       xlab = "", ylab = "Average Score", 
       cex.lab = 1.8, cex.axis = 1.6,    # Scaled up axis labels and ticks
       xaxt = "n") 
  
  # Add shaded areas (filtering out NAs in case a site missed a visit)
  validA <- !is.na(df$mean_value_A)
  if(any(validA)) {
    polygon(c(visits[validA], rev(visits[validA])), c(upperA[validA], rev(lowerA[validA])),
            col = rgb(0, 0, 1, 0.15), border = NA) # Blue for Site 1
  }
  
  validB <- !is.na(df$mean_value_B)
  if(any(validB)) {
    polygon(c(visits[validB], rev(visits[validB])), c(upperB[validB], rev(lowerB[validB])),
            col = rgb(1, 0.5, 0, 0.15), border = NA) # Orange for Site 2
  }
  
  # Add the mean lines (line width at 4, increased data point size with cex = 1.5)
  lines(visits[validA], df$mean_value_A[validA], col = "blue", lwd = 4, type = "o", pch = 19, cex = 1.5)
  lines(visits[validB], df$mean_value_B[validB], col = "darkorange", lwd = 4, type = "o", pch = 15, cex = 1.5)
  
  # Add Legend with larger text and matching point sizes
  legend("topright", legend = c("MUW (n1)", "EMC (n2)"),
         col = c("blue", "darkorange"), pch = c(19, 15), lwd = 4, pt.cex = 1.5, bty = "n", cex = 1.8)
  
  # Add custom X-axis labels with dual patient counts
  countsA <- ifelse(is.na(df$patient_count_A), 0, df$patient_count_A)
  countsB <- ifelse(is.na(df$patient_count_B), 0, df$patient_count_B)
  
  countsA <- format_n(df$patient_count_A)
  countsB <- format_n(df$patient_count_B)
  
  axis(1, at = visits, labels = paste0("Visit ", visits, "\n(n1=", countsA, " | n2=", countsB, ")"), 
       padj = 0.5, cex.axis = 1.6) # Scaled up X-axis label font size
}

# Wrap all plotting commands
draw_all_plots <- function() {
  # Expanded margins (mar) and label positioning (mgp) to safely fit massive labels
  par(mfrow = c(5, 1), mar = c(8, 7, 7, 2), mgp = c(4.5, 1.5, 0))
  
  plot_dual_paid(df1_A, df1_B, "PAID-5_1: Feeling scared when you think about living with diabetes?")
  plot_dual_paid(df2_A, df2_B, "PAID-5_2: Feeling depressed when you think about living with diabetes?")
  plot_dual_paid(df3_A, df3_B, "PAID-5_3: Worrying about the future and the possibility of serious complications?")
  plot_dual_paid(df4_A, df4_B, "PAID-5_4: Feeling that diabetes is taking up too much of your mental and physical energy?")
  plot_dual_paid(df5_A, df5_B, "PAID-5_5: Coping with diabetes complications?")
}

# Save Outputs
jpeg(filename = "plots/Dual_PAID_Average_Change.jpg", width = 10, height = 24, units = "in", res = 300, quality = 100)
draw_all_plots()
dev.off()

svg(filename = "plots/Dual_PAID_Average_Change.svg", width = 10, height = 24)
draw_all_plots()
dev.off()

# Save Outputs (EPS)
postscript(file = "plots/Dual_PAID_Average_Change.eps", width = 10, height = 24, horizontal = FALSE, onefile = FALSE)
draw_all_plots()
dev.off()

print("PAID plots saved to /plots directory.")