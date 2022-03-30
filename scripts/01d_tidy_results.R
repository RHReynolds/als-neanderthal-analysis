# Description: Script to tidy results and generate supplementary table

# Load packages -----------------------------------------------------------

library(LDSCforRyten)
library(here)
library(janitor)
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

results_w_baseline  <- 
  file_paths %>% 
  lapply(., function(file){
    
    file_name <- file
    
    GWAS <- 
      file_name %>% 
      stringr::str_replace("/.*/", "") %>% 
      stringr::str_replace("\\.results", "") %>% 
      stringr::str_replace("_.*", "")
    
    annot_name <- 
      file_name %>% 
      stringr::str_replace("/.*/", "") %>% 
      stringr::str_replace("\\.results", "") %>% 
      stringr::str_replace(".*_", "")
    
    readr::read_delim(file = file_name, delim = "\t") %>% 
      dplyr::mutate(
        annot_name = annot_name, 
        GWAS = GWAS
      ) %>% 
      LDSCforRyten::Calculate_enrichment_SE_and_logP(
        ., one_sided = NULL
      ) %>% 
      tidyr::separate(
        annot_name, 
        into = c("cutoff", "selection_metrics"), sep = ":"
      ) %>% 
      dplyr::mutate(
        cutoff = 
          str_c("Top ", cutoff, "%")
      ) %>% 
      dplyr::select(
        GWAS, cutoff, selection_metrics, everything()
      ) 
    
  }) %>% 
  qdapTools::list_df2df() %>% 
  tibble::as_tibble() %>% 
  dplyr::select(-X1) %>% 
  # fix typo in XPEEH
  dplyr::mutate(
    selection_metrics =
      case_when(
        selection_metrics == "XPEEH" ~ "XPEHH",
        TRUE ~ selection_metrics
      )
  )

results <-
  results_w_baseline %>% 
  dplyr::filter(Category == "L2_0") %>% 
  dplyr::select(-Category)

# Supp table --------------------------------------------------------------

xlsx <- 
  setNames(
    vector(mode = "list", length = 2),
    c("column_descriptions", "results")
  )

xlsx[[2]] <-
  results %>% 
  dplyr::group_by(GWAS) %>%
  dplyr::mutate(
    z_score_fdr = 
      p.adjust(
        p = Z_score_P, 
        method = "fdr"
      )
  ) %>% 
  janitor::clean_names() %>% 
  dplyr::select(
    -contains("_se"), -log_p, -z_score_log_p
  )

xlsx[[1]] <-
  tibble(
    `Column name` = colnames(xlsx[[2]]),
    Description = c(
      "GWAS",
      "The percentile of the natural selection metric",
      "The natural selection metric",
      "Proportion of SNPs accounted for by the annotation within the baseline set of SNPs",
      "Proportion of heritability accounted for by the annotation",
      "Jackknife standard errors for the proportion of heritability. Block jacknife over SNPs with 200 equally sized blocks of adjacent SNPs.",
      "Enrichment = (Proportion of heritability)/(Proportion of SNPs)",
      "Standard error of enrichment",
      "P-value of total enrichment",
      "Regression co-efficient i.e. contribution of annotation after controlling for all other categories in the model",
      "Standard error of coefficient. Estimated using the covariance matrix for coefficient estimates.",
      "Z-score for significance of coefficient",
      "P-value for coefficient computed from z-score",
      "FDR-adjusted coefficient p-value (adjusted by number of percentiles and selection metrics)"
    )
  )

# Save files --------------------------------------------------------------

write_delim(
  results_w_baseline, 
  file = here::here("results", "01_annotations", "ldsc_summary_w_baseline_annot.txt"),
  delim = "\t"
)  

write_delim(
  results, 
  file = here::here("results", "01_annotations", "ldsc_summary.txt"),
  delim = "\t"
) 

openxlsx::write.xlsx(
  xlsx,
  file = here::here("results", "01_annotations", "Supplementary_Table2.xlsx"),
  row.names = FALSE,
  headerStyle = openxlsx::createStyle(textDecoration = "BOLD"),
  firstRow = TRUE,
  append = TRUE
)
