# dist fitting.
library(parallel)
library(stringr)
pareto.MLE <- function(x) {
  n <- length(x)
  m <- min(x)
  a <- n/sum(log(x)-log(m))
  
  return( c(m,a) )
}

from_line_to_time <- function(line) {
  l <- strsplit(line, " ")
  l <- l[[1]]
  date <- gsub("[^[:alnum:][:blank:]+?&/\\-]", "", l[1])
  time <- gsub("]", "", l[2])
  # Convert date_time to posix or sth
  
  # maybe the %OS didnt work because the time is with a ',' and not a '.'. I'm not sure. but now it does work.
  aux <- strptime(paste(date, time, sep=" "), format = "%Y-%m-%d %H:%M:%S")
  milis <- str_split(time, ",")[[1]][2]
  
  return(aux + as.integer(as.character(milis))/1000)
}

from_line_to_msg <- function(line, type){
  if (type == "Q"){
    str_tail <- gsub(pattern = "[[:alnum:][:punct:]\\s]* \\(Q,", replacement = "", x = line, perl = T)
    str_tail <- gsub(pattern = ")", replacement = "", x = str_tail)
    str_tail <- gsub(pattern = " ", replacement = "", x = str_tail)
    aux <- str_split(str_tail, pattern = ",")
  }
  else{
    if (type == "S"){
      str_tail <- gsub(pattern = "[[:alnum:][:punct:]\\s]* \\(S", replacement = "", x = line, perl = T)
      str_tail <- gsub(pattern = ")", replacement = "", x = str_tail)
      str_tail <- gsub(pattern = " ", replacement = "", x = str_tail)
      aux <- str_split(str_tail, pattern = ",")
    } else {
      if (type == "R"){
        str_tail <- gsub(pattern = "[[:alnum:][:punct:]\\s]* \\(R", replacement = "", x = line, perl = T)
        str_tail <- gsub(pattern = ")", replacement = "", x = str_tail)
        str_tail <- gsub(pattern = " ", replacement = "", x = str_tail)
        aux <- str_split(str_tail, pattern = ",")
      } else {
        if (type == "D"){
          str_tail <- gsub(pattern = "[[:alnum:][:punct:]\\s]* \\(D", replacement = "", x = line, perl = T)
          str_tail <- gsub(pattern = ")", replacement = "", x = str_tail)
          str_tail <- gsub(pattern = " ", replacement = "", x = str_tail)
          aux <- str_split(str_tail, pattern = ",")
        }   
      }
    }
  }

  return(aux)
}

get_times_from_log <- function(fn_snd, fn_rcv, id_snd="1", id_rcv="3", policy, num_msg = 1000){
  
  if (length(policy) == 1 ) {
    v_policy = sapply(1:7, function(i) return(policy))
  }
  # Client_snd
  conn <- file(fn_snd, open="r")
  res_snd <- readLines(conn)
  close(conn)
  
  # Client_rcv
  conn <- file(fn_rcv, open="r")
  res_rcv <- readLines(conn)
  close(conn)
  
  op <- options(digits.secs = 3)
  
  m.ts <- matrix(nrow = num_msg, ncol = 7)
  m.count <- matrix(nrow = num_msg, ncol = 7)
  
  # Process res into tbl
  for (i in 0:(num_msg-1)){
    l <- grep (x=res_snd, sprintf("\\(Q, %s, %d)", id_snd, i) )
    len <- length(l)
    m.count[(i+1),1] <- len
    if (len == 0) {
      m.ts[(i+1),1] <- NA
    } else {
      m.ts[(i+1),1] <- from_line_to_time(res_snd[v_policy[[1]](l)])
    }
    
    l <- grep (x=res_snd, sprintf("\\(S, %s, %d)", id_snd, i))
    len <- length(l)
    m.count[(i+1),2] <- len
    if (len == 0) {
      m.ts[(i+1),2] <- NA
    } else {
      m.ts[(i+1),2] <- from_line_to_time(res_snd[v_policy[[2]](l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(R, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),3] <- len
    if (len == 0) {
      m.ts[(i+1),3] <- NA
    } else {
      m.ts[(i+1),3] <- from_line_to_time(res_rcv[v_policy[[3]](l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(D, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),4] <- len
    if (len == 0) {
      m.ts[i,4] <- NA
    } else {
      m.ts[(i+1),4] <- from_line_to_time(res_rcv[v_policy[[4]](l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(DR, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),5] <- len
    if (len == 0) {
      m.ts[(i+1),5] <- NA
    } else {
      m.ts[(i+1),5] <- from_line_to_time(res_rcv[v_policy[[5]](l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(SR, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),6] <- len
    if (len == 0) {
      m.ts[(i+1),6] <- NA
    } else {
      m.ts[(i+1),6] <- from_line_to_time(res_rcv[v_policy[[6]](l)])
    }
    
    l <- grep (x=res_snd, sprintf("\\(SM, %s, %s, %d)", id_rcv, id_snd, i))
    len <- length(l)
    m.count[(i+1),7] <- len
    if (len == 0) {
      m.ts[(i+1),7] <- NA
    } else {
      m.ts[(i+1),7] <- from_line_to_time(res_snd[v_policy[[7]](l)])
    }
  }
  
  ids <- which(is.na(m.ts) == FALSE)
  m.ts[ids] <- m.ts[ids] - min(m.ts[ids])
  return(list(ts=m.ts, count=m.count))  
}


get_fitting <- function(tfn, dir = tempdir(), policy_dup = min, num_msg = 1000, id_snd = 1, id_rcv = 3){
  system(paste("tar -zxf ", tfn, " --directory ", dir ))
    
  client_files <- list.files(path = dir, pattern = "client_[0-9]*.log", full.names = TRUE)
    
  l <- get_times_from_log(fn_snd = client_files[id_snd], fn_rcv = client_files[id_rcv], policy = policy_dup, num_msg =  num_msg, id_snd = as.character(id_snd), id_rcv = as.character(id_rcv))
    
  file.remove(client_files)
  return(l)
}

get_vfitting <- function(v_files, mc.enabled = FALSE, mc.cores = ifelse(mc.enabled, detectCores(), NA), res.sapplied = TRUE, ...){
  if (mc.enabled){
    mclapply(v_files, mc.cores = mc.cores, function(tfn){
      get_fitting(tfn = tfn, ...)
    }) -> res
    # Converts res to what a sapply would return. (because its a sapply :) )
    if (res.sapplied) {
      res <- sapply(1:length(v_files), function(i) res[[i]])
    }
    return(res)
    # but res needs to be processed or it will be different than sapply res.
  }else{
    sapply(v_files, function(tfn){
      get_fitting(tfn = tfn, ...)
    }) -> res
    return(res)
  }
}
  


#load.fitting <- function(v_fn, dir=tempdir(), names_summary = c("drop", "send","missing","recov", "deliv", "limbo", "inLimbo", "inRER","A1", "A2", "A3" )){
#  nrow_summary <- length(names_summary)
#  
#  sapply(v_fn, function(fn){
#    system(paste("tar -zxf ", fn, " --directory ", dir ))
#    mon_files <- list.files(path = dir, pattern = "ntp_client_[0-9]*.log", full.names = TRUE)
#    sapply(mon_files, function(fn2){
#      ## Probably needs to be different...
#      line <- read.csv2(fn2, sep=',', header = FALSE)
#      #print(line)
#    }) -> tbl
#    file.remove(list.files(path = dir, pattern = "*.log", full.names = TRUE))
#    #print(tbl)
#    return(tbl)
#  }) -> v_tbl
#  #str(v_tbl)
#  v_tbl <- data.frame(matrix(v_tbl, nrow = nrow_summary), row.names = names_summary)
#  return(v_tbl)
#}

get_times_from_log <- function(fn_snd, fn_rcv, id_snd="1", id_rcv="3", policy, num_msg = 1000){
  # Client_snd
  conn <- file(fn_snd, open="r")
  res_snd <- readLines(conn)
  close(conn)
  
  # Client_rcv
  conn <- file(fn_rcv, open="r")
  res_rcv <- readLines(conn)
  close(conn)
  
  op <- options(digits.secs = 3)
  
  m.ts <- matrix(nrow = num_msg, ncol = 7)
  m.count <- matrix(nrow = num_msg, ncol = 7)
  
  # Process res into tbl
  for (i in 0:(num_msg-1)){
    l <- grep (x=res_snd, sprintf("\\(Q, %s, %d)", id_snd, i) )
    len <- length(l)
    m.count[(i+1),1] <- len
    if (len == 0) {
      m.ts[(i+1),1] <- NA
    } else {
      m.ts[(i+1),1] <- from_line_to_time(res_snd[policy(l)])
    }
    
    l <- grep (x=res_snd, sprintf("\\(S, %s, %d)", id_snd, i))
    len <- length(l)
    m.count[(i+1),2] <- len
    if (len == 0) {
      m.ts[(i+1),2] <- NA
    } else {
      m.ts[(i+1),2] <- from_line_to_time(res_snd[policy(l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(R, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),3] <- len
    if (len == 0) {
      m.ts[(i+1),3] <- NA
    } else {
      m.ts[(i+1),3] <- from_line_to_time(res_rcv[policy(l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(D, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),4] <- len
    if (len == 0) {
      m.ts[i,4] <- NA
    } else {
      m.ts[(i+1),4] <- from_line_to_time(res_rcv[policy(l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(DR, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),5] <- len
    if (len == 0) {
      m.ts[(i+1),5] <- NA
    } else {
      m.ts[(i+1),5] <- from_line_to_time(res_rcv[policy(l)])
    }
    
    l <- grep (x=res_rcv, sprintf("\\(SR, %s, %s, %d)", id_snd, id_rcv, i))
    len <- length(l)
    m.count[(i+1),6] <- len
    if (len == 0) {
      m.ts[(i+1),6] <- NA
    } else {
      m.ts[(i+1),6] <- from_line_to_time(res_rcv[policy(l)])
    }
    
    l <- grep (x=res_snd, sprintf("\\(SM, %s, %s, %d)", id_rcv, id_snd, i))
    len <- length(l)
    m.count[(i+1),7] <- len
    if (len == 0) {
      m.ts[(i+1),7] <- NA
    } else {
      m.ts[(i+1),7] <- from_line_to_time(res_snd[policy(l)])
    }
  }
  
  ids <- which(is.na(m.ts) == FALSE)
  m.ts[ids] <- m.ts[ids] - min(m.ts[ids])
  return(list(ts=m.ts, count=m.count))  
}


# Snippet to check if the compressed files are good or not
#aux <- sapply(1:300, function(i) {
#  tryCatch({
#    get_summary.mean(get_summary(v_fn[c(1,i)]))
#  }, warning = function(w){
#    cat("W")
#    cat(i)
#    cat("\n")
#  }, error = function(e){
#    cat("E")
#    cat(i)
#    cat("\n")
#  })
#})