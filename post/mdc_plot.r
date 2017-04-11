source("fitting.r")
source('counting.r')
source("rerval.r")
source("plot_sdc.r")

# escull quin vols o petara :) 
#stop("did you choose a load and comment me??")
#load(file="mdc_results.rdata")
#load(file="mdc_as_n1-n3.rdata")
#load(file="mdc_results_with_lm_500.rdata")

load("mdc_results_all_nodes.rdata")
# res commented because the all_nodes.rdata has the res computed from the res.1 + res.2 + ...
#res <- counting_vall(v_l = tbl, files = files, f_count = alt2_counting_all, wt_a0 = 0.001)

load("test.rdata")
##########


plot2pdf <- F
f_mean <- mean


# This gives three variables, tbl, res, and files
str_labels <- c("0.01", NULL,"0.05", NULL, "0.1", NULL, "0.2", NULL, "0.5", NULL, "1", NULL, "2", NULL, "5")
str_legend <- c("LM 5","LM 10","LM 20","LM 50","LM 100","LM 200")
str_legend_title <- "Added Latency"
str_loss <- c("5-","10-","20-","50-","100-","200-")

v_wt <- c(0.01,0.05,0.1,0.2,0.5,1,2,5)
str_wt <- paste(v_wt, "-", sep = '')

v_col <- c(1:6,8)

if (plot2pdf) {
  par(mfrow = c(1,1))
}else{
  par(mfrow = c(2,2))
}
if (plot2pdf) {
  pdf(file="plot_mdc_ratio_op_a0.pdf")
  }
  p0 <- get_fp_plot(get_ratios(res, row=1), files, str_wt = str_wt, str_loss = str_loss, f_mean = f_mean)
  #p <- get_fp_plot(get_ratios(res, row=1), files, f_mean = mean)
  matplot(p0, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n', col = v_col)#,  ylim = c(0,1))
  axis(1,at=1:length(str_labels), labels=str_labels)
  legend("bottomleft", legend = str_legend, lty = "99", col = v_col, title = str_legend_title, bty = 'n', pch = as.character(1:7))

if(plot2pdf) {
  gbg <- dev.off()
}

if (plot2pdf) {pdf(file="plot_mdc_ratio_op_a1.pdf")}
  p1 <- get_fp_plot(get_ratios(res, row=2), files, str_wt = str_wt, str_loss = str_loss, f_mean = f_mean)
  matplot(p1, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n', col = v_col)#,  ylim = c(0,1))
  axis(1,at=1:length(str_labels), labels=str_labels)
  legend("topleft", legend = str_legend, lty = "99", col = v_col, title = str_legend_title, bty = 'n', pch = as.character(1:7))
if (plot2pdf) {gbg <- dev.off()}

if (plot2pdf) {pdf(file="plot_mdc_ratio_op_a2.pdf")}
  p2 <- get_fp_plot(get_ratios(res, row=3), files, str_wt = str_wt, str_loss = str_loss, f_mean = f_mean)
  matplot(p2, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n', col = v_col)
  axis(1,at=1:length(str_labels), labels=str_labels)
  legend("topleft", legend = str_legend, lty = "99", col = v_col, title = str_legend_title, bty = 'n', pch = as.character(1:7))
if (plot2pdf) { gbg <- dev.off() }

if (plot2pdf){pdf(file="plot_mdc_ratio_op_a3.pdf")}
  p3 <- get_fp_plot(get_ratios(res, row=4), files, str_wt = str_wt, str_loss = str_loss, f_mean = f_mean)
  matplot(p3, type='b', lty = 1, xlab='Waiting Times', ylab='Prob.', xaxt = 'n', col = v_col)
  axis(1,at=1:length(str_labels), labels=str_labels)
  legend("topright", legend = str_legend, lty = "99", col = v_col, title = str_legend_title, bty = 'n', pch = as.character(1:7))
if (plot2pdf) {gbg <- dev.off()}

if (plot2pdf){ 
  #210 × 297 	8.3 × 11.7
  pdf(file="plot_mdc_rer_agressivity.pdf", height = 0.75 * 2/3 * 8.3, width = 0.75 * 4/3 * 11.7)
  
  val.1 <- 0
  val.2 <- 0
  val.3 <- 0
  val.4 <- 0
  
  val.1 <- sapply(1:ncol(tbl.1), function(i) sum(tbl.1[,i]$count[1:1000,7]))
  #val.2 <- sapply(1:ncol(tbl.1), function(i) sum(tbl.2[,i]$count[1:1000,7]))
  #val.3 <- sapply(1:ncol(tbl.1), function(i) sum(tbl.3[,i]$count[1:1000,7]))
  #val.4 <- sapply(1:ncol(tbl.1), function(i) sum(tbl.4[,i]$count[1:1000,7]))
  val <- val.1 + val.2 + val.3 + val.4 
  p <- get_fp_plot(v = val, files = files, f_mean = median, str_wt = str_wt, str_loss = str_loss)
  matplot(p, type='b', lty=1, log='', xlab='Waiting Times', ylab='Count Ops', xaxt = 'n', col = v_col)
  axis(1,at=1:length(str_labels), labels=str_labels)
  legend("topright", legend = str_legend, lty = "99", col = v_col, title = str_legend_title, bty = 'n', pch = as.character(1:7))
  
  # Zoomed
  #matplot(p[,1:4], type='b', lty=1, log='', xlab='Waiting Times', ylab='Count Ops', xaxt = 'n', col = v_col[1:4])
  #axis(1,at=1:length(str_labels), labels=str_labels)
  #legend("topright", legend = str_legend, lty = "99", col = v_col, title = str_legend_title, bty = 'n', pch = as.character(1:7))
  
  gbg <- dev.off()
}
  