# Description: Script to format ALS summary statistics and pass them through munge_sumstats.py

# Load packages -----------------------------------------------------------

library(data.table)
library(tidyverse)

# Set arguments -----------------------------------------------------------

gwas_dir <- 
  file.path("/data", "LDScore", "GWAS", "ALS2021")

# Load data ---------------------------------------------------------------

als <- 
  data.table::fread(
    file.path(gwas_dir, "ALS_sumstats_EUR_only.txt.gz")
    )

# Main --------------------------------------------------------------------

als <- 
  als %>% 
  dplyr::select(
    ID, contains("Allele"), Freq1, Effect, StdErr, `P-value`, N_effective
  )

# Save data ---------------------------------------------------------------
data.table::fwrite(
  als, 
  sep = "\t",
  file.path(gwas_dir, "ALS_sumstats_EUR_only.txt")
)

print(Sys.time())
print("Done running Rscript...")
