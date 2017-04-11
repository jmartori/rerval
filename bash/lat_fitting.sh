
sleep 30
bash/experiment.sh launch 6
bash/experiment.sh packing

for i in $(seq 10); 
do
	sleep 60
	bash/experiment.sh setup
	bash/experiment.sh setup-ntp
	sleep 600

	bash/experiment.sh ntp
	bash/experiment.sh run
	sleep 240
	bash/experiment.sh ntp

	bash/experiment.sh fetch "obs_sdc-lm_exp_100-wt_0.1-ro_10-date_$(date +%s).tar.gz"
	bash/experiment.sh reboot
done

sleep 15
bash/experiment.sh destroy


