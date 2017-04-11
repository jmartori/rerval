library(stringr)

load.vlog <- function(v_fn){
  sapply(v_fn, function(fn){
    load.log(fn)
  })
}

load.log <- function(fn){
  conn <- file(fn, open="r")
  res <- readLines(conn)
  close(conn)
  # Process res into tbl
  len <- length(res)
  op <- options(digits.secs = 3)
  
  ids <- grep("stats", res)
  q_ids <- grep("\\(Q,", res)
  r_ids <- grep("\\(R,", res)
  d_ids <- grep("\\(D,", res)
  
  d_ids.1 <- grep ("\\(D, 1,", res)
  d_ids.2 <- grep ("\\(D, 2,", res)
  d_ids.3 <- grep ("\\(D, 3,", res)
  d_ids.4 <- grep ("\\(D, 4,", res)
  
  r_ids.1 <- grep ("\\(R, 1,", res)
  r_ids.2 <- grep ("\\(R, 2,", res)
  r_ids.3 <- grep ("\\(R, 3,", res)
  r_ids.4 <- grep ("\\(R, 4,", res)
  
  sr_ids.1 <- grep ("\\(SR, 1,", res)
  sr_ids.2 <- grep ("\\(SR, 2,", res)
  sr_ids.3 <- grep ("\\(SR, 3,", res)
  sr_ids.4 <- grep ("\\(SR, 4,", res)
  
  sm_ids.1 <- grep ("\\(SM, 1,", res)
  sm_ids.2 <- grep ("\\(SM, 2,", res)
  sm_ids.3 <- grep ("\\(SM, 3,", res)
  sm_ids.4 <- grep ("\\(SM, 4,", res)
  
  l_sm_ids_by_node <- list(ids.1 = sm_ids.1, ids.2 = sm_ids.2, ids.3 = sm_ids.3, ids.4 = sm_ids.4)
  l_sr_ids_by_node <- list(ids.1 = sr_ids.1, ids.2 = sr_ids.2, ids.3 = sr_ids.3, ids.4 = sr_ids.4)
  l_r_ids_by_node <- list(ids.1 = r_ids.1, ids.2 = r_ids.2, ids.3 = r_ids.3, ids.4 = r_ids.4)
  l_d_ids_by_node <- list(ids.1 = d_ids.1, ids.2 = d_ids.2, ids.3 = d_ids.3, ids.4 = d_ids.4)
  
  v_time <- as.list(numeric(len))
  dv_time <- numeric(len)
  for (i in 1:len){
    l <- strsplit(res[i], " ")
    l <- l[[1]]
    date <- gsub("[^[:alnum:][:blank:]+?&/\\-]", "", l[1])
    time <- gsub("]", "", l[2])
    # Convert date_time to posix or sth
    
    # maybe the %OS didnt work because the time is with a ',' and not a '.'. I'm not sure. but now it does work.
    aux <- strptime(paste(date, time, sep=" "), format = "%Y-%m-%d %H:%M:%S")
    milis <- str_split(time, ",")[[1]][2]
    
    v_time[[i]] <- aux + as.integer(as.character(milis))/1000
    dv_time[i] <- as.numeric(difftime(v_time[[i]],v_time[[1]], units = "secs"))
  }
  tbl <- list(d_ids = d_ids, r_ids = r_ids, q_ids = q_ids, dv_time = dv_time, lines = res, l_r_ids_by_node = l_r_ids_by_node, l_d_ids_by_node = l_d_ids_by_node, l_sr_ids_by_node = l_sr_ids_by_node, l_sm_ids_by_node = l_sm_ids_by_node)
  return(tbl)
}

# Plot reception Rates to client 1 from clients 2,3,4
# matplot(cbind(diff(tbl.c1$dv_time[tbl.c1$l_r_ids_by_node$ids.2]), diff(tbl.c1$dv_time[tbl.c1$l_r_ids_by_node$ids.3]),diff(tbl.c1$dv_time[tbl.c1$l_r_ids_by_node$ids.4])), type='l', lty=1)


onlyEven <- function(v){
  v[which((v %% 2) == 0)]
}

onlyOdd <- function(v){
  v[which((v %% 2) != 0)]
}

load.mon_log <- function(fn)
{
  conn <- file(fn, open="r")
  res <- readLines(conn)
  close(conn)
  
  sapply( res, function(line){
    v <- str_split(string = gsub(x = line, pattern = ")", replacement=""), pattern = " ")[[1]]
    
    # First and last fields, for time and length
    time <- v[1]
    len <- v[length(v)]
    
    l <- str_split(v[1], pattern = ":")[[1]]
    l <- as.double(l)
    
    time <- l[1]*3600 + l[2]*60 + l[3]
    return (c(time, as.numeric(len)))
  }) -> ret_val
  
  t <- ret_val[1,onlyOdd(1:(length(ret_val[1,])-1))] - ret_val[1,1]
  len_head <- ret_val[2,onlyOdd(1:(length(ret_val[1,])-1))]
  len_msg <- ret_val[2,onlyEven(1:(length(ret_val[1,])-1))]
  
  names(t) <- NULL
  names(len_head) <- NULL
  names(len_msg) <- NULL
  
  return(list(lines = res, t = t, len_h = len_head, len_m = len_msg, data=ret_val))
}