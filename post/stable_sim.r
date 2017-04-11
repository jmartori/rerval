#stable_sim
load('function_dependences.rdata')
source("lm.r")

# Explain here this values or you'll forget Jordi.
# Conversio del 5ms, 10ms, 20ms, 50ms, 100ms, 200ms d latency exponencial
# a una lambda k va en segons. 1/(5ms/1000) ...
v_lambda <- c(200,100,50,20,10,5)

# WT (no need to explain, they are easy.)
v_wt <- c(0.01, 0.05, 0.1, 0.2, 0.5, 1, 2, 5)

sapply(v_lambda, function(l){
  res <- mclapply(v_wt, function(wt) run_sim_fp(wt = wt, lambda = l, f_aggregate = median, n_iter = 5, rate_op = 50, wt_c2 = 2*qexp(p=0.7, rate=1/l)), mc.cores = 8)
  return(unlist(res))
}) -> p.sim.med

save(p.sim.med, file="p.sim.med.rdata")

matplot(p.sim.med/5, type='b', lty = 1)
