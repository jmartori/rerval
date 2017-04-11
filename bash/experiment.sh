#!/bin/bash
source bash/experiment.cnf

help_launch()
{
	echo "$0 launch <num_instances>"
}

f_destroy()
{
	VM_REGION=$1
	VM_INSTANCE_ID=$2
	aws ec2 --region $VM_REGION terminate-instances --instance-ids $VM_INSTANCE_ID
	#echo "$VM_REGION $VM_INSTANCE_ID"
}

help_destroy()
{
	echo "$0 destroy <file_from_launch>"	
}

help_upload()
{
	echo "$0 upload <file_from_launch> <tar_code>"
}

help_key_error()
{
	echo "[error] Couldnt read SSH key ($1)"
}

help_packing()
{
	echo "$0 packing <file_from_launch> <config.ini>"	
}
help_run()
{
	echo "$0 run <file_from_launch>"
}
help_geolaunch()
{
	echo "$0 geolaunch <geo.cnf>"
}

help_knock()
{
	echo "$0 knock"
}

case $1 in
	"geolaunch")
		#Gets the geo.cnf instead of the number of instances, and creates one instance per region.
		[ $# -lt 2 ] && help_geolaunch && exit 1
		export GEO_LAUNCH="TRUE"
		geo_conf=$2

		cat $geo_conf | while read var;
		do
			line=$(echo $var | grep -v "^#")
			if [ -n "$line" ]; then
				VM_REGION=$(echo $line | awk -F"," '{print $2}')
				VM_AMI=$(echo $line | awk -F"," '{print $3}')
				#echo "$SCRIPT_LAUNCH $VM_REGION $VM_AMI"
				$SCRIPT_LAUNCH $VM_REGION $VM_AMI
			fi
		done > exp_ips.txt
		cat exp_ips.txt

		export GEO_LAUNCH=""
	;;
	"launch")
		[ $# -lt 2 ] && help_launch && exit 1
		num=0
		num_instances=$2
		while [ $num -lt $num_instances ];
		do
			$SCRIPT_LAUNCH
			let num=$num+1
		done > exp_ips.txt
		cat exp_ips.txt
	;;
	"packing")
		# Change the ip of config.ini for the server
		#[ $# -lt 3 ] && help_packing && exit 2
		fn_from_launch="exp_ips.txt"
		fn_config_ini="config.ini"
		
		addr=$(head -n1 $fn_from_launch | awk '{print $3}')
		sed -i "s/ServerAddress[ =.0-9]*$/ServerAddress = $addr/g" $fn_config_ini

		# then creates the tar for upload
		tar -zcf rervalCode.tar.gz $FN_TO_PACK

	;;
	"setup-ntp")
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 51
		fn_from_launch="exp_ips.txt"
		server_ip=$(head -n1 exp_ips.txt | awk '{print $3}')

		# 3bis: run.sh ntp
		cat $fn_from_launch | while read -r line;
		do
			ip=$(echo $line | awk '{print $3}')
			ssh -i $SSH_KEY "ubuntu@${ip}" "bash $RUN_SCRIPT ntp $server_ip" & 1> /dev/null 2>/dev/null
		done
	;;
	"setup")
		#[ $# -lt 2 ] && help_fetch && exit 5
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 51
		fn_from_launch="exp_ips.txt"
		server_ip=$(head -n1 exp_ips.txt | awk '{print $3}')


		vmId=0
		cat $fn_from_launch | while read -r line;
		do
			ip=$(echo $line | awk '{print $3}')
			# 1: Upload run.sh
			# maybe the quiet is too much... 
			scp -q -oStrictHostKeyChecking=no -i $SSH_KEY $PATH_RUN_SCRIPT "ubuntu@${ip}:~/"

			# 2: run.sh clean
			ssh -i $SSH_KEY "ubuntu@${ip}" "bash $RUN_SCRIPT clean" & 1> /dev/null 2>/dev/null
			sleep 5 && scp -q -i $SSH_KEY $PATH_RUN_SCRIPT "ubuntu@${ip}:~/"

			# 3: upload Id
			echo "$vmId" > .vmId
			scp -i $SSH_KEY .vmId "ubuntu@${ip}:~/vmId"
			rm .vmId

			# 4: upload tar
			scp -i $SSH_KEY $TAR_NAME "ubuntu@${ip}:~/"

			# 5: untar
			ssh -i $SSH_KEY "ubuntu@${ip}" "bash $RUN_SCRIPT setup" & 1> /dev/null 2>/dev/null

			# 6: 
			#ssh -i $SSH_KEY "ubuntu@${ip}" "chmod +x $RUN_SCRIPT && bash $RUN_SCRIPT init" & 1> /dev/null 2>/dev/null
			ssh -i $SSH_KEY "ubuntu@${ip}" "chmod +x $RUN_SCRIPT" & 1> /dev/null 2>/dev/null
			# Why there? its convenient...

			# Next Id.
			let vmId=$vmId+1
		done
	;;
	"upload")
		#[ $# -lt 3 ] && help_upload && exit 3
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 31
		fn_from_launch="exp_ips.txt"
		

		cat $fn_from_launch | while read -r line;
		do
			ip=$(echo $line | awk '{print $3}')
			# The while is broken if i run this.
			#ssh -t -t -i $SSH_KEY "ubuntu@${ip}" "echo \"tar -zxf rervalCode.tar.gz >> exp.txt && cat exp.txt | at now + 0 minutes\""
			scp -oStrictHostKeyChecking=no -i $SSH_KEY $TAR_NAME "ubuntu@${ip}:~/"
		done
	;;
	"ntp")
		#[ $# -lt 2 ] && help_run && exit 4
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 41
		# Has the secret to eternal happiness (or just fixing this.)
		fn_from_launch="exp_ips.txt"
		f_head=0

		echo -n "gnome-terminal " > .cmd_to_run
		for ip in $(awk '{print $3}' $fn_from_launch);
		do
			if [ $f_head -eq 0 ]; then
				WND_TITLE="server"
				let f_head=$f_head+1
			else
				WND_TITLE="client_${f_head}"
				let f_head=$f_head+1
			fi
			#echo -n " --tab --title=$WND_TITLE -e \"bash -c 'ssh -i $SSH_KEY ubuntu@${ip}' \" ">> .cmd_to_run
			echo -n " --tab --title=$WND_TITLE -e \"bash -c 'ssh -i $SSH_KEY ubuntu@${ip} ./run.sh log-ntp' \" ">> .cmd_to_run
		done

		eval $(cat .cmd_to_run)
		rm .cmd_to_run
	;;
	"run")
		#[ $# -lt 2 ] && help_run && exit 4
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 41
		# Has the secret to eternal happiness (or just fixing this.)
		fn_from_launch="exp_ips.txt"
		f_head=0

		echo -n "gnome-terminal " > .cmd_to_run
		for ip in $(awk '{print $3}' $fn_from_launch);
		do
			if [ $f_head -eq 0 ]; then
				WND_TITLE="server"
				let f_head=$f_head+1
			else
				WND_TITLE="client_${f_head}"
				let f_head=$f_head+1
			fi
			#echo -n " --tab --title=$WND_TITLE -e \"bash -c 'ssh -i $SSH_KEY ubuntu@${ip}' \" ">> .cmd_to_run
			echo -n " --tab --title=$WND_TITLE -e \"bash -c 'ssh -i $SSH_KEY ubuntu@${ip} ./run.sh run' \" ">> .cmd_to_run
		done

		eval $(cat .cmd_to_run)
		rm .cmd_to_run
	;;
	"ssh")
		#[ $# -lt 2 ] && help_run && exit 4
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 41
		# Has the secret to eternal happiness (or just fixing this.)
		fn_from_launch="exp_ips.txt"
		f_head=0

		echo -n "gnome-terminal " > .cmd_to_ssh
		for ip in $(awk '{print $3}' $fn_from_launch);
		do
			if [ $f_head -eq 0 ]; then
				WND_TITLE="server"
				let f_head=$f_head+1
			else
				WND_TITLE="client_${f_head}"
				let f_head=$f_head+1
			fi
			echo -n " --tab --title=$WND_TITLE -e \"bash -c 'ssh -i $SSH_KEY ubuntu@${ip}' \" ">> .cmd_to_ssh
		done

		eval $(cat .cmd_to_ssh)
		rm .cmd_to_ssh
	;;
	"fetch")
		#[ $# -lt 2 ] && help_fetch && exit 5
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 51
		fn_from_launch="exp_ips.txt"
		
		mkdir .tmp

		cat $fn_from_launch | while read -r line;
		do
			# -q is from --quiet
			ip=$(echo $line | awk '{print $3}')
			scp -q -i $SSH_KEY "ubuntu@${ip}:~/*.log" .tmp/
		done

		ts=$(date +%s)
		cd .tmp/
		cp ../exp_ips.txt ../config.ini ../bash/experiment.cnf ./
		if [ -n "$2" ]; then
			tar -zcf "$2" *.log exp_ips.txt config.ini experiment.cnf
			mv "$2" ../
		else
			tar -zcf "log_$ts.tar.gz" *.log exp_ips.txt config.ini experiment.cnf
			mv "log_$ts.tar.gz" ../
		fi
		
		cd ..
		rm -rf .tmp/

	;;
	"destroy")
		#[ $# -lt 2 ] && help_destroy && exit 6
		fn_experiment="exp_ips.txt"

		cat $fn_experiment | while read -r line
		do
			$SCRIPT_DESTROY $line
		done > output_destroy.txt
		cat output_destroy.txt
	;;
	"reboot")
		#[ $# -lt 2 ] && help_fetch && exit 5
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 51
		fn_from_launch="exp_ips.txt"
		
		cat $fn_from_launch | while read -r line;
		do
			# -q is from --quiet
			ip=$(echo $line | awk '{print $3}')
			ssh -i $SSH_KEY "ubuntu@${ip}" "sudo reboot" & 1> /dev/null 2>/dev/null
		done
	;;
	"knock")
	 	regions=$(aws ec2 describe-regions | awk -F"\t" '{print $3}')
	 	for region in $regions;
	 	do
	 		aws ec2 --region="$region" describe-instances > .tmp-description.txt
	 		var=$(cat .tmp-description.txt | head -n2 | tail -n1 | awk -F"\t" '{print $8" "$10" "$11}')
	 		if [ ${#var} -ne 0 ]; then
	 			grep -e "STATE" .tmp-description.txt | grep -v "REASON" | awk -F"\t" '{print $3}' | grep -v "terminated" > .tmp-terminated
	 			if [ ! $(cat .tmp-terminated | wc --lines) == "0" ] ;then
	 				echo "$region: $var"
	 			fi
	 		fi
	 	done
	 	# -f so that it doesnt complain when .tmp-terminated doesnt exist.
	 	# if all the lengths are 0, it never gets created.
	 	rm -f .tmp-description.txt .tmp-terminated
	;;
	"clean")
		# -f to avoid complains... 
		rm -f exp_ips.txt output_*.txt description.txt instance-id.txt
	;;
	"monitor")
		#[ $# -lt 2 ] && help_run && exit 4
		[ ! -r  $SSH_KEY ] && help_key_error $SSH_KEY && exit 41
		# Has the secret to eternal happiness (or just fixing this.)
		fn_from_launch="exp_ips.txt"
		f_head=0

		echo -n "gnome-terminal " > .cmd_to_mon
		for ip in $(awk '{print $3}' $fn_from_launch);
		do
			if [ $f_head -eq 0 ]; then
				WND_TITLE="server"
				let f_head=$f_head+1
			else
				WND_TITLE="client_${f_head}"
				let f_head=$f_head+1
			fi
			echo -n " --tab --title=$WND_TITLE -e \"bash -c 'ssh -i $SSH_KEY ubuntu@${ip} ./run.sh monitor' \" ">> .cmd_to_mon
		done

		eval $(cat .cmd_to_mon)
		rm .cmd_to_mon
	;;
	"help")
		echo "I know i know... but not here yet. try reading the code."
	;;
	*)
		echo "Wrong parameters. Try $0 help."
	;;
esac