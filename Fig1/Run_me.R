
# Install required packages if you haven't already:
# install.packages("tidyverse")
# install.packages("patchwork")
# install.packages("svglite") # Required for clean SVG export

library(tidyverse)
library(patchwork)

# 1. Load the data directly from text
raw_data <- "Match_Type,Generic,DM,IBD,MBC,LC,Total
Exact match,51 (86.4%),11 (18.6%),4 (13.3%),35 (66.0%),33† (67.3%),134 (53.6%)
Non-exact match,1 (1.7%),21 (35.6%),23 (76.7%),17 (32.1%),16 (32.7%),78 (31.2%)
No match,7 (11.9%),27 (45.6%),3 (10%),1 (1.8%),0 (0%),38 (15.2%)
Total,59 (100%),59 (100%),30 (100%),53 (100%),49 (100%),250 (100%)"

df <- read.csv(text = raw_data, stringsAsFactors = FALSE, check.names = FALSE)

# 2. Data Cleaning & Preparation
df_clean <- df %>% filter(Match_Type != "Total")

df_long <- df_clean %>%
  pivot_longer(
    cols = -Match_Type, 
    names_to = "Category", 
    values_to = "Value_Str"
  )

df_long <- df_long %>%
  mutate(
    Percentage = as.numeric(str_extract(Value_Str, "(?<=\\()[0-9.]+(?=%)")),
    Count = as.numeric(str_extract(Value_Str, "^[0-9]+")),
    Plot_Group = ifelse(Category == "Total", "Total Sum", "Diseases Subset")
  )

df_long$Match_Type <- factor(df_long$Match_Type, 
                             levels = c("Exact match", "Non-exact match", "No match"))

df_long$Category <- factor(df_long$Category, 
                           levels = rev(c("Generic", "DM", "IBD", "MBC", "LC", "Total")))

df_long$Plot_Group <- factor(df_long$Plot_Group, 
                             levels = c("Diseases Subset", "Total Sum"))


# Define the highly professional theme
my_theme <- theme_minimal(base_family = "sans") +
  theme(
    axis.text.y = element_text(face = "bold", size = 11, color = "#333333"),  
    axis.text.x = element_text(size = 10, color = "#444444"),
    axis.title.x = element_text(face = "bold", margin = margin(t = 12), size = 11),
    
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "#E5E5E5", linetype = "dashed"), 
    axis.line.x = element_line(color = "#666666", linewidth = 0.8),            
    
    # Grey background and white font for the facet labels
    strip.background = element_rect(fill = "grey50", color = "grey50", linewidth = 0.0),
    strip.text.y = element_text(face = "bold", size = 10, angle = 270, color = "white")
  )

# Darker Pastel / Muted Colors
darker_pastels <- c("Exact match" = "#76C2A5",      # Darker Pastel Green
                    "Non-exact match" = "#ECA882",  # Darker Pastel Peach/Muted Orange
                    "No match" = "#E2837E")         # Darker Pastel Pink/Muted Red


# 3. Create the UPPER plot (Diseases Subset)
p_upper <- ggplot(df_long %>% filter(Plot_Group == "Diseases Subset"), 
                  aes(x = Percentage, y = Category, fill = Match_Type)) +
  
  geom_bar(stat = "identity", position = "stack", width = 0.45) +
  
  # Text color kept dark ("#222222") to maintain contrast against the richer pastels
  geom_text(aes(label = ifelse(!is.na(Percentage) & Percentage > 0, paste0(Percentage, "%"), "")), 
            position = position_stack(vjust = 0.5), 
            size = 3.2, color = "#222222", fontface = "bold") +
  
  geom_text(aes(label = ifelse(!is.na(Percentage) & Percentage > 0, paste0("n=", Count), "")), 
            position = position_stack(vjust = 0.5), 
            size = 3.2, vjust = -1.5, color = "#222222") +
  
  scale_y_discrete(expand = expansion(add = c(0.6, 0.8))) +
  scale_fill_manual(values = darker_pastels) + 
  facet_grid(Plot_Group ~ .) +
  labs(x = "Percentage of total count of each subset (%)", y = NULL, fill = "Match_Type") +
  
  my_theme +
  theme(plot.margin = margin(t = 5, r = 5, b = 25, l = 5))


# 4. Create the LOWER plot (Total Sum)
p_lower <- ggplot(df_long %>% filter(Plot_Group == "Total Sum"), 
                  aes(x = Percentage, y = Category, fill = Match_Type)) +
  
  geom_bar(stat = "identity", position = "stack", width = 0.45) +
  
  geom_text(aes(label = ifelse(!is.na(Percentage) & Percentage > 0, paste0(Percentage, "%"), "")), 
            position = position_stack(vjust = 0.5), 
            size = 3.2, color = "#222222", fontface = "bold") +
  
  geom_text(aes(label = ifelse(!is.na(Percentage) & Percentage > 0, paste0("n=", Count), "")), 
            position = position_stack(vjust = 0.5), 
            size = 3.2, vjust = -1.5, color = "#222222") +
  
  scale_y_discrete(expand = expansion(add = c(0.6, 0.8))) +
  scale_fill_manual(values = darker_pastels) + 
  facet_grid(Plot_Group ~ .) +
  labs(x = "Percentage of total items (%)", y = NULL, fill = "Match_Type") +
  
  my_theme +
  theme(plot.margin = margin(t = 15, r = 5, b = 5, l = 5))


# 5. Combine the plots using Patchwork
final_plot <- p_upper / p_lower + 
  plot_layout(heights = c(4, 1.2), guides = "collect") & 
  theme(
    legend.position = "bottom",
    legend.title = element_blank(), 
    legend.key.size = unit(0.6, "cm"),
    legend.text = element_text(size = 11, face = "bold")
  )

# Display the plot
print(final_plot)


# 6. EXPORTING THE PLOT IN MULTIPLE FORMATS
# Using consistent dimensions (10x7.5 inches) for thick bars and clear spacing.

# Export as PNG (Great for presentations and standard web use)
ggsave("Outcome_Mapping_Final.png", plot = final_plot, width = 10, height = 7.5, dpi = 300)

# Export as SVG (Great for web, infinitely scalable, text remains editable)
ggsave("Outcome_Mapping_Final.svg", plot = final_plot, width = 10, height = 7.5)

# Export as EPS (Great for medical/scientific journals, requires a PostScript viewer)
# Note: R handles EPS natively, but fallback device is cairo_ps for better font handling if needed
ggsave("Outcome_Mapping_Final.eps", plot = final_plot, width = 10, height = 7.5, device = cairo_ps)