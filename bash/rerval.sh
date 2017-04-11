#!/bin/bash
test_name=""


update_config()
{
	fn_config_ini="$1"
	attr="$2"
	val="$3"

	sed -i "s/${attr}[ ]*=[ ]*[ .0-9a-zA-Z]*$/${attr} = $val/g" $fn_config_ini
}

nop=1000
update_config "config.ini" numOperations $nop

maxIter=10

#CNF_RO="2 10 20 100"
#CNF_LOC="sdc mdc xdc"
#CNF_WT="1 0.1 0.01"
# CNF_LOSS="0.00 0.005 0.01"
# CNF_WT="0.01"
#CNF_LM="5 10 20 50 100 200"


#DO_YOU_WANT_NTP="YES PLEASE" # To say TRUE
DO_YOU_WANT_NTP="No Thanks" # To say FALSE

CNF_LM="500"
CNF_LOSS="0.00"
CNF_WT="0.01"
CNF_RO="10"
CNF_LOC="mdc"

gliter=1

update_config "config.ini" func_lat_model exponential

# Lambda will change but we dont care...
#update_config "config.ini" func_lat_model exponential
#update_config "config.ini" val_static 1000


for ro in $(echo "$CNF_RO" | tr ' ' '\n');
do
	sp_time=$(echo "2.4*($nop/$ro)" | bc) ## The experiment should be around 500 + extra waiting time and stuff
	update_config "config.ini" rateOperations $ro

	for loc in $(echo "$CNF_LOC" | tr ' ' '\n'); 
	do
		echo "Launch"
		case $loc in
			"sdc")
				update_config "config.ini" MaxEntries 16
				bash/experiment.sh launch 6 >> /dev/null
			;;
			"mdc")
				update_config "config.ini" MaxEntries 16
				bash/experiment.sh geolaunch bash/geo.cnf >> /dev/null
			;;
			"xdc")
				update_config "config.ini" MaxEntries 26
				bash/experiment.sh geolaunch bash/geo_25repl.cnf >> /dev/null
			;;
			*)
				echo "[error] The launch is not good."
				exit 2
			;;
		esac
		sleep 60 
		for iter in $(seq $maxIter);
		do
			for lm in $(echo "$CNF_LM" | tr ' ' '\n');
			do
				# Moved up!
				# update_config "config.ini" func_lat_model exponential
				update_config "config.ini" exp_lambda $lm

				for loss in $(echo "$CNF_LOSS" | tr ' ' '\n'); 
				do
					if [ ! $loss == "tcp" ]; then
			#			update_config "config.ini" enabled True
						update_config "config.ini" p_loss $loss
						update_config "config.ini" SocketType udp
					else
			#			update_config "config.ini" enabled False
						update_config "config.ini" SocketType tcp
						update_config "config.ini" p_loss 0.00
					fi

					for wt in $(echo "$CNF_WT" | tr ' ' '\n'); 
					do
						ts=$(date +%s)
						update_config "config.ini" wt $wt
										
						echo -n "($gliter) Packing "
						bash/experiment.sh packing >> /dev/null

						echo -n "Setup "
						bash/experiment.sh setup >> /dev/null

						if [ "$DO_YOU_WANT_NTP" == "YES PLEASE" ]; then 
							echo -n "PreNTP "
							bash/experiment.sh ntp
						fi

						echo -n "Run "
						sleep 5 && bash/experiment.sh run 
						
						echo -n "Monitor "
						bash/experiment.sh monitor 

						# Long time of waiting
						echo -n "(Now the long wait begins) "
						sleep $sp_time

						if [ "$DO_YOU_WANT_NTP" == "YES PLEASE" ]; then 
							echo -n "PostNTP "
							bash/experiment.sh ntp
						fi

						# Fetch & Clean & Destroy
						echo -n "Fetching "
						bash/experiment.sh fetch "$test_name$loc-lm_exp_$lm-loss_$loss-wt_$wt-ro_$ro-date_$ts".tar.gz

						cat exp_ips.txt >> machines_used.txt

						echo "Rebooting "
						bash/experiment.sh reboot && sleep 60

						let gliter=$gliter+1
					done
				done
			done
		done

		echo "Cleaning"
		bash/experiment.sh destroy >> /dev/null && bash/experiment.sh clean
	done
done
