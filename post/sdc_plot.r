source("fitting.r")
source('counting.r')
source("rerval.r")
source("plot_sdc.r")

plot_in_pdf <- FALSE

#load(file="sdc_with_close_up_results.rdata")
load(file="sdc_with_close_up_results_extra_lm200.rdata")
#load(file="sdc_results_all_nodes_to_5.rdata")

res <- counting_vall(v_l = tbl, files = files, f_count = alt2_counting_all, wt_a0 = 0.0001)

# This gives three variables, tbl, res, and files
str_labels <- c("0.01", NULL,"0.05", NULL, "0.1", NULL, "0.2", NULL, "0.5", NULL, "1", NULL, "2", NULL, "5")
str_legend <- c("LM 5","LM 10","LM 20","LM 50","LM 100","LM 200")
str_legend_title <- "Added Latency"

f <- median

if(plot_in_pdf) {
  par(mfrow = c(1,1))
} else {
  par(mfrow = c(2,3))
}
if(plot_in_pdf) {
  pdf(file="plot_sdc_ratio_op_a0.pdf")
}
p <- get_fp_plot(get_ratios(res, row=1), files, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5"),f_mean = f)
matplot(p, type='b', lty = 1, xlab='wt', ylab='Prob.', xaxt = 'n')
axis(1,at=1:8, labels=str_labels)
legend("bottomleft", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
if(plot_in_pdf) {
  gbg <- dev.off()
}

if(plot_in_pdf)pdf(file="plot_sdc_ratio_op_a1.pdf")
  p <- get_fp_plot(get_ratios(res, row=2), files, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5"),f_mean = f)
  matplot(p, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n')
  axis(1,at=1:8, labels=str_labels)
  legend("topleft", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
if(plot_in_pdf)gbg <- dev.off()

if(plot_in_pdf)pdf(file="plot_sdc_ratio_op_a2.pdf")
  p <- get_fp_plot(get_ratios(res, row=3), files, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5"),f_mean = f)
  matplot(p, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n')
  axis(1,at=1:8, labels=str_labels)
  legend("topright", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
if(plot_in_pdf)gbg <- dev.off()

if(plot_in_pdf)pdf(file="plot_sdc_ratio_op_a3.pdf")
  p <- get_fp_plot(get_ratios(res, row=4), files, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5"),f_mean = f)
  matplot(p, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n')
  axis(1,at=1:8, labels=str_labels)
  legend("topright", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
if(plot_in_pdf)gbg <- dev.off()

if(plot_in_pdf) pdf(file="plot_sdc_rer_agressivity.pdf")
  val <- sapply(1:ncol(tbl), function(i) sum(tbl[,i]$count[1:1000,7]))
  p <- get_fp_plot(val,files, f_mean = f, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5") )
  matplot(p, type='b', lty=1, log='', xlab='Waiting Times', ylab='Count Ops', xaxt = 'n')
  axis(1,at=1:8, labels=str_labels)
  legend("topright", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
if(plot_in_pdf) gbg <- dev.off()
  
if(plot_in_pdf) pdf(file="plot_sdc_rer_agressivity_zoomed.pdf")
  val <- sapply(1:ncol(tbl), function(i) sum(tbl[,i]$count[1:1000,7]))
  p <- get_fp_plot(val,files, f_mean = f, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5") )
  matplot(p[,1:4], type='b', lty=1, log='', xlab='Waiting Times', ylab='Count Ops', xaxt = 'n')
  axis(1,at=1:8, labels=str_labels)
  legend("topright", legend = str_legend[1:4], lty = 1, col = 1:4, title = str_legend_title)
if(plot_in_pdf) gbg <- dev.off()

load(file="p.sim_median.rdata")
if(plot_in_pdf) pdf(file="plot_sdc_rer_simulation_of_A2.pdf")
  # p.sim.med its the result of a get_fp_plot like function. The file stable_sim.r
  matplot(p.sim.med, type='b', lty = 1, xlab = 'Waiting Times', xaxt = 'n', ylab = 'Prob. FP')
  axis(1,at=1:8, labels=str_labels)
  legend("topright", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
if(plot_in_pdf) gbg <- dev.off()