###Read the dfs --------------------
df1 <- read.csv(
  file.path(resultsDirectory, "5_1_mix.csv")
)

df2 <- read.csv(
  file.path(resultsDirectory, "5_2_mix.csv")
)

df3 <- read.csv(
  file.path(resultsDirectory, "5_3_mix.csv")
)

df4 <- read.csv(
  file.path(resultsDirectory, "5_4_mix.csv")
)

df5 <- read.csv(
  file.path(resultsDirectory, "5_5_mix.csv")
)






# 1. Open file
# Ensure the folder "plots" exists, or remove "plots/" from the filename
jpeg(filename = "plots/PAID_Average_Change_With_STD.jpg", width = 900, height = 2200, quality = 90)

# 2. Layout
# The top margin (3rd number) is set to 7 to allow space for the long titles
par(mfrow = c(5, 1), mar = c(5, 5, 7, 2))

# Helper function to plot Mean + Shaded STD
plot_trend_with_sd <- function(df, title) {
  # Calculate stats
  means <- tapply(df$answer_value, df$answer_time, mean, na.rm = TRUE)
  sds   <- tapply(df$answer_value, df$answer_time, sd, na.rm = TRUE)
  visits <- as.numeric(names(means))
  
  # Define upper and lower boundaries (Mean +/- SD)
  upper <- means + sds
  lower <- means - sds
  
  # Setup empty plot frame
  plot(visits, means, type = "n", 
       ylim = c(0, 4), # Fixed scale 0-4
       main = title, cex.main = 1.3,
       xlab = "Visit Number", ylab = "Average Score",
       xaxt = "n") # Turn off default x-axis to customize later
  
  # Add shaded area (Polygon)
  # We trace the top line forward and bottom line backward to close the shape
  polygon(c(visits, rev(visits)), c(upper, rev(lower)),
          col = rgb(0, 0, 1, 0.2), border = NA) # Blue with transparency
  
  # Add the mean line
  lines(visits, means, col = "blue", lwd = 2, type = "o", pch = 19)
  
  # Add custom x-axis labels
  axis(1, at = visits, labels = paste(visits, "Visit"))
}

# --- Plot the 5 Questions with Full Titles ---

plot_trend_with_sd(df1, "PAID-5_1: Which of the following diabetes issues are currently a problem for you:\nFeeling scared when you think about living with diabetes?")

plot_trend_with_sd(df2, "PAID-5_2: Which of the following diabetes issues are currently a problem for you:\nFeeling depressed when you think about living with diabetes?")

plot_trend_with_sd(df3, "PAID-5_3: Which of the following diabetes issues are currently a problem for you:\nWorrying about the future and the possibility of serious complications?")

plot_trend_with_sd(df4, "PAID-5_4: Which of the following diabetes issues are currently a problem for you:\nFeeling that diabetes is taking up too much of your mental and physical energy everyday?")

plot_trend_with_sd(df5, "PAID-5_5: Which of the following diabetes issues are currently a problem for you:\nCoping with diabetes complications?")

# 3. Save
dev.off()










