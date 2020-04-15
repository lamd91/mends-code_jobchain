#!/bin/bash -l


# Parse command line arguments
modelName=$1
iter=$2
homeDirPath=$(pwd)


# Create local working directory on cluster node
mkdir -p /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}/
cd /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}/

# Compute the Back Transform of the Normal Score Transformed log K value based on ensemble of realizations (local cumulative distribution function)
rm -f pyr_${SLURM_ARRAY_TASK_ID}.txt pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt 
${homeDirPath}/bnst_nsPyr.py ${SLURM_ARRAY_TASK_ID} ${iter} ${homeDirPath} ${modelName} # creates pyr_*.txt file

while [ ! -f pyr_${SLURM_ARRAY_TASK_ID}.txt ] || [ ! -f pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt ]
do
	sleep 0.5
done

# Bring back output file to main directory
rm -f ${homeDirPath}/pyr_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}/pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt
cp pyr_${SLURM_ARRAY_TASK_ID}.txt pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}
while [ ! -s ${homeDirPath}/pyr_${SLURM_ARRAY_TASK_ID}.txt ] || [ ! -s ${homeDirPath}/pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt ]
do
	cp pyr_${SLURM_ARRAY_TASK_ID}.txt pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath} 
done

