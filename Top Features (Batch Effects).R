#-------------------------------------------------------------------------------
### DATA INPUT:

## Import trained data sets.
UCD_and_Coimbra_data <- read.csv("unharmonized_train_with_batch.csv")
mayo_data <- read.csv("m_image_features.csv")

## Add batch variable to Mayo data.
mayo_data$batch <- "M"

## Combine data sets.
common_cols <- intersect(colnames(UCD_and_Coimbra_data), colnames(mayo_data))
all_data <- rbind(UCD_and_Coimbra_data[, common_cols],
                  mayo_data[, common_cols])

## Sort by cohort.
all_data <- all_data[order(all_data$batch), ]

#-------------------------------------------------------------------------------
### HYPOTHESIS TESTING:

## Check normality of features using the Shapiro-Wilk test
hyp_test <- function(dataset) {
  
  ## Obtain only features (no Subject ID, DGF, or batch).
  features_only <- dataset[, setdiff(colnames(dataset),
                                     c("Subject ID", "DGF", "batch")), drop = FALSE]
  
  # Convert features to numeric values.
  num_col <- data.frame(lapply(features_only, function(x) as.numeric(as.character(x))))
  
  # Create empty data frame.
  results <- data.frame(
    Feature = character(),
    Shapiro_p_value = numeric(),
    Test_Used = character(),
    Test_p_value = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Loop through each feature.
  for (feature in names(num_col)) {
    
    values <- num_col[[feature]]
    group <- dataset$batch
    
    # Remove missing values.
    keep <- !is.na(values) & !is.na(group)
    values <- values[keep]
    group <- group[keep]
    
    # Make sure enough values exist.
    if (length(values) < 3) {
      next
    }
    
    # Shapiro test for each feature.
    shapiro_result <- shapiro.test(values)
    p_val <- shapiro_result$p.value
    
    # Choose test based on normality.
    if (p_val > 0.05) {
      test_result <- aov(values ~ group)
      test_p <- summary(test_result)[[1]][["Pr(>F)"]][1]
      test_used <- "ANOVA"
    } else {
      test_result <- kruskal.test(values ~ group)
      test_p <- test_result$p.value
      test_used <- "Kruskal-Wallis"
    }
    
    # Store results into dataframe.
    results <- rbind(results, data.frame(
      Feature = feature,
      Shapiro_p_value = p_val,
      Test_Used = test_used,
      Test_p_value = test_p,
      stringsAsFactors = FALSE
    ))
  }
  
  return(results)
}

all_results <- hyp_test(all_data)

#-------------------------------------------------------------------------------
### TOP 5 MOST SIGNIFICANT FEATURES:

most_sig_feature <- function(results) {
  unnecessary_features <- results[!(results$Feature %in% c("Subject_ID", "eGFR_12M")), ]
  top_five <- unnecessary_features[order(unnecessary_features$Test_p_value), ][1:5, ]
  return(top_five)
}

top_5_features <- most_sig_feature(all_results)

#-------------------------------------------------------------------------------
### MATCH TOP 5 FEATURES BACK TO ORIGINAL DATA:

cohort_matching <- function(top, original) {
  matched_data <- original[, c("batch", top$Feature), drop = FALSE]
  return(matched_data)
}

matched_top5 <- cohort_matching(top_5_features, all_data)
#-------------------------------------------------------------------------------
### PLOTTING:

library(tidyr)
library(ggplot2)
library(MetBrewer)
library(ggpubr)

violin_plotting <- function(top, original, feature_labels) {
  
  top <- top[order(top$Test_p_value), , drop = FALSE]
  
  keep_cols <- c("batch", top$Feature)
  keep_cols <- keep_cols[keep_cols %in% colnames(original)]
  
  plot_data <- original[, keep_cols, drop = FALSE]
  
  plot_data_long <- pivot_longer(
    plot_data,
    cols = -batch,
    names_to = "Feature",
    values_to = "Feature_Value"
  )
  
  plot_data_long$batch <- factor(
    plot_data_long$batch,
    levels = c("C", "U", "M"),
    labels = c("Coimbra", "UCD", "Mayo")
  )
  
  plot_data_long$Feature <- factor(plot_data_long$Feature, levels = top$Feature)
  
  ggplot(plot_data_long, aes(x = batch, y = Feature_Value, fill = batch)) +
    geom_violin(trim = FALSE) +
    labs(
      title = "Significance of Kruskal-Wallis Test",
      x = "Cohort",
      y = "Measured Feature Value"
    ) +
    facet_wrap(
      ~ Feature,
      scales = "free",
      nrow = 1,
      labeller = labeller(Feature = feature_labels)
    ) +
    scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
    scale_fill_manual(values = met.brewer("Hiroshige", n = 3), name = "Cohort") +
    theme(
      strip.background = element_rect(fill = "#fed4d2", color = "black", linewidth = 0.5),
      strip.text = element_text(
        size = 9,
        face = "bold",
        lineheight = 1.1,
        margin = margin(6, 6, 6, 6)
      ),
      panel.background = element_rect(fill = "white"),
      panel.grid.major = element_line(color = "gray85", linewidth = 0.3),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA),
      axis.title.x = element_text(face = "bold", margin = margin(t = 12)),
      axis.title.y = element_text(face = "bold", margin = margin(r = 12)),
      plot.title = element_text(face = "bold", hjust = 0.5, margin = margin(b = 15))
    )
}

# Labels 
feature_labels <- c(
  "Correlation.Nuclei_artery" = "Nuclei Spacing (Artery)",
  "Correlation.Nuclei_tubule" = "Nuclei Spacing (Tubule)",
  "Mean.Nuclear.Area_artery" = "Mean Nuclear Size (Artery)",
  "Mean.Nuclear.Area_tubule" = "Mean Nuclear Size (Tubule)",
  "Nuclei.Number_tubule" = "Nuclei Count (Tubule)"
)

violin_plotting(top_5_features, all_data, feature_labels)
