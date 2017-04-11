# Check if we have to run client.py or repl_client.py
if [ -r "config.ini" ]; then
	# That should be only for clean or setup
	CLIENT_SCRIPT=$(cat config.ini | grep "clientScript" | grep -v "#" | awk -F"\"" '{print $2}')
fi
## This script is supposed to be ran in the vm's.
num_ins=$(ps aux | grep "python3" | grep "config.ini" | wc --lines)
num_ins_mon=$(ps aux | grep "tcpdump" | grep -v grep | wc --lines)

case $1 in
	"clean")
		rm -rf *
	;;
	"setup")
		tar -zxf *.tar.gz
	;;
	"run")
		if [ $num_ins -eq 0 ]; then 
			vmId=$(cat vmId)
			if [ $vmId -eq 0 ]; then
				python3 server.py config.ini
			else
				echo -e "Waiting 10 seconds before trying to connect.\nThe server needs to be ready..."
				sleep 10
				echo -e "Launching python3 $CLIENT_SCRIPT config.ini $vmId"
				python3 $CLIENT_SCRIPT config.ini $vmId
				sleep 10
			fi
		fi
	;;
	"log-ntp")
		ntpq -p | grep LOCAL >> ~/ntp_client_$(cat vmId).log
	;;
	"ntp")
		# 0: Install ntp
		sudo apt-get  -qq -y install ntp >> /dev/null
		wget --quiet http://http.us.debian.org/debian/pool/main/n/ntpstat/ntpstat_0.0.0.1-1_amd64.deb
		sudo dpkg -i ntpstat_0.0.0.1-1_amd64.deb >> /dev/null

		

		vmId=$(cat vmId)
		if ! grep "^#server" /etc/ntp.conf >> /dev/null; then
			line=$(sudo grep -n "^server" /etc/ntp.conf | awk -F":" '{print $1}'| tail -n1)
			sudo sed -i "s/^server/#server/g" /etc/ntp.conf
			#echo "Setting up NTP ..." >> /home/ubuntu/ntp.log
			if [ $vmId -eq 0 ]; then
				# server ntp config
				sudo sed -i "${line}ifudge 127.127.1.0 stratum 8" /etc/ntp.conf
				sudo sed -i "${line}iserver 127.127.1.0" /etc/ntp.conf

			else
				#client ntp config
				sudo sed -i "${line}iserver $2" /etc/ntp.conf
			fi

			sudo service ntp restart
		fi

		
	;;
	"monitor")
		if [ $num_ins_mon -eq 0 ]; then 
			vmId=$(cat vmId)
			if [ $vmId -eq 0 ]; then
				sudo tcpdump -i eth0 -v port 5005 > mon_server.log
			else
				sudo tcpdump -i eth0 -v port 5005 > mon_client_$vmId.log
			fi
		fi
	;;
	"init")
		if ! grep "run.sh run" ~/.bashrc >> /dev/null ; then 
			echo "$HOME/run.sh run" >> ~/.bashrc
		fi
	;;
	"sleep")
		## good for debug
		sleep 100
	;;
	*)
		echo "[error] Give me sth useful..."
		echo "run.sh <clean|setup|run>"
esac