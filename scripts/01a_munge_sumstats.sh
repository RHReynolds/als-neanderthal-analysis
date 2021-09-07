# Description: Script to munge ALS summary statistics

#!/usr/bin/env bash

# Set arguments -----------------------------------------------------------

python_v2_7="/usr/bin/python2.7"
ldsc_dir="/tools/ldsc/"
gwas_dir="/data/LDScore/GWAS/ALS2021/"
gwas="ALS_sumstats_EUR_only.txt.gz"
rscript="/home/rreynolds/misc_projects/als-neanderthal-analysis/scripts/01a_munge_sumstats.R"
out_filename="ALS2021.EUR"

# Main --------------------------------------------------------------------

# Move to directory and run Rscript
cd $gwas_dir
echo "Running $rscript..."
Rscript $rscript

echo "Running ldsc..."
$python_v2_7 $ldsc_dir"munge_sumstats.py" \
--sumstats ${gwas/%.gz} \
--out $out_filename \
--merge-alleles /data/LDScore/Reference_Files/w_hm3.snplist \
--snp ID \
--N-col N_effective

# Remove gunzipped file
rm ${gwas/%.gz}
