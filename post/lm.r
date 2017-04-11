source("fitting.r")
source("rerval.r")
source("counting.r")

# Needed for the rmse
library(hydroGOF)
library(actuar)
library(parallel)

generate_rdata <- function(files){
#files <- get_filenames(pattern = "fitv2_")
  sapply(2:5, function(i) {
    tbl <- get_vfitting(files, id_snd=1, id_rcv=i)
    save(tbl, files, file=sprintf("lm_sdc_as_n1-n%d.rdata", i))
    print('.')
    return (tbl)
  }) -> ret_val
}

load.rdata <- function(v_files) {
  sapply(v_files, function(i) {
    a <- new.env()
    load(envir=a, file = i)
    return (a)
  })
}
# in step, i'm not checking the modulus. so be careful.
proces <- function(e, step = 200) {
  sapply(1:ncol(e$tbl), function(i) {
    m <- e$tbl[,i]$ts
    sapply(1:(nrow(m)/step), function(j){
      mm <- m[( step*(j-1)+1):(step*j), ]
      v <- mm[,3] - mm[,2]
      count_na <- sum(is.na(v))
      # without na's
      v.mean <- mean(v[which(is.na(v) == FALSE)])
      
      # without na's
      count_neg <- sum(v[which(is.na(v) == FALSE)] < 0)
      
      return(c(v.mean, count_na, count_neg))
    })    
  })-> ret_val  
  return(ret_val)
}

# returns the best option (or NA) for each colum/file
choose <- function(m){
  apply(m, 2, function(col){
    ids <- 3*((1:(length(col)/3))-1)
    v <- col[ids+1]
    count_na <- col[ids+2]
    count_neg <- col[ids+3]
    
    ids <- which(count_neg == 0)
    if (length(ids) == 0) return(c(NA, 0))
  
    ids <- which(min(v[ids]) == v[ids])
    
    if (length(ids) == 0) return(c(NA, 0))
    
    val <- max(v[ids])
    return (c(val, which(v == val)))  
  })
}

check_rmse <- function(e, choosen, step = 200){
  sapply(1:ncol(choosen), function(i){
    m <- e$tbl[,i]$ts
    if (choosen[2,i] == 0) return(NA)
    ids <- ((step*(choosen[2,i] - 1))+1):(step*choosen[2,i])
    
    v.obs <- m[ids,3] - m[ids,2]
    v.obs <- v.obs[which(is.na(v.obs) == FALSE)] # remove NA's
    v.sim <- rexp(length(v.obs), rate=1/choosen[1,i])
    return(rmse(v.sim, v.obs))
  })
}


find_best_option <- function(v_env, ...) {
  sapply(1:length(v_env), function(i){
    val <- proces(e = v_env[[i]], ...)
    choosen <- choose(val)
    res <- check_rmse(v_env[[i]], choosen, ...)
    #dat <- rbind(choosen, res)
    return(list(rmse=res, mean=choosen[1,], id=choosen[2,]))
  }) -> dat

  return(dat)
}

run <- function(v_env, files, ...) {
  t0 <- as.numeric(Sys.time())
  
  dat <- find_best_option(v_env)
  dat.rmse <- sapply(1:length(dat[1,]), function(i) dat[,i]$rmse)
  
  apply(dat.rmse, 1, function(row) {
    vals <- row[which(is.na(row) == FALSE)]
    ret <- ifelse(length(vals) == 0, NA, min(vals))
    return(ret)
  }) -> v
  
  print(length(files))
  #sapply(1:length(files), function(i){
  mclapply(mc.cores = 8, X = 1:length(files), function(i){
    t1 <- as.numeric(Sys.time())
    if (is.na(v[i]) == FALSE){
      item <- which(v[i] == dat.rmse)
      item.col <- trunc(item / nrow(dat.rmse)) + 1
      
      # Simulation of FP 
      fp.sim <- run_sim_fp(lambda = 1/(dat[, item.col]$mean[i]/1000), wt = files , ...)
      
      # Count FP from tbl
      fp.obs <- run_obs_fp(ts = v_env[[item.col]]$tbl[,i]$ts, wt = files[i])
      
      v_res <- c(fp.sim, fp.obs)
    } else{
      v_res <- c(NA, NA)
    }

    printf("%d) %f\n", i, as.numeric(Sys.time()) - t1)
    return(v_res)
  }) -> res
  
  l <- list(res = res, fbo = dat, files = files )
  
  printf("TOTAL) %f\n", as.numeric(Sys.time()) - t0)  
  return (l)
}

# I prefer the ... option, but this seems easier?
run_sim_fp <- function(n_iter = 2, wt, lambda, rate_op = 50, window_op = 1000, wt_c2 = 2*qexp(p=0.7, rate=1/lambda), f_aggregate=median) {
  if(is.numeric(wt) == FALSE) wt <-as.numeric(strsplit(x = strsplit(x = wt, split = "-wt_")[[1]][2], split = '-')[[1]][1])
  
  r_data <- replicate(n=n_iter, expr = process_scenario(get_scenario(c1_dt = wt, c2_dt = wt_c2, len_lambda = lambda, window_op = window_op, rate_op = rate_op, p_rpareto = 0), f_dc_er=matrix_causal_delivery_time_bt_with_error_recovery, f_dnc=matrix_delivery_time))
  v <- apply(r_data, 2, function(mi) mean(mi$dc_er$log$fp))
  
  return (f_aggregate(v))
}

run_obs_fp <- function(ts, wt, f_count = alt2_counting_all) {
  fp <- get_ratios(f_count(ts, wt), row = 3)
  return (fp)
}