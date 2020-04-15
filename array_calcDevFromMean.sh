#!/bin/bash

ensembleSize=$1
modelName=$2
dataTypes=$3

homeDirPath=$(pwd)
nbOfElements=$(cat ${homeDirPath}/$modelName/elementCentroids.txt | wc -l)

# Created local working directory on node
mkdir -p /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}/
cd /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}

${homeDirPath}/calcDevFromMean.py $modelName $ensembleSize ${SLURM_ARRAY_TASK_ID} $dataTypes $nbOfElements ${homeDirPath}
wait

cp devFromEnsMeanOfPar_${SLURM_ARRAY_TASK_ID}.txt devFromEnsMeanOfSimData_${SLURM_ARRAY_TASK_ID}.txt devFromEnsMeanOfSimDataWithNoise_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}

