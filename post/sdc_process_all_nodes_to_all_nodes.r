source("fitting.r")
source('counting.r')
source("rerval.r")
source("plot_sdc.r")

files <- get_filenames(dir = "~/Documents/rerval/sdc", pattern = "")
### 5 - 
tbl.1 <- get_vfitting(v_files = files, mc.enabled = TRUE, id_snd = 1, id_rcv = 5)
res.1 <- counting_vall(v_l = tbl.1, files = files, f_count = alt2_counting_all, wt_a0 = 0.0001)

tbl.2 <- get_vfitting(v_files = files, mc.enabled = TRUE, id_snd = 2, id_rcv = 5)
res.2 <- counting_vall(v_l = tbl.2, files = files, f_count = alt2_counting_all, wt_a0 = 0.0001)

tbl.3 <- get_vfitting(v_files = files, mc.enabled = TRUE, id_snd = 3, id_rcv = 5)
res.3 <- counting_vall(v_l = tbl.3, files = files, f_count = alt2_counting_all, wt_a0 = 0.0001)

tbl.4 <- get_vfitting(v_files = files, mc.enabled = TRUE, id_snd = 4, id_rcv = 5)
res.4 <- counting_vall(v_l = tbl.4, files = files, f_count = alt2_counting_all, wt_a0 = 0.0001)

res <- res.1 + res.2 + res.3 + res.4
save(files, tbl.1,tbl.2,tbl.3,tbl.4,res.1,res.2,res.3,res.4, res, file = "sdc_results_all_nodes_to_5.rdata")
