source("fitting.r")
source('counting.r')
source("rerval.r")
source("plot_sdc.r")

load('sdc_static.rdata')

str_labels <- c("0.01", NULL, "0.1", NULL, "1")
#str_legend <- c("LM 5","LM 10","LM 20","LM 50","LM 100","LM 200")
str_legend_title <- "Added Latency"

res <- counting_vall(v_l = tbl, files = files, f_count = alt2_counting_all, wt_a0 = 0.01)


par(mfrow = c(1,1))
pdf(file="plot_sdc_static_ratio_op_a0.pdf")
  p <- get_fp_plot(get_ratios(res, row=1), files, f_mean = median, str_loss = "0-", str_wt = c('0.01-', '0.1-','1-'))
  matplot(p, type='b', lty = 1, xlab='Waiting Time', ylab='Prob.', xaxt = 'n')#,  ylim = c(0.83,0.93))
  axis(1,at=1:3, labels=str_labels)
  #legend("bottomleft", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
gbg <- dev.off()


#pdf(file="plot_sdc_static_ratio_op_a1.pdf")
#  p <- get_fp_plot(get_ratios(res, row=2), files, f_mean = mean, str_loss = "0-", str_wt = c('0.01-', '0.1-','1-'))
#  matplot(p, type='b', lty = 1, xlab='Waiting Time', ylab='Prob.', xaxt = 'n',  ylim = c(0.07,0.17))
#  axis(1,at=1:3, labels=str_labels)
#  #legend("bottomleft", legend = str_legend, lty = 1, col = 1:6, title = str_legend_title)
#gbg <- dev.off()