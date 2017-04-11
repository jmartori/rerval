#CNF_LOSS="0.00 0.005 0.01 tcp"
CNF_LOSS="0.005"
#CNF_WT="1 0.1 0.01"
CNF_WT="1"

CNF_RO="10"
CNF_LOC="sdc"

for ro in $(echo "$CNF_RO" | tr ' ' '\n');
do
	for loc in $(echo "$CNF_LOC" | tr ' ' '\n'); 
	do
		for loss in $(echo "$CNF_LOSS" | tr ' ' '\n'); 
		do
			for wt in $(echo "$CNF_WT" | tr ' ' '\n'); 
			do
				fn=$(echo "$loc-loss_$loss-wt_$wt-ro_$ro-")
				echo $fn
				#nohup Rscript /home/jordi/Documents/rerval/post/process.r $fn & 
				Rscript /home/jordi/Documents/rerval/post/process.r $fn 
			done
		done
	done
done