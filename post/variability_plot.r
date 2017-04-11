load("p.list.rdata")

vm.lm <- c(p.list[,1],NA,p.list[,2],NA,p.list[,3],NA,p.list[,4],NA,p.list[,5],NA,p.list[,6])



ids_labels <- c(rep(1,8), as.numeric(sapply(2:6, function(i) c("",rep(i,8)))))
str_labels <- c("LM 5", "LM 10", "LM 20", "LM 50", "LM 100", "LM 200")
str_nums <- c("5", "10", "20", "50", "100", "200")

string.1 <- c(rep("",3), rep(str_nums[1],2), rep("",3))
string.o <- sapply(2:6, function(i) c(rep("",3), rep(str_nums[i],2), rep("",4)))
### Let the plot begin

pdf(file = "boxplot_variability_mean.pdf", width = 1.2*11.69, height = 8.27)
  boxplot(vm.lm, col=2:10, xaxt='n', xlab="LM Grouped", ylab="Latency")
  #axis(1,at = 1:(8*6 +5), labels=str_labels[ids_labels])
  axis(1,at = 1:(8*6 +5), labels=c(string.1,string.o))
  legend("topleft", legend = c("0.01","0.05","0.1","0.2","0.5","1","2","5"), title = "wt", ncol=8, lty = 0, pch = 15, col = 2:10)
gbg <- dev.off()
