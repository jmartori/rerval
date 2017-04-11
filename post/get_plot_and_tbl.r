source("~/Documents/rerval/post/rerval.r")
source("~/Documents/rerval/post/plot_sdc.r")

#v_fn <- get_filenames(pattern = "*lm_exp*")
#tbl <- get_all(v_fn)

str_loss  <- c("5-","10-","20-","50-","100-","200-")
str_wt <- c("0.01-","0.1-","1-","2-","5-")

tbl_plot <- sapply(1:13, function(i) get_tbl_plot(tbl, col = i, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean)

a1 <- get_tbl_plot(tbl, col =  9, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean
a2 <- get_tbl_plot(tbl, col = 10, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean
a3 <- get_tbl_plot(tbl, col = 11, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean
snd <- get_tbl_plot(tbl, col = 2, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean

by <- get_tbl_plot(tbl, col = 13, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean
dt <- get_tbl_plot(tbl, col = 12, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean

limbo <- get_tbl_plot(tbl, col = 8, str_head_loss = "-lm_exp", str_loss = str_loss, str_wt=c("0.01","0.1","1","2","5"))$mean

pdf("~/rer_a.pdf")
  #par(mfrow=c(1,3))
	matplot(a1/snd, lty = 1, type='b')
	matplot(a2/snd, lty = 1, type='b')
	matplot(a3/snd, lty = 1, type='b')
gbg <- dev.off()


pdf("~/limbo.pdf")
  #par(mfrow=c(1,2))
	matplot(limbo, lty = 1, type='b')
	matplot(by/dt, lty = 1, type='b')
gbg <- dev.off()

save(tbl, tbl_plot, a1,a2,a3,snd,by,dt,limbo, file="sdc_exp_lm_wt.rdata")
