### Read the aggregated dfs --------------------
df1 <- read.csv(file.path(resultsDirectory, "5_1_agg.csv"))
df2 <- read.csv(file.path(resultsDirectory, "5_2_agg.csv"))
df3 <- read.csv(file.path(resultsDirectory, "5_3_agg.csv"))
df4 <- read.csv(file.path(resultsDirectory, "5_4_agg.csv"))
df5 <- read.csv(file.path(resultsDirectory, "5_5_agg.csv"))

if (!dir.exists("plots")) dir.create("plots")

# Helper function to plot Mean + Shaded STD + Patient Counts
plot_trend_with_sd <- function(df, title) {
  visits <- df$answer_time
  means  <- df$mean_value
  sds    <- df$sd_value
  counts <- df$patient_count 
  
  upper <- means + sds
  lower <- means - sds
  
  lower[lower < 0] <- 0
  upper[upper > 4] <- 4
  
  plot(visits, means, type = "n", 
       #xlim = c(0,10),
       ylim = c(0, 4), 
       main = title, cex.main = 1.3,
       xlab = "", ylab = "Average Score", 
       xaxt = "n") 
  
  polygon(c(visits, rev(visits)), c(upper, rev(lower)),
          col = rgb(0, 0, 1, 0.2), border = NA) 
  
  lines(visits, means, col = "blue", lwd = 2, type = "o", pch = 19)
  
  axis(1, at = visits, labels = paste0("Visit ", visits, "\n(n=", counts, ")"), padj = 0.5)
}

# Wrap all plotting commands in one function to easily export multiple formats
draw_all_plots <- function() {
  par(mfrow = c(5, 1), mar = c(6, 5, 7, 2))
  
  plot_trend_with_sd(df1, "PAID-5_1: Which of the following diabetes issues are currently a problem for you:\nFeeling scared when you think about living with diabetes?")
  plot_trend_with_sd(df2, "PAID-5_2: Which of the following diabetes issues are currently a problem for you:\nFeeling depressed when you think about living with diabetes?")
  plot_trend_with_sd(df3, "PAID-5_3: Which of the following diabetes issues are currently a problem for you:\nWorrying about the future and the possibility of serious complications?")
  plot_trend_with_sd(df4, "PAID-5_4: Which of the following diabetes issues are currently a problem for you:\nFeeling that diabetes is taking up too much of your mental and physical energy everyday?")
  plot_trend_with_sd(df5, "PAID-5_5: Which of the following diabetes issues are currently a problem for you:\nCoping with diabetes complications?")
}

# 1. Save High-Resolution JPEG (300 DPI)
jpeg(filename = "plots/PAID_Average_Change_With_STD.jpg", 
     width = 10, height = 24, units = "in", res = 300, quality = 100)
draw_all_plots()
dev.off()

# 2. Save SVG (Vector format for crisp scaling, sizes are in inches by default)
svg(filename = "plots/PAID_Average_Change_With_STD.svg", 
    width = 10, height = 24)
draw_all_plots()
dev.off()

print("PAID plots saved as High-Res JPEG and SVG.")