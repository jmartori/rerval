source("./R/utils.r")

#udp.c1 <- load.log("./data/100ops/udp/client_1.log")
#udp.5p.c2 <- load.log("./data/10ops/udp_5p/client_2.log")
#udp.1p.c2 <- load.log("./data/10ops/udp_1p/client_2.log")
#udp.0p.c2 <- load.log("./data/10ops/udp_0p/client_2.log")

udp.1p.wt1.c2 <- load.log("./data/100ops_wt1/udp_1p/client_2.log")
udp.1p.wt01.c2 <- load.log("./data/100ops_wt01/udp_1p/client_2.log")
udp.1p.wt001.c2 <- load.log("./data/100ops_wt001/udp_1p/client_2.log")

#tcp.c1 <- load.log("./data/100ops/tcp/client_1.log")
# wt doesnt matter for tcp.
tcp.c2 <- load.log("./data/100ops_wt1/tcp/client_2.log")

v.tcp <- tcp.c2$dv_time[tcp.c2$l_d_ids_by_node$ids.1] - tcp.c2$dv_time[tcp.c2$l_d_ids_by_node$ids.1[1]]
v.1p.wt1 <- udp.1p.wt1.c2$dv_time[udp.1p.wt1.c2$l_d_ids_by_node$ids.1] - udp.1p.wt1.c2$dv_time[udp.1p.wt1.c2$l_d_ids_by_node$ids.1[1]]
v.1p.wt01 <- udp.1p.wt01.c2$dv_time[udp.1p.wt01.c2$l_d_ids_by_node$ids.1] - udp.1p.wt01.c2$dv_time[udp.1p.wt01.c2$l_d_ids_by_node$ids.1[1]]
v.1p.wt001 <- udp.1p.wt001.c2$dv_time[udp.1p.wt001.c2$l_d_ids_by_node$ids.1] - udp.1p.wt001.c2$dv_time[udp.1p.wt001.c2$l_d_ids_by_node$ids.1[1]]

matplot(cbind(v.1p.wt1,v.1p.wt01,v.1p.wt001, v.tcp), type='l', lty=1, xlab = "Time", ylab='Time')
