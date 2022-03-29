library(tidyverse)
library(readxl)

Neanderthal <- read_excel(als-neanderthal-analysis/results/01_annotations/Supplementary_Table2.xlsx)

order_metric <- c("LA", "CLR", "CMS", "IHS", "XPEHH")

Neanderthal_sig <- Neanderthal %>% mutate(FDR_Pvalue = ifelse(FDR_P<0.05, "FDR p-value < 0.05", "Not significant, FDR p-value >=0.05")) %>%
  mutate(selection_metrics = selection_metrics %>% factor() %>% fct_relevel(order_metric))

Coefficient_plot <- Neanderthal_sig%>% 
  ggplot(aes(x = selection_metrics,y = Coefficient))+
  geom_col(aes(fill = FDR_Pvalue), colour = "black") +
  scale_fill_manual(values = c("#DC0000B2", "grey93"), labels = c("FDR p-value <0.05", expression("Not significant, FDR p-value">=0.05))) +
  geom_errorbar(aes(ymin = Coefficient.Lower.SE,ymax = Coefficient.Upper.SE, width = 0.2)) +
  facet_grid(facets = GWAS ~ cutoff, scales = "free")  +
  labs(x = "Selection metric", y = expression("Coefficient,"~tau*"c"), fill = "", title = "") +
  theme_bw()+ theme(legend.position="bottom")
