
# Converting from mmol/mol -> percentage
# Function to convert mmol/mol to percentage
hba1c_to_percent <- function(mmol_mol) {
  percent <- (mmol_mol / 10.929) + 2.15
  return(round(percent, 2))
}

convert_lipid <- function(value, type = "cholesterol", to = "mg/dl") {
  # Define conversion factors
  factor <- if (tolower(type) == "triglycerides") 88.57 else 38.67
  
  # Perform conversion based on direction
  if (tolower(to) == "mg/dl") {
    return(value * factor)
  } else if (tolower(to) == "mmol/l") {
    return(value / factor)
  } else {
    stop("Invalid 'to' unit. Use 'mg/dl' or 'mmol/l'.")
  }
}


# Add custom X-axis labels
# Define a helper to format the count
format_n <- function(x) {
  ifelse(is.na(x) | x < 5, "<5", as.character(x))
}
