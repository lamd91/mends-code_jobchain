#!/bin/bash

ensembleSize=$1
modelName=$2
nbSV_svds2=$3
dataTypes=$4
nbAssimilations=$5

homeDirPath=$(pwd)
nbOfPar=$(cat ${homeDirPath}/ens_of_parameters.txt | wc -l)
nbObsPts=$(awk '/OBSERVATION POINTS/{f=1;next} /end/{f=0} f' ${homeDirPath}/$modelName/forgw/gw_tr/*.fed | wc -l) # number of head observation locations

mkdir -p /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}
#rm -f /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}/*
cd /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID} 
rm -f transformedPyr1_${SLURM_ARRAY_TASK_ID}.txt 

${homeDirPath}/computeGain_esmda-loc_updateNSPyr.py $modelName $ensembleSize ${nbSV_svds2} ${SLURM_ARRAY_TASK_ID} $dataTypes $nbOfPar $nbAssimilations $nbObsPts ${homeDirPath}
wait

while [ ! -f transformedPyr1_${SLURM_ARRAY_TASK_ID}.txt ] || [ ! -f parUpgradeFromDataMismatch_${SLURM_ARRAY_TASK_ID}.txt ]; do sleep 0.2; done
cp transformedPyr1_${SLURM_ARRAY_TASK_ID}.txt parUpgradeFromDataMismatch_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}


