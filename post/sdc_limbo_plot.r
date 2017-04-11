load(file='sdc.summary.rdata')

str_labels <- c("0.01", NULL,"0.05", NULL, "0.1", NULL, "0.2", NULL, "0.5", NULL, "1", NULL, "2", NULL, "5")
str_legend <- c("LM 5","LM 10","LM 20","LM 50","LM 100","LM 200")
str_legend_title <- "Added Latency"


v <- sdc.summary[,6]

p <- get_fp_plot(v, files, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5"), f_mean = median)

pdf(file="plot_sdc_limbo.pdf", width = 2/3 * 11.69, height = 2/3 * 8.27)
  matplot(p, type='b', lty = 1, ylim = c(0,2670), xaxt = 'n') 
  axis(1,at=1:8, labels=str_labels)
  legend("top", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title, horiz = F, ncol = 3) 
gbg <- dev.off()