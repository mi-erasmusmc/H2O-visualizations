###Read the dfs --------------------
df1 <- read.csv(
  file.path(resultsDirectory, "5_1.csv")
)

df2 <- read.csv(
  file.path(resultsDirectory, "5_2.csv")
)

df3 <- read.csv(
  file.path(resultsDirectory, "5_3.csv")
)

df4 <- read.csv(
  file.path(resultsDirectory, "5_4.csv")
)

df5 <- read.csv(
  file.path(resultsDirectory, "5_5.csv")
)


# 1. Open the JPG file device
# Increased height to 1500 to fit 5 plots comfortably
jpeg(filename = "plots/PAID_Plots_scatter_plots.jpg", width = 800, height = 1500, quality = 90)

# 2. Set up the grid layout (5 rows, 1 column)
# 'mar' sets margins: Bottom, Left, Top, Right
par(mfrow = c(5, 1), mar = c(4, 4, 3, 1))

# --- Plot 1: PAID5_1 ---
plot(x = jitter(df1$answer_time), 
     y = jitter(df1$answer_value), 
     main = "PAID5_1", 
     xlab = "Answer Time", 
     ylab = "Answer Value",
     pch = 19, col = "blue")

# --- Plot 2: PAID5_2 ---
plot(x = jitter(df2$answer_time), 
     y = jitter(df2$answer_value), 
     main = "PAID5_2", 
     xlab = "Answer Time", 
     ylab = "Answer Value",
     pch = 19, col = "blue")

# --- Plot 3: PAID5_3 ---
plot(x = jitter(df3$answer_time), 
     y = jitter(df3$answer_value), 
     main = "PAID5_3", 
     xlab = "Answer Time", 
     ylab = "Answer Value",
     pch = 19, col = "blue")

# --- Plot 4: PAID5_4 ---
plot(x = jitter(df4$answer_time), 
     y = jitter(df4$answer_value), 
     main = "PAID5_4", 
     xlab = "Answer Time", 
     ylab = "Answer Value",
     pch = 19, col = "blue")

# --- Plot 5: PAID5_5 ---
plot(x = jitter(df5$answer_time), 
     y = jitter(df5$answer_value), 
     main = "PAID5_5", 
     xlab = "Answer Time", 
     ylab = "Answer Value",
     pch = 19, col = "blue")

# 3. Close the device to save the file
dev.off()












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










# 1. Open file
jpeg(filename = "plots/PAID_Overall_Boxplot.jpg", width = 900, height = 600, quality = 90) # Single plot, smaller height

# 2. Layout (1 row, 1 column)
par(mfrow = c(1, 1), mar = c(5, 5, 4, 2))

# 3. Combine DataFrames
# We verify columns match before binding
df_all <- rbind(df1, df2, df3, df4, df5)

# 4. Plot
boxplot(answer_value ~ factor(answer_time), data = df_all,
        main = "Overall Diabetes Distress (All Questions Combined)",
        xlab = "Visit Number",
        ylab = "Score (0-4)",
        col = "lightgreen",
        border = "darkgreen",
        names = paste(sort(unique(df_all$answer_time)), "Visit"))

# Add a grid for readability
grid(nx = NA, ny = NULL) 

# 5. Save
dev.off()




