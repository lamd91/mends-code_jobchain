#!/bin/bash

##------------- SLURM job array to compare the objective function value after and before parameter update --------------##

# Request amount of run time
#SBATCH -t 01:00:00

###############################################################################

## Display information about resource management for job
#echo "Job ID: ${SLURM_ARRAY_JOB_ID}"
#echo "Process rank: ${SLURM_ARRAY_TASK_ID}"
#echo "=============="

# Parse command line arguments
modelName=$1
dataTypes=$2
iteration=$3

homeDirPath=$(pwd)

# Other variables
nbObsPts=$(awk '/OBSERVATION POINTS/{f=1;next} /end/{f=0} f' ${homeDirPath}/$modelName/forgw/gw_tr/*.fed | wc -l) # number of head observation locations

if [ ${iteration} -eq 0 ]
then
    # Compute initial value of objective function
    ./initOF.py $modelName ${SLURM_ARRAY_TASK_ID} $dataTypes
    wait
else
    # Read files
    objFun=$(<objFunMin_${SLURM_ARRAY_TASK_ID}.txt) # contains the minimum objective function value obtained so far

    # Compute objective function before and after update and make changes accordingly
    ./calcOF.py $modelName ${SLURM_ARRAY_TASK_ID} $objFun $dataTypes
    wait
fi

