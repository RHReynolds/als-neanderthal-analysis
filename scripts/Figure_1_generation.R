# Description: Script to generate figure summarising coefficient p-values from stratified-LD score regression (Figure 1)

# Load packages -----------------------------------------------------------

library(here)
library(tidyverse)
library(readxl)

# Set arguments --------------------------------------------------------

args <- 
  list(
    results_dir = here::here("results", "01_annotations")
  )
  

# Load files -----------------------------------------------------------

Neanderthal <- 
  read_excel(
    file.path(args$results_dir, "Supplementary_Table2.xlsx"),
    sheet = "results"
  )

# Main -----------------------------------------------------------

order_metric <- c("LA", "CLR", "CMS", "IHS", "XPEEH")

Neanderthal_sig <- 
  Neanderthal %>% 
  mutate(
    FDR_Pvalue = 
      ifelse(
        z_score_fdr < 0.05, 
        "FDR p-value < 0.05", 
        "Not significant, FDR p-value >=0.05"
        ),
    Coefficient.Lower.SE = coefficient - coefficient_std_error,
    Coefficient.Upper.SE = coefficient + coefficient_std_error,
    selection_metrics = 
      selection_metrics %>% 
      factor() %>% 
      fct_relevel(order_metric)
    )

Coefficient_plot <- 
  Neanderthal_sig %>% 
  ggplot(
    aes(
      x = selection_metrics,
      y = coefficient)
    ) +
  geom_col(
    aes(fill = FDR_Pvalue), 
    colour = "black"
    ) +
  scale_fill_manual(
    values = c("#DC0000B2", "grey93"), 
    labels = c("FDR p-value <0.05", expression("Not significant, FDR p-value">=0.05))
    ) +
  geom_errorbar(
    aes(
      ymin = Coefficient.Lower.SE,
      ymax = Coefficient.Upper.SE, 
      width = 0.2)
    ) +
  facet_grid(facets = gwas ~ cutoff, scales = "free")  +
  labs(
    x = "Selection metric", 
    y = expression("Coefficient,"~tau*"c"), 
    fill = "", 
    title = ""
    ) +
  theme_bw() + 
  theme(legend.position = "bottom")

# Save files --------------------------------------------------------------

ggsave(
  "figure1.png", 
  Coefficient_plot, 
  device = "png", 
  path = args$results_dir,
  width = 150,  
  height = 150,
  units = "mm",
  dpi = 300,
  limitsize = TRUE
)
