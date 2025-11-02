# ============================================================================
# FIX DATA DICTIONARY - Instrument Mapping Corrections
# ============================================================================

library(readr)
library(dplyr)

# Read data dictionary
dict <- read_csv("data_dictionary_enhanced.csv", show_col_types = FALSE)

cat("Original dictionary:", nrow(dict), "rows\n\n")

# ============================================================================
# FIX 1: DSST Standardized Score (Field 180) - Line 402
# ============================================================================

cat("FIX 1: DSST Standardized Score (Field 180)\n")
dict_fix1 <- dict %>%
  mutate(
    instrument = ifelse(
      original_name == "44. Standardized Score - 180",
      "DSST",
      instrument
    ),
    section = ifelse(
      original_name == "44. Standardized Score - 180",
      "cognitive",
      section
    ),
    prefix = ifelse(
      original_name == "44. Standardized Score - 180",
      "cog",
      prefix
    ),
    new_name = ifelse(
      original_name == "44. Standardized Score - 180",
      "cog_standardized_score_v1",
      new_name
    ),
    description = ifelse(
      original_name == "44. Standardized Score - 180",
      "DSST standardized score (pen & paper version)",
      description
    )
  )

cat("  Changed instrument from NA to DSST\n")
cat("  Changed section from medical to cognitive\n")
cat("  Changed prefix from med to cog\n")
cat("  Changed new_name from med_standardized_score_v1 to cog_standardized_score_v1\n\n")

# ============================================================================
# FIX 2: WHO-5 Total Score - Line 341
# ============================================================================

cat("FIX 2: WHO-5 Total Score\n")
dict_fix2 <- dict_fix1 %>%
  mutate(
    instrument = ifelse(
      original_name == "19. WHO-5 - Total Score - 135",
      "WHO-5",
      instrument
    )
  )

cat("  Changed instrument from NA to WHO-5\n\n")

# ============================================================================
# FIX 3: SPPB Components - Wrong Category
# ============================================================================

cat("FIX 3: SPPB Components (Gait Speed & Chair Stand)\n")
dict_fix3 <- dict_fix2 %>%
  mutate(
    section = ifelse(
      original_name %in% c("50. Gait speed test score - 431", "51. Chair stand test score - 432"),
      "physical",
      section
    ),
    prefix = ifelse(
      original_name %in% c("50. Gait speed test score - 431", "51. Chair stand test score - 432"),
      "phys",
      prefix
    ),
    new_name = case_when(
      original_name == "50. Gait speed test score - 431" ~ "phys_gait_speed_test_score",
      original_name == "51. Chair stand test score - 432" ~ "phys_chair_stand_test_score",
      TRUE ~ new_name
    )
  )

cat("  Changed 2 fields from medical to physical\n")
cat("  Updated new_names: med_* -> phys_*\n\n")

# ============================================================================
# FIX 4: Gait Speed - Wrong Category (6 fields)
# ============================================================================

cat("FIX 4: Gait Speed fields in wrong category\n")
gait_speed_fields <- c(
  "8. Slow walk: Walking pace measurement of over seven seconds in order to walk three meters - 245",
  "34. Walking? (Approx. 10m or 32 ft or 14 steps) - 0.  - 164",
  "34. Walking? (Approx. 10m or 32 ft or 14 steps) - 1. Walking -difficulty? - 164",
  "35. Walk - did you require help? - 0.  - 166",
  "35. Walk - did you require help? - 1. Walk- Help required - 166",
  "35. Walk - did you require help? - 2. Other - 166"
)

dict_fix4 <- dict_fix3 %>%
  mutate(
    section = ifelse(
      original_name %in% gait_speed_fields,
      "physical",
      section
    ),
    prefix = ifelse(
      original_name %in% gait_speed_fields,
      "phys",
      prefix
    )
  )

# Update new_names for gait speed fields
for (i in 1:nrow(dict_fix4)) {
  if (dict_fix4$original_name[i] %in% gait_speed_fields) {
    old_name <- dict_fix4$new_name[i]
    # Replace cog_ or med_ with phys_
    new_name <- gsub("^(cog|med)_", "phys_", old_name)
    dict_fix4$new_name[i] <- new_name
  }
}

cat("  Changed 6 fields to physical category\n")
cat("  Updated new_names: cog_*/med_* -> phys_*\n\n")

# ============================================================================
# FIX 5: Grip Strength - Muscle Weakness Wrong Category
# ============================================================================

cat("FIX 5: Grip Strength muscle weakness field\n")
dict_fix5 <- dict_fix4 %>%
  mutate(
    section = ifelse(
      original_name == "9. Muscle weakness: Dynamometer measurement that tests hand grip strength. Weakness is defined as results being less then 20% on the scale according to gender and body mass. - 246",
      "physical",
      section
    ),
    prefix = ifelse(
      original_name == "9. Muscle weakness: Dynamometer measurement that tests hand grip strength. Weakness is defined as results being less then 20% on the scale according to gender and body mass. - 246",
      "phys",
      prefix
    )
  )

# Update new_name for muscle weakness
for (i in 1:nrow(dict_fix5)) {
  if (dict_fix5$original_name[i] == "9. Muscle weakness: Dynamometer measurement that tests hand grip strength. Weakness is defined as results being less then 20% on the scale according to gender and body mass. - 246") {
    old_name <- dict_fix5$new_name[i]
    new_name <- gsub("^demo_", "phys_", old_name)
    dict_fix5$new_name[i] <- new_name
  }
}

cat("  Changed from demographic to physical\n")
cat("  Updated new_name: demo_* -> phys_*\n\n")

# ============================================================================
# FIX 6: Investigate Standardized Scores 197 & 199
# ============================================================================

cat("FIX 6: Investigating standardized scores fields 197 & 199\n")

# Find what comes before field 197
field_197_context <- dict_fix5 %>%
  filter(position >= 407 & position <= 411) %>%
  select(original_name, position, instrument, new_name)

cat("  Context around field 197:\n")
print(field_197_context)

# Find what comes before field 199
field_199_context <- dict_fix5 %>%
  filter(position >= 409 & position <= 413) %>%
  select(original_name, position, instrument, new_name)

cat("\n  Context around field 199:\n")
print(field_199_context)

cat("\n  ANALYSIS: Fields 197 & 199 are standardized scores for Verbal Fluency tests\n")
cat("  Field 197 follows VF phonemic (196)\n")
cat("  Field 199 follows VF semantic (198)\n")
cat("  Creating 'Verbal Fluency' instrument and assigning all 4 VF fields to it\n\n")

# Fix VF fields - create Verbal Fluency instrument
dict_fix6 <- dict_fix5 %>%
  mutate(
    # Assign VF phonemic and semantic to Verbal Fluency instrument
    instrument = case_when(
      original_name == "60. VF phonemic - Total Score - 196" ~ "Verbal Fluency",
      original_name == "62. VF semantic - Total Score - 198" ~ "Verbal Fluency",
      original_name == "61. Standardized Score - 197" ~ "Verbal Fluency",
      original_name == "63. Standardized Score - 199" ~ "Verbal Fluency",
      TRUE ~ instrument
    ),
    # Fix standardized scores category (should be cognitive, not medical)
    section = case_when(
      original_name == "61. Standardized Score - 197" ~ "cognitive",
      original_name == "63. Standardized Score - 199" ~ "cognitive",
      TRUE ~ section
    ),
    prefix = case_when(
      original_name == "61. Standardized Score - 197" ~ "cog",
      original_name == "63. Standardized Score - 199" ~ "cog",
      TRUE ~ prefix
    ),
    # Update new_names for standardized scores
    new_name = case_when(
      original_name == "61. Standardized Score - 197" ~ "cog_vf_phonemic_standardized_score",
      original_name == "63. Standardized Score - 199" ~ "cog_vf_semantic_standardized_score",
      TRUE ~ new_name
    ),
    # Update descriptions
    description = case_when(
      original_name == "60. VF phonemic - Total Score - 196" ~ "Verbal Fluency phonemic test score",
      original_name == "61. Standardized Score - 197" ~ "Verbal Fluency phonemic standardized score",
      original_name == "62. VF semantic - Total Score - 198" ~ "Verbal Fluency semantic test score",
      original_name == "63. Standardized Score - 199" ~ "Verbal Fluency semantic standardized score",
      TRUE ~ description
    )
  )

cat("  ✓ Created 'Verbal Fluency' instrument\n")
cat("  ✓ Assigned 4 fields to Verbal Fluency\n")
cat("  ✓ Fixed standardized scores category (medical -> cognitive)\n")
cat("  ✓ Updated new_names for better clarity\n\n")

# Use the fixed version
dict_final <- dict_fix6

# ============================================================================
# SAVE UPDATED DICTIONARY
# ============================================================================

cat("Saving updated dictionary...\n")

# Backup original
file.copy("data_dictionary_enhanced.csv",
          "data_dictionary_enhanced_BACKUP.csv",
          overwrite = TRUE)

# Write updated dictionary
write_csv(dict_final, "data_dictionary_enhanced.csv")

cat("\nDONE! Dictionary updated successfully.\n")
cat("Backup saved as: data_dictionary_enhanced_BACKUP.csv\n\n")

# ============================================================================
# SUMMARY
# ============================================================================

cat("=== SUMMARY OF CHANGES ===\n\n")

cat("✓ FIX 1: DSST standardized score now assigned to DSST instrument\n")
cat("✓ FIX 2: WHO-5 total score now assigned to WHO-5 instrument\n")
cat("✓ FIX 3: SPPB components (2 fields) changed from medical to physical\n")
cat("✓ FIX 4: Gait Speed fields (6 fields) changed to physical category\n")
cat("✓ FIX 5: Grip Strength muscle weakness changed from demographic to physical\n")
cat("✓ FIX 6: Created Verbal Fluency instrument (4 fields total)\n")
cat("         - VF phonemic & semantic total scores\n")
cat("         - VF phonemic & semantic standardized scores\n\n")

cat("Total fixes applied: 14 fields\n")
cat("New instruments created: Verbal Fluency\n")
