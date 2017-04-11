temp.dir <- function(path = tempdir(), name_dir){
  v_dir <- paste(tempdir(), name_dir, sep = "/")
  sapply(v_dir, function(d){
    if (dir.exists(d) == FALSE){
      dir.create(d)
    }
  })
  
  return (v_dir)
}