source("~/Documents/rerval/post/rerval.r")


argv <- commandArgs(trailingOnly = TRUE)

v_fnn <- get_filenames(pattern=argv[1])

tbl <- get_all(v_fnn)

save(file=paste(argv[1], ".rdata", sep=""), tbl)