load("p.sim.med.rdata")


str_labels <- c("0.01", NULL,"0.05", NULL, "0.1", NULL, "0.2", NULL, "0.5", NULL, "1", NULL, "2", NULL, "5")
str_legend <- c("LM 5","LM 10","LM 20","LM 50","LM 100","LM 200")
str_legend_title <- "Added Latency"

par(mfrow=c(1,1))

pdf(file="plot_sdc_rer_simulation_of_A2.pdf")
  matplot(p.sim.med/5, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n')
  axis(1,at=1:8, labels=str_labels)
  legend("topright", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
gbg <- dev.off()