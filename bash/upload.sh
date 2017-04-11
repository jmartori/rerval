#!/bin/bash

# I dont know why it doesnt work...
VM_SSH_KEY="$HOME/.ssh/keys/aws_ec2_jmartori.pem"

while [ $# -ge 1 ];
do
	scp -i $VM_SSH_KEY rervalCode.tar.gz ubuntu@$1:~/
	shift
done
