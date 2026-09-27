# Multisite-Renal-Pathomics-Visualizations
Violin plots and horizontal bar charts for visualizing the distribution and direction of pathomic feature correlations with kidney transplant outcomes.

## Important Note

The code below was written specifically for these three cohorts (UC Davis, Mayo Clinic, and Coimbra) and their corresponding patient data. It is meant to create visualizations and run statistical comparisons for this dataset only. If additional cohorts are added in the future, further edits to the code will likely be needed (e.g., updating cohort labels, group comparisons, and etc.). This code does not perform any harmonization or batch-effect correction. It only generates visualizations and statistical results based on the data as given.

## Overview

This project looks at image-based features (pathomic features) taken from kidney biopsy images from three medical centers: UC Davis, Mayo Clinic, and Coimbra. The goal is to see how much these features vary between sites and to find features linked to Delayed Graft Function (DGF).

### Background

Data from each medical center was analyzed as-is, without any correction for site-to-site differences (no harmonization or batch-effect correction). Differences in features between cohorts could come from:

- Different scanners
- Different imaging methods
- Different preprocessing steps
- Real differences between patient groups at each site

### Purpose

- Figure out whether differences between cohorts are caused by site-related factors (scanners, protocols, etc.) or real biological differences.
- Give the lab a baseline (unharmonized) result to compare against when testing harmonization methods later.
- Find features linked to DGF that could help predict kidney outcomes in the future.

## Approach to Creating Violin Plots

### Step 1: Check if Data is Normal

We looked at a sample of features across patients at each site to see if the data followed a normal distribution. This decided which type of statistical test to use:

- If data looked normal, use tests that compare averages:
  - ANOVA across cohorts (UC Davis vs. Mayo vs. Coimbra)
  - Two-sample t-test within each cohort (DGF vs. non-DGF)
- If data did not look normal, use tests that don't assume a normal distribution:
  - Kruskal-Wallis test across cohorts
  - Wilcoxon rank-sum test within each cohort (DGF vs. non-DGF)

### Step 2: Run the Tests

- ANOVA / Kruskal-Wallis: checks if a feature is different across the three cohorts.
- T-test / Wilcoxon rank-sum: checks if a feature is different between DGF and non-DGF patients.

### Step 3: Make Violin Plots

We made violin plots to show the top 5 most significant features from each test. Violin plots were used because they show:

- The full shape of each feature's distribution (not just the average)
- How dense the values are across the range
- How spread out or variable each group is
- How much the groups overlap or stay separate

## Summary of Workflow

### Across Cohorts (Coimbra vs. UC Davis vs. Mayo)

1. Tested every feature across the three cohorts.
2. Recorded a p-value for each feature.
3. Picked the top 5 features with the smallest p-values.
4. Made violin plots of these features, split by cohort.

### Within Cohorts (DGF vs. Non-DGF)

1. Tested every feature for DGF vs. non-DGF, separately in each cohort.
2. Recorded a p-value for each feature.
3. Picked the top 5 features with the smallest p-values.
4. Made violin plots of these features, split by DGF status.

### Direction of Correlations for Top Pathomic Features Identified by Top Performing Model
1. Pulled the list of top eGFR pathomic features identified by the top-performing model.
2. Compared this list against the p-values generated from the unharmonized feature analysis described above.
3. Ran a correlation test between the two sets of features to see how they related to each other.
4. Created a horizontal bar plot to visualize the direction (positive or negative) and strength of the correlation coefficients for each feature.

## Results & Visuals

### DGF vs. Non-DGF (Within Each Cohort)

The top 5 features that separated DGF from non-DGF patients (all found in the Mayo Clinic data) were:

1. Average Distance to Artery Lumen
2. Total Distance per Lumen Area
3. Total Distance per Artery Area
4. Maximum Distance to Artery Lumen
5. Mesangial Area Proportion

- Tested using the Wilcoxon rank-sum test.
- All five features were strongly significant (p < 0.001) and showed a clear split between DGF and non-DGF patients.
- These features might reflect imaging patterns tied to DGF and could help predict kidney outcomes down the line.

### Across Cohorts (UC Davis vs. Mayo vs. Coimbra)

The top 5 features that differed the most between institutions were:

1. Mean Nuclear Size (Tubule)
2. Mean Nuclear Size (Artery)
3. Nuclei Spacing (Tubule)
4. Nuclei Spacing (Artery)
5. Nuclei Count (Tubule)

![Final ANOVA/Kruskal-Wallis Plot](path/to/'/Users/catthuyvo/Desktop/STARAPTOR Lab/Top Features Across All 3 Cohorts (Batch Effects)/Final ANOVA:Kruskal-Wallis Violin Plot')

- Tested using the Kruskal-Wallis test.
- All five features showed strong, consistent differences between cohorts (p < 0.001).
- This points to systematic differences between sites, likely from scanner or protocol differences, or batch effects.
- These features are good candidates for checking whether future harmonization methods actually reduce differences between cohorts.

## Key Takeaways

- DGF-related features all came from the Mayo Clinic data, suggesting something site-specific worth digging into further.
- Cross-cohort differences mostly showed up in nuclear size and spacing features, which lines up with what you'd expect from technical differences (scanner/protocol) rather than pure biology.
- These unharmonized results give the lab a starting point to compare against once harmonization methods are tested.
