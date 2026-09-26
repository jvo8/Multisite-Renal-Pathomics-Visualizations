#-------------------------------------------------------------------------------
### Data Input/Preprocessing

## Importing unharmonized trained data set.
UCD_and_Coimbra_data <- read.csv("unharmonized_train_with_batch.csv")
mayo_data <- read.csv("m_image_features.csv")

## Separating datasets.
coimbra_data <- subset(UCD_and_Coimbra_data, batch == "C", select = -batch)
UCD_data <- subset(UCD_and_Coimbra_data, batch == "U", select = -batch)

#-------------------------------------------------------------------------------
### Hypothesis testing:
# Function for DGF that runs shapiro & and chooses t-test or wilocoxon.
DGF_test <- function(dataset, cohort_name) {
  
  # Obtain only features (no Subject ID, DGF, or batch).
  features_only <- dataset[, setdiff(colnames(dataset),
                                     c("Subject ID", "DGF", "batch")), drop = FALSE]
  
  # Convert features to numeric values
  num_col <- data.frame(lapply(features_only, function(x) as.numeric(as.character(x))))
  
  # Create empty dataframe that contains cohort, feature, Shapiro p values, test used, and test p value.
  results <- data.frame(
    Cohort = character(),
    Feature = character(),
    Shapiro_p_DGF = numeric(),
    Shapiro_p_nonDGF = numeric(),
    Test_Used = character(),
    Test_p_value = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Loop through each feature.
  for (feature in names(num_col)) {
    
    values <- num_col[[feature]]
    group <- dataset$DGF
    
    # Remove missing values.
    keep <- !is.na(values) & !is.na(group)
    values <- values[keep]
    group <- group[keep]
    
    # Make sure both DGF groups are present.
    if (!all(c("0", "1") %in% unique(group))) {
      next
    }
    
    # Split into DGF and non-DGF.
    values_DGF <- values[group == "1"]
    values_nonDGF <- values[group == "0"]
    
    # Make sure each group has enough values for Shapiro.
    if (length(values_DGF) < 3 || length(values_nonDGF) < 3) {
      next
    }
    
    # Shapiro test for each group.
    shapiro_DGF <- shapiro.test(values_DGF)
    shapiro_nonDGF <- shapiro.test(values_nonDGF)
    
    p_DGF <- shapiro_DGF$p.value
    p_nonDGF <- shapiro_nonDGF$p.value
    
    # Choose test based on normality.
    if (p_DGF > 0.05 & p_nonDGF > 0.05) {
      test_result <- t.test(values ~ group)
      test_used <- "t-test"
    } else {
      test_result <- wilcox.test(values ~ group)
      test_used <- "Wilcoxon"
    }
    
    # Store results into empty data frame.
    results <- rbind(results, data.frame(
      Cohort = cohort_name,
      Feature = feature,
      Shapiro_p_DGF = p_DGF,
      Shapiro_p_nonDGF = p_nonDGF,
      Test_Used = test_used,
      Test_p_value = test_result$p.value,
      stringsAsFactors = FALSE
    ))
  }
  
  return(results)
}

coimbra_results <- DGF_test(UCD_and_Coimbra_data, "Coimbra")
UCD_results <- DGF_test(UCD_data, "UC Davis")
mayo_results <- DGF_test(mayo_data, "Mayo")
#-------------------------------------------------------------------------------
### Plotting
# Function that extracts top 5 significant p values excluding subject ID and egfr
# across all cohorts.

# Combine all results dataframes, and then extract top 5 features from across all
# three cohorts.
all_results <- rbind(coimbra_results, UCD_results, mayo_results)

most_sig_feature <- function(results){
  unnecessary_features <- results[!(results$Feature %in% c("Subject_ID", "eGFR_12M")), ]
  top_five <- unnecessary_features[order(unnecessary_features$Test_p_value), ][1:5, , drop = FALSE]
  return(top_five)
}

top_5_features <- most_sig_feature(all_results)

# According to those significant 5 values, find them from the original dataset for DGF vs non DGF.
DGF_matching <- function(top, original) {
  matched_data <- original[, c("DGF", top$Feature), drop = FALSE]
  return(matched_data)
}

mayo_match <- DGF_matching(top_5_features, mayo_data)

# Function: for each top 5 feature, extract the DGF group and create a violin plot. 
# Then extract the no dgf group and create a separate violin plot. These violin plots then should be grouped together,
# and the groups for each feature should be side by side from most signifcant to least.
library(tidyr)
library(ggplot2)
library(MetBrewer)
library(grDevices)

violin_plotting <- function(top, original, feature_labels) {
  
  top <- top[order(top$Test_p_value), , drop = FALSE]
  
  keep_cols <- c("DGF", top$Feature)
  keep_cols <- keep_cols[keep_cols %in% colnames(original)]
  
  plot_data <- original[, keep_cols, drop = FALSE]
  
  plot_data_long <- pivot_longer(
    plot_data,
    cols = -DGF,
    names_to = "Feature",
    values_to = "Feature_Value"
  )
  
  plot_data_long$DGF <- factor(
    plot_data_long$DGF,
    levels = c("1", "0"),
    labels = c("DGF", "non-DGF")
  )
  
  plot_data_long$Feature <- factor(plot_data_long$Feature, levels = top$Feature)
  
  ggplot(plot_data_long, aes(x = DGF, y = Feature_Value, fill = DGF)) +
    geom_violin(trim = FALSE) +
    labs(
      title = "Significance of Wilcoxon Rank Sum Test (Mayo Clinic)",
      x = "DGF Status",
      y = "Measured Feature Value"
    ) +
    facet_wrap(
      ~ Feature,
      scales = "free",
      nrow = 1,
      labeller = labeller(Feature = feature_labels)
    ) +
    scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
    scale_fill_manual(
      values = hcl.colors(n = 2, palette = "Blues"),
      name = "DGF Status"
    ) +
    theme(
      strip.background = element_rect(fill = "#93B9E1", color = "black", linewidth = 0.5),
      strip.text = element_text(
        size = 9,
        face = "bold",
        lineheight = 1.1,
        margin = margin(6, 6, 6, 6)
      ),
      panel.background = element_rect(fill = "white"),
      panel.grid.major = element_line(color = "gray80", linewidth = 0.2),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 0.3),
      axis.title.x = element_text(face = "bold", margin = margin(t = 12)),
      axis.title.y = element_text(face = "bold", margin = margin(r = 12)),
      plot.title = element_text(face = "bold", hjust = 0.5, margin = margin(b = 15))
    )
}

# New labels 
top_5_labels <- c(
  "Mean.Distance.Transform.Luminal.Space_artery" = "Average Distance to \n Artery Lumen",
  "Sum.Distance.Transform.By.Luminal.Space.Area_artery" = "Total Distance per \n Lumen Area",
  "Sum.Distance.Transform.By.Object.Area.Luminal.Space_artery" = "Total Distance per \n Artery Area",
  "Max.Distance.Transform.Luminal.Space_artery" = "Maximum Distance to \n Artery Lumen",
  "Mesangial.Fraction_glom" = "Mesangial Area Proportion"
)

top_violin_plot <- violin_plotting(top_5_features, mayo_data, top_5_labels)
top_violin_plot
  