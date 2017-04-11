#!/bin/bash
SLEEP_TIME=1
EDATE=$(date +%s)
EWD=$HOME
i=1

while [ $i -lt 10 ];
do
	echo "Iter $i" >> $EWD/file-$EDATE.log
	sleep $SLEEP_TIME
	let i=i+1
done

 #ssh -t -i ~/.ssh/aws_ec2_jmartori_ws1.pem ubuntu@52.208.201.238 "screen -dm bash experiment-demo.sh"