# Description: Script to run natural selection annotations through LDSC

# Load packages -----------------------------------------------------------

library(LDSCforRyten)
library(here)
library(tidyverse)
library(stringr)

# Main --------------------------------------------------------------------

file_paths <- 
  list.files(
    path = 
      here::here(
        "raw_data", "01_annotations"
      ),
    pattern = ".results",
    recursive = T,
    full.names = T
  )

results <-
  LDSCforRyten::Assimilate_H2_results(
    path_to_results = file_paths
  ) %>% 
  LDSCforRyten::Calculate_enrichment_SE_and_logP(
    ., one_sided = "+"
  ) %>% 
  tidyr::separate(
    annot_name, 
    into = c("cutoff", "selection_metrics"), sep = ":"
  ) %>% 
  dplyr::mutate(
    cutoff = 
      str_c("Top ", cutoff, "%")
  ) %>% 
  dplyr::select(GWAS, cutoff, selection_metrics, everything())

# Save files --------------------------------------------------------------

write_delim(
  results, 
  path = here::here("results", "01_annotations", "ldsc_summary.txt"),
  delim = "\t"
)  