#!/bin/bash
source bash/experiment.cnf

# OUTDATED. SG are created in each region.
create_security_group()
{
 	[ $# -lt 2 ] && echo "Error: I need more arguments. REGION SG-NAME" && return -1
	REGION_ID="$1"
 	REGION_SG="$2"
 	aws ec2 --region $REGION_ID create-security-group --group-name $REGION_SG --description "My SG for experiment 1. SSH + UDP:5005"
 	aws ec2 --region $REGION_ID authorize-security-group-ingress --group-name $REGION_SG --protocol tcp --port 22 --cidr 0.0.0.0/0
 	aws ec2 --region $REGION_ID authorize-security-group-ingress --group-name $REGION_SG --protocol udp --port 5005 --cidr 0.0.0.0/0
 	aws ec2 --region $REGION_ID authorize-security-group-ingress --group-name $REGION_SG --protocol tcp --port 5005 --cidr 0.0.0.0/0
#	aws ec2 --region $REGION_ID authorize-security-group-ingress --group-name $REGION_SG --protocol icmp --port 7 --cidr 0.0.0.0/0
}

create_instance()
{
	[ $# -lt 5 ] && echo "Error: I need more arguments. REGION AMI KEY SG SIZE" && return -1
	VM_REGION="$1"
	VM_AMI="$2"
	VM_KEY="$3"
	VM_SG="$4"
	VM_SIZE="$5"

	aws ec2 --region "$VM_REGION" run-instances --image-id "$VM_AMI" --count 1 --instance-type "$VM_SIZE" --key-name "$VM_KEY" --security-groups "$VM_SG"
	return $?
}

#### Enought functions!!!


# To Create instances

#create_security_group $VM_REGION "segr-icmp"

# not working now.
#create_instance "eu-west-1" "ami-708ec403" "aws_ec2_jmartori_ws1" $REGION_SG "t2.micro" > description.txt
# Do not change from here but from the configuration file that is sourced at the beginning of the script.

# Good for debuging...
# echo "create_instance $VM_REGION $VM_AMI $KEY_REGION $REGION_SG $VM_SIZE > description.txt"
# exit 99

create_instance $VM_REGION $VM_AMI $KEY_REGION $REGION_SG $VM_SIZE > description.txt

instance_id=$(cat description.txt | head -n2 | tail -n1 | awk -F"\t" '{print $8}')
# Wait for the public IP

i=1
f_leave=0
while [[ $f_leave !=  1 ]]; do
	sleep 5
	
	aws ec2 --region $VM_REGION describe-instances --instance $instance_id > instance-id.txt	
	instance_ip=$(cat instance-id.txt | grep ASSOCIATION | head -n1 | awk -F"\t" '{print $4}')
	if [ ${#instance_ip} -gt 5 ]; then
		f_leave=1
		echo "$VM_REGION $instance_id $instance_ip"
	fi

	let i=$i+1
	## We should check that if the f_leave is set, this has to be ignored.
	if [ $i == MAX_RETRY ]; then 
		f_leave=1
		echo "ERROR failed after $MAX_RETRY retries."
	fi
done
rm instance-id.txt description.txt

#launch the experiment as sort of a daemon. It can no be retrieved until it finishes, and the output should be redirected somewhere.
#ssh -t -i ~/.ssh/aws_ec2_jmartori_ws1.pem ubuntu@52.208.137.203  "echo "bash experiment-demo.sh" >> exp.txt && cat exp.txt | at now + 0 minutes"


