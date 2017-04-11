library(ggplot2)
source("~/Documents/rerval/post/rerval.r")

path <- "~/Documents/rerval/stable_data/"
############
v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.01-wt_0.01-ro_10-*")
v.wt0.01 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.01-wt_0.1-ro_10-*")
v.wt0.1 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.01-wt_1-ro_10-*")
v.wt1 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

m.0.01 <- cbind(v.wt1, v.wt0.1, v.wt0.01)
m.0.01.mean <- apply(m.0.01, 2, mean)
m.0.01.sd <- apply(m.0.01, 2, sd)


#####
v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.005-wt_0.01-ro_10-*")
v.wt0.01 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.005-wt_0.1-ro_10-*")
v.wt0.1 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.005-wt_1-ro_10-*")
v.wt1 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

m.0.005 <- cbind(v.wt1, v.wt0.1, v.wt0.01)
m.0.005.mean <- apply(m.0.005, 2, mean)
m.0.005.sd <- apply(m.0.005, 2, sd)

#####
v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.00-wt_0.01-ro_10-*")
v.wt0.01 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.00-wt_0.1-ro_10-*")
v.wt0.1 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

v_fnn <- get_filenames(dir=path, pattern="mdc-loss_0.00-wt_1-ro_10-*")
v.wt1 <- get_summary.mean(get_summary(v_fnn))[c(7,13),6]

m.0.00 <- cbind(v.wt1, v.wt0.1, v.wt0.01)
m.0.00.mean <- apply(m.0.00, 2, mean)
m.0.00.sd <- apply(m.0.00, 2, sd)

####


m.mean <- cbind(m.0.00.mean, m.0.005.mean, m.0.01.mean)
m.sd <- cbind(m.0.00.sd, m.0.005.sd, m.0.01.sd)


matplot(m.mean, type='b', lty=1, ylab="#Delayed Operations", xaxt="n", xlab="Different Waiting Times (wt) ")
axis(1,at=1:3, labels=c("wt 1", NULL, "wt 0.1", NULL, "wt 0.01", NULL))
legend("topright", legend = c("0.00%","0.005%","0.01%"), lty = 1, col = 1:3, title = "Prob Message Loss")
