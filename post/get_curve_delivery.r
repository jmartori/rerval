
m <- tbl[,1]$ts

v.r <- ifelse(is.na(m[,3]), ifelse(is.na(m[,6]),NA,m[,6]),m[,3])
v.d <- ifelse(is.na(m[,4]), ifelse(is.na(m[,5]),NA,m[,5]),m[,4])

ids.r <- which(is.na(v.r) == FALSE)
ids.d <- which(is.na(v.d) == FALSE)

ids <- ids.r[ids.r %in% ids.d]

v.delta <- v.d[ids] - v.r[ids]

