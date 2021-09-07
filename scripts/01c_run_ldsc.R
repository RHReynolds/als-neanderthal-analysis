# Description: Script to run natural selection annotations through LDSC

# Load packages -----------------------------------------------------------

library(doParallel)
library(foreach)
library(LDSCforRyten)
library(here)
library(tidyverse)
library(stringr)

# Set arguments -----------------------------------------------------------

here::i_am("scripts/01c_run_ldsc.R")

args <-
  list(
    python_command = "/usr/bin/python2.7",
    annot_basedir = here::here("raw_data", "01_annotations/"),
    annot_name = "ldsc_annotations",
    annot_subcategories = 
      list.dirs(
        path = file.path(here::here("raw_data", "01_annotations", "ldsc_annotations"))
        ) %>% 
      basename(),
    baseline_model = "97",
    gwas_df = 
      LDSCforRyten::Create_GWAS_df() %>% 
      dplyr::filter(Original.name %in% c("AD2019", "ALS2021.EUR", "PD2019.meta5.ex23andMe"))
  )

# Remove annot_name from annot_subcategories
args$annot_subcategories <- 
  args$annot_subcategories[!str_detect(args$annot_subcategories, args$annot_name)]

print(args)

# Main --------------------------------------------------------------------

print(Sys.time())
print("Start running LDSC...")

fixed_args <- 
 get_LDSC_fixed_args(Baseline_model = args$baseline_model)

Calculate_LDscore(
  Command = args$python_command,
  Annotation_Basedir = args$annot_basedir,
  Annot_name = args$annot_name,
  Annotation_Subcategories = args$annot_subcategories,
  Fixed_Arguments = fixed_args,
  cores = 2
)

Calculate_H2(
  Command = args$python_command,
  Annotation_Basedir = args$annot_basedir,
  Annot_name = args$annot_name,
  Annotation_Subcategories = args$annot_subcategories,
  Fixed_Arguments = fixed_args,
  GWAS_df = args$gwas_df,
  cores = 8
)

print(Sys.time())
print("Done!")