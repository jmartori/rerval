source("~/Documents/rerval/post/R/utils.r")

concat <- function(v1, v2)
{
  return(paste(v1, v2, sep="/"))
}
list_pos <- function(v, n=1) lapply(v, '[[', n)



get_bandwidth <- function(tar_fn, dir = tempdir(), remote=FALSE){
	if (remote) cat(".")
  
  sapply(tar_fn, function(tfn){
    system(paste("tar -zxf ", tfn, " --directory ", dir ))
    if (remote) cat(".")
  
    mon_files <- c(list.files(path = dir, pattern = "mon_client_[0-9]*.log"))#, list.files(path = dir, pattern = "mon_server.log")) ## No mon_server yet
  
    sapply(mon_files, function(fn) {
      if (remote) cat(".")
      system(concat("echo  >> ", concat(dir,fn)))
      tbl <- load.mon_log(concat(dir,fn))
      bytes <- sum(tbl$len_h)
      t <- tbl$t[which(!is.na(tbl$t))]
      dt <- max(t) - min(t)
      
      #return(c( bytes, dt, bytes/dt))
      return(bytes/dt)
    }) -> val
    return(val)
  }) -> v_val
  colnames(v_val) <- 1:ncol(v_val)
  return(t(v_val))
}
get_dt <- function(tar_fn, dir = tempdir(), remote=FALSE){
  if (remote) cat(".")
  
  sapply(tar_fn, function(tfn){
    if (remote) cat(".")
    system(paste("tar -zxf ", tfn, " --directory ", dir ))
    
    mon_files <- c(list.files(path = dir, pattern = "mon_client_[0-9]*.log"))#, list.files(path = dir, pattern = "mon_server.log")) ## No mon_server yet
    
    sapply(mon_files, function(fn) {
      if (remote) cat(".")
      system(concat("echo  >> ", concat(dir,fn)))
      tbl <- load.mon_log(concat(dir,fn))
      bytes <- sum(tbl$len_h)
      t <- tbl$t[which(!is.na(tbl$t))]
      dt <- max(t) - min(t)
      
      #return(c( bytes, dt, bytes/dt))
      return(dt)
    }) -> val
    return(val)
  }) -> v_val
  colnames(v_val) <- 1:ncol(v_val)
  return(t(v_val))
}
get_bytes <- function(tar_fn, dir = tempdir(), remote = FALSE){
  if (remote) cat(".")
  
  sapply(tar_fn, function(tfn){
    if (remote) cat(".")
    system(paste("tar -zxf ", tfn, " --directory ", dir ))
    
    mon_files <- c(list.files(path = dir, pattern = "mon_client_[0-9]*.log"))#, list.files(path = dir, pattern = "mon_server.log")) ## No mon_server yet
    
    sapply(mon_files, function(fn) {
      if (remote) cat(".")
      system(concat("echo  >> ", concat(dir,fn)))
      tbl <- load.mon_log(concat(dir,fn))
      bytes <- sum(tbl$len_h)
      t <- tbl$t[which(!is.na(tbl$t))]
      dt <- max(t) - min(t)
      
      #return(c( bytes, dt, bytes/dt))
      return(bytes)
    }) -> val
    file.remove(paste(dir,mon_files, sep="/"))
    return(val)
  }) -> v_val
#  if (ncol(v_val) == 0) {
#    print(tfn)
#  } else{
#    colnames(v_val) <- 1:ncol(v_val)
#  }
  return(t(v_val))
}

get_summary <- function(v_fn, dir=tempdir(), names_summary = c("drop", "send","missing","recov", "deliv", "limbo", "inLimbo", "inRER","A1", "A2", "A3" ), remote = FALSE){
  if (remote) cat(".")
  nrow_summary <- length(names_summary)
  
  sapply(v_fn, function(fn){
    tryCatch({
      if (remote) cat(".")
      system(paste("tar -zxf ", fn, " --directory ", dir ))
      mon_files <- list.files(path = dir, pattern = "summary_[0-9]*.log", full.names = TRUE)
      sapply(mon_files, function(fn2){
        line <- read.csv2(fn2, sep=',', header = FALSE)
        #print(line)
      }) -> tbl
      file.remove(list.files(path = dir, pattern = "*.log", full.names = TRUE))
    },warning = function(w) {
      print(fn)
      return(c(NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA))
    }, error = function(e){
      print(fn)
      return(c(NA,NA,NA,NA))
    })
    #print(tbl)
    if (remote) cat(".")
    return(tbl)
  }) -> v_tbl
  #str(v_tbl)
  v_tbl <- data.frame(matrix(v_tbl, nrow = nrow_summary), row.names = names_summary)
  return(v_tbl)
}

get_summary.mean <- function(v_tbl, n=5, remote = FALSE){
  if (remote) cat(".")
  ncol(v_tbl)
  sapply(1:nrow(v_tbl), function(m){
    if (remote) cat(".")
    sapply(0:((ncol(v_tbl)/n)-1), function(i){
      mean(as.numeric(list_pos(v_tbl, m))[((i*n+1):(i*n+n))])
    })
  }) -> val
  colnames(val) <- rownames(v_tbl)
  return(val)
}

#mc.get_all <- function(v_fn, dir=tempdir()){}

get_all <- function(v_fn, dir=tempdir(), debug=F, remote = FALSE){
  if (debug) print(1)
  summary <- get_summary(v_fn, dir, remote)
  if (debug) print(2)
  summary.mean <- get_summary.mean(summary,remote)
  if (debug) print(3)
  bytes <- get_bytes(v_fn, dir, remote)
  if (debug) print(4)
  dt <- get_dt(v_fn, dir, remote)
  if (debug) print(5)
  bandwidth <- get_bandwidth(v_fn, dir, remote)
  if (debug) print(6)
  
  tbl <- list(summary = summary, summary.mean = summary.mean, bytes = bytes, dt = dt, bandwidth = bandwidth, files = v_fn)
  
  
  tbl$summary.mean <- cbind(tbl$summary.mean, add_dt_to_summary(tbl))
  tbl$summary.mean <- cbind(tbl$summary.mean, add_bytes_to_summary(tbl))
  #str_colnames <- c(colnames(tbl$summary.mean),"dt", "bytes")  
  #colnames(tbl$summary.mean) <- str_colnames
  return(tbl)
}

get_filenames <- function(dir="~/Documents/rerval", pattern="", ext="tar.gz"){
  # loss
  # wt
  # ro
  
  # Get all tar.gz files from dir
  v_files <- list.files(path = dir, pattern = ext, full.names = T)
  
  return(v_files[grep(v_files, pattern = pattern)])
  
}

# Makes the mean of the different clients
# if the dt is within 0.1, and 0.9 then it adds them otherwise nope.
add_dt_to_summary <- function(tbl, q=c(0.0, 0.9)){
  lower <- quantile(tbl$dt, probs = q[1])
  upper <- quantile(tbl$dt, probs = q[2])
  
  apply(tbl$dt, 1, function(row) {
    mean(row[row >= lower & row <= upper])
  }) -> x.mean
  return(x.mean)
}

add_bytes_to_summary <- function(tbl, q=c(0.0, 0.9)){
  lower <- quantile(tbl$dt, probs = q[1])
  upper <- quantile(tbl$dt, probs = q[2])
  
  apply(tbl$dt, 1, function(row) {
    which(row >= lower & row <= upper)
  }) -> x.ids
  sapply(1:length(x.ids), function(i){
    mean(tbl$bytes[i, x.ids[[i]] ])
  }) -> x.mean
  return(x.mean)
}
