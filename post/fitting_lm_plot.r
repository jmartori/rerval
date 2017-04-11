load("fitting_lm.rdata")


par(mfrow = c(1,1))
pdf(file = "plot_fitting_lm.pdf")
  # v.obs, v.sim, 
  m <- cbind(sort(v.obs), sort(v.sim))
  matplot(m, type='l', lty = 1, lwd = 2, col = 1:2, ylab = "Latency", xlab = "Observations")
  legend('top', ncol = 2, legend = c("Observed", "Simulated"), lty = 1, col = 1:2)
gbg <- dev.off()