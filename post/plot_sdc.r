
filter_rules_empty <- function(tbl, ids){
  return(ids)
}

filter_rules_deliv <- function(tbl, ids, p_deliv=0.98, filter_nans=TRUE){
  deliv <- quantile(tbl[ids,5], probs = p_deliv)
  ids <- ids[ids %in% which(tbl[,5] >= deliv)]
  
  if (filter_nans) {
    ids <- filter_rules_nan(tbl, ids)
  }
  
  return(ids)
}

filter_rules_nan <- function(tbl, ids) {
  rows <- nrow(tbl)
  nan_ids <- unique(which(is.nan(tbl)==FALSE) %% rows)
  
  ids <- ids[ids %in% nan_ids]
  
  return(ids)
}

get_tbl_plot <- function(tbl, col, filter_rules = filter_rules_deliv, 
                         str_loss=c("5-","10-","20-","50-","100-","200-"), str_head_loss="-lm_exp", 
                         str_wt=c("0.01-","0.1-","1-", "2-", "5-"), str_head_wt = "-wt", 
                         files
                         #, files = ifelse(class(tbl) == "list", tbl$files, v_files)
                         ){  
  
  sapply(paste(str_head_loss, str_loss, sep="_"), function(pattern_loss){
    ids_loss <- grep(files, pattern = pattern_loss)
    sapply(paste(str_head_wt, str_wt, sep="_"), function(pattern_wt){
      ids_wt <- grep(files, pattern = pattern_wt)  
      ids <- ids_wt[which(ids_wt %in% ids_loss)]
  
      ids <- filter_rules(tbl, ids)
      
      x.mean <- mean(tbl[ids, col])
      return(x.mean)
    })
  }) -> tbl_mean

  return(tbl_mean)
  #return(list(mean=tbl_mean, sd=tbl_sd))
}
get_summary_tbl <- function(ncols=13, ...){
  sapply(1:ncols, function(i) get_tbl_plot(tbl, col = i, str_head_loss = "-lm_exp", str_loss = c("50","100","200"))$mean)
}


get_fp_plot <- function(v, files,
                         str_loss=c("5-","10-","20-","50-","100-","200-"), str_head_loss="-lm_exp", 
                         str_wt=c("0.01-","0.1-","1-", "2-", "5-"), str_head_wt = "-wt",
                        f_mean = mean
                        ){  
  
  sapply(paste(str_head_loss, str_loss, sep="_"), function(pattern_loss){
    ids_loss <- grep(files, pattern = pattern_loss)
    sapply(paste(str_head_wt, str_wt, sep="_"), function(pattern_wt){
      ids_wt <- grep(files, pattern = pattern_wt)  
      ids <- ids_wt[which(ids_wt %in% ids_loss)]
      
      ids_nan <- which(is.na(v))
      
      # with setdiff like this, we remove the ids_nan from ids
      x.mean <- f_mean(v[setdiff(ids, ids_nan)])
      return(x.mean)
    })
  }) -> tbl_mean
  
  return(tbl_mean)
}

