load(file = 'sdc.bytes.rdata')
load(file = 'sdc.tcp.bytes.rdata')
source("plot_sdc.r")

str_labels <- c("0.01", NULL,"0.05", NULL, "0.1", NULL, "0.2", NULL, "0.5", NULL, "1", NULL, "2", NULL, "5")
str_legend <- as.vector(as.matrix(c("LM 5", "LM 10","LM 20","LM 50","LM 100","LM 200", "TCP","UDP"), nrow=4,ncol=2, byrow = F))
str_legend_title <- "Added Latency"

# numbers from a rer_no_lm file.
# using grep ", length [0-9]*)" mon_client_1.log | awk -F"length" '{print $2}' | awk -F")" '{print $1}' | sed 's/ //g' > udp.bytes
# and then mean  of udp.bytes and length for the n_lines
v.udp <- 174*5000*5 / 1024
v.tcp <- 5037163 / 1024 

v <- apply(sdc.bytes, 1, sum)/1024

p <- get_fp_plot(v, files, str_wt = c("0.01","0.05","0.1","0.2","0.5","1","2","5"), f_mean = median)

#par(mfrow = c(1,1))
#pdf(file="plot_sdc_bytes.pdf", width = 2/3 * 11.69, height = 2/3 * 8.27)
  matplot(p, type='b', lty = 1,xaxt = 'n', xlab = "Waiting Time", ylab = "kilobytes", ylim = c(3000, 22500))
  axis(1,at=1:8, labels=str_labels)
  legend("top", str_legend, lty = c(rep.int(1,6), 2, 2), col = c(1:6, "red", "darkgreen"), title = str_legend_title, horiz = F, ncol = 4)
  abline(h=v.tcp, lty = 2, col = "red")
  abline(h=v.udp, lty = 2, col = "darkgreen")
#gbg <- dev.off()

  
par(mfrow = c(1,1))
pdf(file="plot_sdc_bytes_zoom.pdf", width = 2/3 * 11.69, height = 2/3 * 8.27)
  matplot(p[,1:4], type='b', lty = 1,xaxt = 'n', xlab = "Waiting Time", ylab = "kilobytes", ylim = c(4200, 7250))
  axis(1,at=1:8, labels=str_labels)
  legend("top", str_legend[c(1:4,5:6)], lty = c(rep.int(1,4), 2, 2), col = c(1:4, "red", "darkgreen"), title = str_legend_title, horiz = F, ncol = 3)
  abline(h=v.tcp, lty = 2, col = "red")
  abline(h=v.udp, lty = 2, col = "darkgreen")
gbg <- dev.off()
  
  #abline(h=mean(p[,1]), lty = 1, col = 1)
  #abline(h=mean(p[,2]), lty = 1, col = 2)
  #abline(h=mean(p[,3]), lty = 1, col = 3)
  
  