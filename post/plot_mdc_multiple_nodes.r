
r <- 1

p.n2 <-  get_fp_plot(get_ratios(n2$res, row=r), n2$files, f_mean = median)
p.n3 <-  get_fp_plot(get_ratios(n3$res, row=r), n3$files, f_mean = median)
p.n4 <-  get_fp_plot(get_ratios(n4$res, row=r), n4$files, f_mean = median)
p.n5 <-  get_fp_plot(get_ratios(n5$res, row=r), n5$files, f_mean = median)

matplot(p.n2, type='b', lty = 1)
matplot(p.n3, type='b', lty = 1)
matplot(p.n4, type='b', lty = 1)
matplot(p.n5, type='b', lty = 1)


f <- median
p.n2 <-  get_fp_plot(get_ratios(n5$res, row=1), n5$files, f_mean = f)
p.n3 <-  get_fp_plot(get_ratios(n5$res, row=2), n5$files, f_mean = f)
p.n4 <-  get_fp_plot(get_ratios(n5$res, row=3), n5$files, f_mean = f)
p.n5 <-  get_fp_plot(get_ratios(n5$res, row=4), n5$files, f_mean = f)

matplot(p.n2, type='b', lty = 1)
matplot(p.n3, type='b', lty = 1)
matplot(p.n4, type='b', lty = 1)
matplot(p.n5, type='b', lty = 1)