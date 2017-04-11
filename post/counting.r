# if column 1 or 2 have NA then the line is removed.
# if column 4 and 5 have NA then the line is removed ( there is a duplicate in the previous delivery).
# if column 3 and 6 have NA then the line is removed (there is sth wrong). 
filter_tbl <- function(tbl) {
  apply(tbl, 1, function(row){
    if (is.na(row[1]) | is.na(row[2])){
      return(FALSE)
    } else {
      if (is.na(row[4]) && is.na(row[5])){
        return(FALSE)
      } else {
        if (is.na(row[3]) && is.na(row[6])){
          return(FALSE)
        }  
      }
    }
    return(TRUE)
  }) -> ids
  return(tbl[ids,])
}

count_a0 <- function(tbl, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    b <- ifelse(is.na(tbl[i, 3]), ifelse(is.na(tbl[i, 6]), NA , tbl[i, 6]) , tbl[i, 3])
    
    if (is.na(tbl[i-1, 3])) return (FALSE)
    if (is.na(b)) return (TRUE)
    
    return(tbl[i-1, 3] <= b)
    
  }) -> res
  return (sum(res))
}

count_a1 <- function(tbl, wt, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    b <- ifelse(is.na(tbl[i, 3]), ifelse(is.na(tbl[i, 6]), NA , tbl[i, 6]) , tbl[i, 3])
    
    if (is.na(tbl[i-1, 3])) return (FALSE)
    if (is.na(b)) return (TRUE)
    
    return((tbl[i-1, 3] > b) & (tbl[i-1, 3] <= (wt + b))) # Althought b shouldnt have the wt if its from recovery...
    
  }) -> res
  return (sum(res))
}

count_a2 <- function(tbl, wt, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    if (is.na(tbl[i-1, 3])) return (FALSE)
    if (is.na(tbl[i-1, 6])) return (FALSE)
    if (is.na(tbl[i-1, 7])) return (FALSE)
    
    return((tbl[i-1, 3] > tbl[i-1, 7]) & (tbl[i-1,3] < tbl[i-1, 6]))
    
  }) -> res
  return (sum(res))
}

count_a3 <- function(tbl, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    if (is.na(tbl[i-1, 3])) return (TRUE)
    if (is.na(tbl[i-1, 6])) return (FALSE) 
    
    return( tbl[i-1, 3] >= tbl[i-1, 6] )
    
  }) -> res
  return (sum(res))
}

counting_all <- function(tbl, wt, filtered = FALSE){
  
  if(is.numeric(wt) == FALSE) wt <-as.numeric(strsplit(x = strsplit(x = wt, split = "-wt_")[[1]][2], split = '-')[[1]][1])
  
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  a0 <- count_a0(tbl, filtered = TRUE)
  a1 <- count_a1(tbl, wt, filtered = TRUE)
  a2 <- count_a2(tbl, wt, filtered = TRUE)
  a3 <- count_a3(tbl, filtered = TRUE)
  #t <- length(tbl[,1])
  
  if (is.numeric(a0) == FALSE) a0 <- NA
  if (is.numeric(a1) == FALSE) a1 <- NA
  if (is.numeric(a2) == FALSE) a2 <- NA
  if (is.numeric(a3) == FALSE) a3 <- NA
  
  return(c( a0, a1, a2, a3))
}

# alt2_counting_all is better that just counting_all as it only uses information from the operation, and not other operations.
counting_vall <- function(v_l, files, filtered = FALSE, f_count = alt2_counting_all, ...) {
  sapply(1:length(files), function(i) {
    tryCatch({
      f_count(tbl = v_l[,i]$ts, wt = files[i], filtered = filtered, ...)
    }, warning = function(w) {
      print(i)
      return(c(NA,NA,NA,NA))
    }, error = function(e){
      print(i)
      return(c(NA,NA,NA,NA))
    })
  })
}


rates_q <- function(tbl, filtered = FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  v <- tbl[,1]
  ids <- which(is.na(v) == FALSE)
  v <- v[ids]
  
  return(1/mean(diff(v)))
}

# Doesnt contain the missing ones from column 7
rates_s <- function(tbl, filtered = FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  v <- tbl[,2]
  ids <- which(is.na(v) == FALSE)
  v <- v[ids]
  
  return(1/mean(diff(v)))
}


rates_r <- function(tbl, filtered = FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  # if the R is NA we take the SR, else we will ignore it with an NA
  v <- ifelse( is.na(tbl[,3]), ifelse(is.na(tbl[,6]), 0, tbl[,6]) , tbl[,3])
  
  ids <- which(is.na(v) == FALSE)
  v <- v[ids]
  
  return(1/mean(diff(v)))
}

rates_d <- function(tbl, filtered = FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  # if the D is NA we take the DR, else we will ignore it with an NA
  v <- ifelse( is.na(tbl[,4]), ifelse(is.na(tbl[,5]), 0, tbl[,5]) , tbl[,4])
  
  ids <- which(is.na(v) == FALSE)
  v <- v[ids]
  
  return(1/mean(diff(v)))
}

rates_all <- function(tbl, filtered = FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  rq <- rates_q(tbl, filtered = TRUE)
  rs <- rates_s(tbl, filtered = TRUE)
  rr <- rates_r(tbl, filtered = TRUE)
  rd <- rates_d(tbl, filtered = TRUE)
  
  if (is.numeric(rq) == FALSE) rq <- NA
  if (is.numeric(rs) == FALSE) rs <- NA
  if (is.numeric(rr) == FALSE) rr <- NA
  if (is.numeric(rd) == FALSE) rd <- NA
  
  return (c(rq, rs, rr, rd))
}


rates_vall <- function(v_l, filtered = FALSE) {
  sapply(1:ncol(v_l), function(i) {
    tryCatch({
      rates_all(tbl = v_l[,i]$ts, filtered = filtered)
    }, warning = function(w) {
      print(i)
      return(c(NA,NA,NA,NA))
    }, error = function(e){
      print(i)
      return(c(NA,NA,NA,NA))
    })
  })
}

get_ratios <- function(tbl, row = 2){
  if (is.null(nrow(tbl)) == FALSE){
    apply(tbl, 2, function(r) {
      if (sum(is.na(row)) > 0 ) {
        return(NA)
      } else {
        r[row]/sum(r)
      }
    }) -> ret
    return(ret)
  } else {
    # We have only one row in tbl
    return(tbl[row]/sum(tbl))
  }
}


alt_count_a0 <- function(tbl, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    b <- ifelse(is.na(tbl[i, 3]), ifelse(is.na(tbl[i, 6]), NA , tbl[i, 6]) , tbl[i, 3])
    a <- ifelse(is.na(tbl[i-1, 4]), ifelse(is.na(tbl[i-1, 5]), NA , tbl[i-1, 5]) , tbl[i-1, 4])
    
    if (is.na(a)) return (FALSE)
    if (is.na(b)) return (TRUE)
    
    return(a <= b)
    
  }) -> res
  return (sum(res))
}

alt_count_a1 <- function(tbl, wt, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    b <- ifelse(is.na(tbl[i, 3]), ifelse(is.na(tbl[i, 6]), NA , tbl[i, 6]) , tbl[i, 3])
    a <- ifelse(is.na(tbl[i-1, 4]), ifelse(is.na(tbl[i-1, 5]), NA , tbl[i-1, 5]) , tbl[i-1, 4])
    
    if (is.na(a)) return (FALSE)
    if (is.na(b)) return (TRUE)
    
    return((a > b) & (a <= (wt + b))) # Althought b shouldnt have the wt if its from recovery...
    
  }) -> res
  return (sum(res))
}

alt_count_a2 <- function(tbl, wt, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    a <- tbl[i-1, 4]
    c <- tbl[i-1, 7]
    d <- tbl[i-1, 6]
    
    if (is.na(a)) return (FALSE)
    if (is.na(d)) return (FALSE)
    if (is.na(d)) return (FALSE)
    
    return((a > c) & (a < d))
    
  }) -> res
  return (sum(res))
}

alt_count_a3 <- function(tbl, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(2:length(tbl[,1]), function(i){
    a <- tbl[i-1, 3]
    d <- tbl[i-1, 6]
    if (is.na(a)) return (TRUE)
    if (is.na(d)) return (FALSE) 
    
    return( a >= d )
    
  }) -> res
  return (sum(res))
}

alt_counting_all <- function(tbl, wt, filtered = FALSE){
  
  if(is.numeric(wt) == FALSE) wt <-as.numeric(strsplit(x = strsplit(x = wt, split = "-wt_")[[1]][2], split = '-')[[1]][1])
  
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  a0 <- alt_count_a0(tbl, filtered = TRUE)
  a1 <- alt_count_a1(tbl, wt, filtered = TRUE)
  a2 <- alt_count_a2(tbl, wt, filtered = TRUE)
  a3 <- alt_count_a3(tbl, filtered = TRUE)
  #t <- length(tbl[,1])
  
  if (is.numeric(a0) == FALSE) a0 <- NA
  if (is.numeric(a1) == FALSE) a1 <- NA
  if (is.numeric(a2) == FALSE) a2 <- NA
  if (is.numeric(a3) == FALSE) a3 <- NA
  
  return(c( a0, a1, a2, a3))
}

alt2_count_a0 <- function(tbl, filtered=FALSE, wt_a0 = 0.001) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 4])) return (FALSE)
    
    return((tbl[i, 3] + wt_a0) >= tbl[i, 4])
    
  }) -> res
  return (sum(res))
}

alt2_count_a1 <- function(tbl, wt, filtered=FALSE, wt_a0 = 0.001) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
  
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 4])) return (FALSE)
    
    #return(((tbl[i, 3] + wt_a0) < tbl[i, 4]) & ((tbl[i, 3] + wt) >= tbl[i, 4])) 
    return((tbl[i, 3] + wt) >= tbl[i, 4]) 
  }) -> res
  
  sapply(1:length(tbl[,1]), function(i){
    
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 4])) return (FALSE)
    
    #return(((tbl[i, 3] + wt_a0) < tbl[i, 4]) & ((tbl[i, 3] + wt) >= tbl[i, 4])) 
    return((tbl[i, 3] + wt_a0) >= tbl[i, 4]) 
  }) -> res_a0
  
  return (sum(res) - sum(res_a0))
}

alt2_count_a2 <- function(tbl, wt, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 6])) return (FALSE)
    if (is.na(tbl[i, 7])) return (FALSE)
    
    return((tbl[i, 3] > tbl[i, 7]) & (tbl[i,3] < tbl[i, 6]))
    
  }) -> res
  return (sum(res))
}

alt2_count_a3 <- function(tbl, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
    if (is.na(tbl[i, 3])) return (TRUE)
    if (is.na(tbl[i, 6])) return (FALSE) 
    
    return( tbl[i, 3] >= tbl[i, 6] )
    
  }) -> res
  return (sum(res))
}

alt2_counting_all <- function(tbl, wt, filtered = FALSE, wt_a0 = 0.0001){
  
  if(is.numeric(wt) == FALSE) wt <-as.numeric(strsplit(x = strsplit(x = wt, split = "-wt_")[[1]][2], split = '-')[[1]][1])
  
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  a0 <- alt2_count_a0(tbl, filtered = TRUE, wt_a0 = wt_a0)
  a1 <- alt2_count_a1(tbl, wt, filtered = TRUE, wt_a0 = wt_a0)
  a2 <- alt2_count_a2(tbl, wt, filtered = TRUE)
  a3 <- alt2_count_a3(tbl, filtered = TRUE)
  #t <- length(tbl[,1])
  
  if (is.numeric(a0) == FALSE) a0 <- NA
  if (is.numeric(a1) == FALSE) a1 <- NA
  if (is.numeric(a2) == FALSE) a2 <- NA
  if (is.numeric(a3) == FALSE) a3 <- NA
  
  return(c( a0, a1, a2, a3))
}

alt3_count_a0 <- function(tbl, filtered=FALSE, wt_a0 = 0.001) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 4])) return (FALSE)
    
    return((tbl[i, 3] + wt_a0) >= tbl[i, 4])
    
  }) -> res
  return (sum(res))
}

alt3_count_a1 <- function(tbl, wt, filtered=FALSE, wt_a0 = 0.001) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
    
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 4])) return (FALSE)
    
    #return(((tbl[i, 3] + wt_a0) < tbl[i, 4]) & ((tbl[i, 3] + wt) >= tbl[i, 4])) 
    return((tbl[i, 3] + wt) >= tbl[i, 4]) 
  }) -> res
  
  sapply(1:length(tbl[,1]), function(i){
    
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 4])) return (FALSE)
    
    #return(((tbl[i, 3] + wt_a0) < tbl[i, 4]) & ((tbl[i, 3] + wt) >= tbl[i, 4])) 
    return((tbl[i, 3] + wt_a0) >= tbl[i, 4]) 
  }) -> res_a0
  
  return (sum(res) - sum(res_a0))
}

alt3_count_a2 <- function(tbl, wt, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
    if (is.na(tbl[i, 3])) return (FALSE)
    if (is.na(tbl[i, 6])) return (FALSE)
    if (is.na(tbl[i, 7])) return (FALSE)
    
    return((tbl[i, 3] > tbl[i, 7]) & (tbl[i,3] < tbl[i, 6]))
    
  }) -> res
  return (sum(res))
}

alt3_count_a3 <- function(tbl, filtered=FALSE) {
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  sapply(1:length(tbl[,1]), function(i){
    if (is.na(tbl[i, 3])) return (TRUE)
    if (is.na(tbl[i, 6])) return (FALSE) 
    
    return( tbl[i, 3] >= tbl[i, 6] )
    
  }) -> res
  return (sum(res))
}

alt3_counting_all <- function(tbl, wt, filtered = FALSE, wt_a0 = 0.0001){
  
  if(is.numeric(wt) == FALSE) wt <-as.numeric(strsplit(x = strsplit(x = wt, split = "-wt_")[[1]][2], split = '-')[[1]][1])
  
  if (filtered == FALSE) tbl <- filter_tbl(tbl)
  
  a0 <- alt3_count_a0(tbl, filtered = TRUE, wt_a0 = wt_a0)
  a1 <- alt3_count_a1(tbl, wt, filtered = TRUE, wt_a0 = wt_a0)
  a2 <- alt3_count_a2(tbl, wt, filtered = TRUE)
  a3 <- alt3_count_a3(tbl, filtered = TRUE)
  #t <- length(tbl[,1])
  
  if (is.numeric(a0) == FALSE) a0 <- NA
  if (is.numeric(a1) == FALSE) a1 <- NA
  if (is.numeric(a2) == FALSE) a2 <- NA
  if (is.numeric(a3) == FALSE) a3 <- NA
  
  return(c( a0, a1, a2, a3))
}