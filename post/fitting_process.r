#from the fitting.r 

# This gets you the rates summary for all 4 types (Q,S,R,D)
sapply(1:(length(v_l)/2), function(i){
  
  v <- v_l[,i]$ts[,1]
  v <- v[setdiff(1:length(v), which(is.na(v)))]
  rate_q <- 1/mean(diff(v))
  
  v <- v_l[,i]$ts[,2]
  v <- v[setdiff(1:length(v), which(is.na(v)))]
  rate_s <- 1/mean(diff(v))
  
  v <- v_l[,i]$ts[,3]
  v <- v[setdiff(1:length(v), which(is.na(v)))]
  rate_r <- 1/mean(diff(v))
  
  v_d <- apply(v_l[,i]$ts, 1, function(row) ifelse(is.na(row[4]), row[5], row[4]))
  v_d <- v_d[setdiff(1:length(v_d), which(is.na(v_d)))]
  
  rate_d <- 1/mean(diff(v_d))
  
  return(c(rate_q,rate_s,rate_r,rate_d))
}) -> dat

### This gets you the A0, A1, A2, A3
wt <- 0 # This needs to be adquired from the configuration file.
sapply(1:(length(v_l)/2), function(i){
  v <- v_l[,i]$ts[,3]
  v <- v[setdiff(1:length(v), which(is.na(v)))]
  
  a0 <- sum(diff(v) >= 0) +1 # because we use diff we lose the first or last operations.
  
  ids_a1 <- which(diff(v) < 0)
  a1 <- 
  #a2
  #a3
  
})