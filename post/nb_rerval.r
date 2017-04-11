source("~/Documents/rerval/post/R/utils.r")

udp.1p.wt1.c2 <- load.log("~/Documents/rerval/post/data/mdc_n3/10ops_wt1/udp_1p/client_2.log")
udp.1p.wt01.c2 <- load.log("~/Documents/rerval/post/data/mdc_n3/10ops_wt01/udp_1p/client_2.log")
udp.1p.wt001.c2 <- load.log("~/Documents/rerval/post/data/mdc_n3/10ops_wt001/udp_1p/client_2.log")

# wt doesnt matter for tcp.
tcp.c2 <- load.log("~/Documents/rerval/post/data/mdc_n3/10ops_wt1/tcp/client_2.log")

v.tcp <- tcp.c2$dv_time[tcp.c2$l_d_ids_by_node$ids.1] - tcp.c2$dv_time[tcp.c2$l_d_ids_by_node$ids.1[1]]
v.1p.wt1 <- udp.1p.wt1.c2$dv_time[udp.1p.wt1.c2$l_d_ids_by_node$ids.1] - udp.1p.wt1.c2$dv_time[udp.1p.wt1.c2$l_d_ids_by_node$ids.1[1]]
v.1p.wt01 <- udp.1p.wt01.c2$dv_time[udp.1p.wt01.c2$l_d_ids_by_node$ids.1] - udp.1p.wt01.c2$dv_time[udp.1p.wt01.c2$l_d_ids_by_node$ids.1[1]]
v.1p.wt001 <- udp.1p.wt001.c2$dv_time[udp.1p.wt001.c2$l_d_ids_by_node$ids.1] - udp.1p.wt001.c2$dv_time[udp.1p.wt001.c2$l_d_ids_by_node$ids.1[1]]

par(mfrow = c(2,2))
len <- max(length(v.1p.wt1),length(v.1p.wt01),length(v.1p.wt001),length( v.tcp))
m <- cbind(v.1p.wt1[1:len],v.1p.wt01[1:len],v.1p.wt001[1:len], v.tcp[1:len])

matplot(m, type='l', lty=1, xlab = "Time", ylab='Time', main = "all")
plot(v.1p.wt1[1:len] - v.tcp[1:len], type='l', lty=1, xlab = "Time", ylab='Error', main = "wt1 vs tcp")
plot(v.1p.wt01[1:len] - v.tcp[1:len], type='l', lty=1, xlab = "Time", ylab='Error', main = "wt01 vs tcp")
plot(v.1p.wt001[1:len] - v.tcp[1:len], type='l', lty=1, xlab = "Time", ylab='Error', main = "wt001 vs tcp")

par(mfrow = c(1,1))