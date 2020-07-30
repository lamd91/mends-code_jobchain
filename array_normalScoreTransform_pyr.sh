#!/bin/bash -l


#------- SLURM job script to run parallelized iterative ensemble smoother (ES) with GW (GWES)  ------#

# Parse command line arguments
modelName=$1
iter=$2
homeDirPath=$(pwd)
nbOfPar=$(cat ${homeDirPath}/iniOrigPyrEns.txt | wc -l)

# Create local working directory on cluster node
mkdir -p /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}/
cd /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}/


# Compute there the Normal Score Transform of each local log K value based on ensemble of realizations (local cumulative distribution function)
rm -f normalScoreOfPyr1_${SLURM_ARRAY_TASK_ID}.txt
${homeDirPath}/nst_pyr.py ${SLURM_ARRAY_TASK_ID} ${nbOfPar} ${iter} ${homeDirPath} # creates iniNormalScoreOfLogK_${SLURM_ARRAY_TASK_ID}.txt file
wait

while [ ! -f normalScoreOfPyr1_${SLURM_ARRAY_TASK_ID}.txt ]
do
    sleep 0.5
done

# Bring back output file to main directory
cp normalScoreOfPyr1_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}



