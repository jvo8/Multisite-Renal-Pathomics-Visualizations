#-------------------------------------------------------------------------------
### DATA INPUT

# Import trained data sets.
UCD_and_Coimbra_data <- read.csv("unharmonized_train_with_batch.csv")
mayo_data <- read.csv("m_image_features.csv")

# Subset data to only contain UCD information.
UCD_data <- UCD_and_Coimbra_data[UCD_and_Coimbra_data$batch != "C", ]

# Add batch variable to Mayo data.
mayo_data$batch <- "M"

#-------------------------------------------------------------------------------
### eGFR FOR RITESH'S TOP PERFORMING MODELS:

## Top features identified for UCD
UCD_top <- UCD_data[, c(
  "Mean.Distance.Transform.By.Object.Area.Nuclei_artery",
  "Total.Object.Aspect.Ratio_artery",
  "Minor.Axis.Length_artery",
  "Mean.Distance.Transform.By.Nuclei.Area_artery",
  "Major.Axis.Length_glom",
  "Total.Object.Perimeter_glom",
  "Max.Distance.Transform.By.Object.Area.Nuclei_artery",
  "Max.Distance.Transform.Nuclei_glom",
  "Eosinophilic.Area_artery",
  "Radius..pixel._artery",
  "Max.Distance.Transform.Nuclei_artery",
  "Max.Distance.Transform.By.Nuclei.Area_artery"
)]

## Top features identified for Mayo
mayo_top <- mayo_data[, c(
  "Mean.Aspect.Ratio.Nuclei_tubule",
  "Max.Distance.Transform.By.Luminal.Space.Area_glom",
  "Max.Distance.Transform.By.Object.Area.Eosinophilic_tubule",
  "Max.Distance.Transform.By.Nuclei.Area_artery",
  "Mesangial.Area_glom",
  "Nuclei.Number_glom",
  "Mean.Distance.Transform.By.Object.Area.Nuclei_glom",
  "Major.Axis.Length_artery",
  "Nuclei.Number_artery",
  "Standard.Deviation.Aspect.Ratio.Nuclei_artery",
  "Total.Object.Perimeter_artery",
  "Max.Distance.Transform.By.Eosinophilic.Area_tubule",
  "Mean.Distance.Transform.By.Eosinophilic.Area_tubule",
  "Mean.Aspect.Ratio.Nuclei_artery",
  "Mean.Distance.Transform.By.Luminal.Space.Area_glom"
)]

#-------------------------------------------------------------------------------
### CORRELATION BAR PLOTS:

library(ggplot2)
library(grDevices)

## UC Davis
UCD.correlations <- data.frame(
  Feature = names(UCD_top),
  Correlation = sapply(names(UCD_top), function(feature) {
    cor(
      UCD_top[[feature]],
      UCD_data$eGFR,
      method = "spearman",
      use = "complete.obs"
    )
  })
)

UCD.correlations <- UCD.correlations[
  order(UCD.correlations$Correlation),
]

ggplot(
  UCD.correlations,
  aes(
    x = Correlation,
    y = factor(Feature, levels = Feature),
    fill = Correlation
  )
) +
  geom_col(width = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  scale_fill_gradientn(
    colors = rev(hcl.colors(12, "Burg"))
  ) +
  labs(
    title = "Direction of Association of Top Features with eGFR (UC Davis)",
    x = "Spearman Correlation Coefficient",
    y = "Feature"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.margin = margin(r = 40),
    plot.title = element_text(face = "bold", hjust = 0.5, margin = margin(t = 15, b = 15)),
    axis.title.x = element_text(margin = margin(t = 15, b = 15)),
    axis.title.y = element_text(margin = margin(r = 20, l = 20)),
    axis.line = element_line(color = "grey80", linewidth = 0.4),
    axis.ticks = element_line(color = "grey"),
    axis.ticks.length = unit(0.1, "cm")
  )


## Mayo

mayo.correlations <- data.frame(
  Feature = names(mayo_top),
  Correlation = sapply(names(mayo_top), function(feature) {
    cor(
      mayo_top[[feature]],
      mayo_data$eGFR,      # Replace with your eGFR column name if different
      method = "spearman",
      use = "complete.obs"
    )
  })
)

mayo.correlations <- mayo.correlations[
  order(mayo.correlations$Correlation),
]

ggplot(
  mayo.correlations,
  aes(
    x = Correlation,
    y = factor(Feature, levels = Feature),
    fill = Correlation
  )
) +
  geom_col(width = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40") +
  scale_fill_gradientn(
    colors = rev(hcl.colors(15, "Teal"))
  ) +
  labs(
    title = "Direction of Association of Top Features with eGFR (Mayo)",
    x = "Spearman Correlation Coefficient",
    y = "Feature"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.margin = margin(r = 40),
    plot.title = element_text(face = "bold", hjust = 0.5, margin = margin(t = 15, b = 15)),
    axis.title.x = element_text(margin = margin(t = 15, b = 15)),
    axis.title.y = element_text(margin = margin(r = 20, l = 20)),
    axis.line = element_line(color = "grey80", linewidth = 0.4),
    axis.ticks = element_line(color = "grey"),
    axis.ticks.length = unit(0.1, "cm")
  )

#-------------------------------------------------------------------------------
### View correlation coefficients:

UCD.correlations
mayo.correlations
