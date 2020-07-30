#!/bin/bash

## SLURM job array script to make ensemble of perturbed observations for assimilation with ES-MDA

# Parse command line arguments
modelName=$1
dataTypes=$2
nbAssimilations=$3

homeDirPath=$(pwd)  # path to folder from which script of chained jobs has been executed

# Go to local directory on allocated node
mkdir -p /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}
cd /tmp/$USER/es/$modelName/member_${SLURM_ARRAY_TASK_ID}/

# Other variables
nbObsPts=$(awk '/OBSERVATION POINTS/{f=1;next} /end/{f=0} f' ${homeDirPath}/$modelName/forgw/gw_tr/*.fed | wc -l) # number of head observation locations
nbOfFluidBudgets=$(grep "^[^\!]" ${homeDirPath}/$modelName/forgw/gw_tr/*.fed | grep "Layer" | wc -l) # number of flowrate measurement "locations" (group of nodes)


# Create perturbed observation vector per member for each data type
${homeDirPath}/addInflatedNoiseToObsData.py $modelName h ${SLURM_ARRAY_TASK_ID} $nbAssimilations $nbObsPts ${homeDirPath} # add gaussian noise to synthetic observations
${homeDirPath}/addInflatedNoiseToObsData.py $modelName q ${SLURM_ARRAY_TASK_ID} $nbAssimilations $nbObsPts ${homeDirPath}

while [[ ! -f obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}.txt && ! -f obsHeads_${SLURM_ARRAY_TASK_ID}.txt && ! -f obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}.txt && ! -f obsFlowrates_${SLURM_ARRAY_TASK_ID}.txt ]] 
do
    sleep 0.1
done


# Prepare observation data file according to type of observations to assimilate (calibration dataset)

if [ $dataTypes == "h" ]
then
    while [[ ! -f obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}.txt && ! -f obsHeads_${SLURM_ARRAY_TASK_ID}.txt ]]; do sleep 0.1; done
    cat obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}.txt > obsDataWithNoise_${SLURM_ARRAY_TASK_ID}.txt
    cat obsHeadsWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt > obsDataWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt
    cat obsHeads_${SLURM_ARRAY_TASK_ID}.txt > obsData4OF_${SLURM_ARRAY_TASK_ID}.txt

elif [ $dataTypes == "h+q" ] 
then
    while [[ ! -f obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}.txt && ! -f obsHeads_${SLURM_ARRAY_TASK_ID}.txt && ! -f obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}.txt && ! -f obsFlowrates_${SLURM_ARRAY_TASK_ID}.txt ]]; do sleep 0.1; done
    cat obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}.txt obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}.txt > obsDataWithNoise_${SLURM_ARRAY_TASK_ID}.txt
    cat obsHeadsWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt obsFlowratesWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt > obsDataWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt
    cat obsHeads_${SLURM_ARRAY_TASK_ID}.txt obsFlowrates_${SLURM_ARRAY_TASK_ID}.txt > obsData4OF_${SLURM_ARRAY_TASK_ID}.txt
fi

i=1
line_start4heads=1
line_start4deltaHeads=1
line_end4heads=37 
rm -f obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}_*  # delete preexisting files

while [ ${i} -le ${nbObsPts} ] 
do
    sed -n ${line_start4heads},${line_end4heads}p obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}.txt > obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}_${i}.txt
    sed -n ${line_start4heads},${line_end4heads}p obsHeadsWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt > obsHeadsWithRegularNoise_${SLURM_ARRAY_TASK_ID}_${i}.txt

    ((line_start4heads=line_start4heads+37))
    ((line_end4heads=line_end4heads+37))
    ((i=i+1))

    while  [ -f obsHeadsWithRegularNoise_${SLURM_ARRAY_TASK_ID}_${i}.txt ] && [ -f obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}_${i}.txt ]; do sleep 0.25; done # safety check
done

j=1
line_start4heads=1
line_end4heads=20
rm -f obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}_* # delete preexisting files

while [ ${j} -le ${nbOfFluidBudgets} ] 
do
    sed -n ${line_start4heads},${line_end4heads}p obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}.txt > obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}_${j}.txt
    sed -n ${line_start4heads},${line_end4heads}p obsFlowratesWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt > obsFlowratesWithRegularNoise_${SLURM_ARRAY_TASK_ID}_${j}.txt
    ((line_start4heads=line_start4heads+20))
    ((line_end4heads=line_end4heads+20))
    ((j=j+1))
    
    while [ -f obsFlowratesWithRegularNoise_${SLURM_ARRAY_TASK_ID}_${i}.txt ] && [ -f obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}_${i}.txt ]; do sleep 0.25; done # safety check
done

# Copy of files created on node to home dir
cp inflatedObsErr*_${SLURM_ARRAY_TASK_ID}.txt obsHeadsWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt obsFlowratesWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt obsHeads_${SLURM_ARRAY_TASK_ID}.txt obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}.txt obsFlowrates_${SLURM_ARRAY_TASK_ID}.txt obsDataWithNoise_${SLURM_ARRAY_TASK_ID}.txt obsDataWithRegularNoise_${SLURM_ARRAY_TASK_ID}.txt obsData4OF_${SLURM_ARRAY_TASK_ID}.txt obsHeadsWithNoise_${SLURM_ARRAY_TASK_ID}_*.txt obsHeadsWithRegularNoise_${SLURM_ARRAY_TASK_ID}_*.txt obsFlowratesWithNoise_${SLURM_ARRAY_TASK_ID}_*.txt obsFlowratesWithRegularNoise_${SLURM_ARRAY_TASK_ID}_*.txt ${homeDirPath}


wait
