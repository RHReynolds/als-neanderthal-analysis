# Description: Script to create natural selection annotations for LDSC

# Load packages -----------------------------------------------------------

library(doParallel)
library(foreach)
library(here)
library(LDSCforRyten)
library(tidyverse)
library(stringr)
library(qdapTools)

# Set arguments -----------------------------------------------------------

args <-
  list(
    cores = 10,
    file_dir = here::here("raw_data", "01_annotations", "positive_selection"),
    top_percent = 
      setNames(
        object = c(2,1,0.5),
        nm = str_c("top_", c(2,1,0.5))
      ),
    baseline_model = "97",
    annot_dir = here::here("raw_data", "01_annotations", "ldsc_annotations")
  )

print(args)

# Set up parallelisation --------------------------------------------------

cl <- parallel::makeCluster(args$cores)
doParallel::registerDoParallel(cl)

# Load data ---------------------------------------------------------------

# Loading baseline
BM <- LDSCforRyten::creating_baseline_df(baseline_model = args$baseline_model)

# Load metrics
metric_df <- 
  list.files(
    path = args$file_dir,
    pattern = "\\.annot",
    full.names = T
  ) %>% 
  lapply(
    ., 
    readr::read_table
  ) %>% 
  qdapTools::list_df2df(col1 = "list_name") %>% 
  dplyr::select(-list_name) %>% 
  tidyr::pivot_longer(
    cols = IHS:LA,
    names_to = "selection_metric",
    values_to = "value"
  )

# Main --------------------------------------------------------------------

# Create df with top 2%, 1% and 0.05% of SNPs
# Keep tied scores even if this means slightly more SNPs included 
# (as no way of distinguishing between tied SNPs)
metric_top_df <- 
  args$top_percent %>% 
  lapply(., function(percent){
    
    metric_df %>% 
      dplyr::group_by(selection_metric) %>% 
      dplyr::slice_max(
        prop = percent/100, 
        order_by = value,
        with_ties = TRUE
      )
    
  }) %>% 
  qdapTools::list_df2df(col1 = "cutoff") %>%
  dplyr::mutate(
    joint_name = str_c(cutoff, selection_metric, sep = ":")
  ) 

# Create list with all annotations
ldsc_list <- 
  setNames(
    object = 
      metric_top_df %>%
      dplyr::select(
        joint_name, everything(), -selection_metric, -cutoff
      ) %>% 
      dplyr::group_split(joint_name),
    nm = 
      metric_top_df$joint_name %>% 
      unique() %>% 
      sort()
  )
  
# As natural selection metrics were annotated to LDSC baseline model
# can simply use a left join and make values binary
ldsc_bm_list <-
  foreach::foreach(
    i = 1:length(ldsc_list),
    .verbose = TRUE, 
    .packages = c("LDSCforRyten", "tidyverse", "stringr")
  ) %dopar% {
    
    # Important that left-joined to BM to maintain order of SNPs
    BM %>% 
      dplyr::left_join(
        ldsc_list[[i]],
        by = c("CHR", "BP", "SNP", "CM")
      ) %>% 
      dplyr::mutate(
        Binary = 
          case_when(is.na(value) ~ 0,
                    TRUE ~ 1)
      ) %>% 
      dplyr::select(
        CHR, BP, SNP, CM, Binary
      )
    
  }

names(ldsc_bm_list) <- names(ldsc_list)

# Close parallel connections ----------------------------------------------

parallel::stopCluster(cl)

# Save files --------------------------------------------------------------

# Save annot files
dir.create(args$annot_dir, showWarnings = T)
LDSCforRyten::create_annot_file_and_export(ldsc_bm_list, annot_basedir = args$annot_dir)

# Save top metric dataframe
saveRDS(
  metric_top_df,
  here::here("raw_data", "01_annotations", "positive_selection_top_n.rds")
  )

print(Sys.time())
print("Done!")