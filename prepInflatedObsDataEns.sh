#!/bin/bash

##------------- SLURM job array to perturbed observations with noise for ES-MDA--------------##

# Parse command line arguments
modelName=$1
dataTypes=$2
nbAssimilations=$3
ensembleSize=$4

homeDirPath=$(pwd) # path to folder from which script of chained jobs has been executed

mkdir -p /tmp/$USER/es/$modelName/
cd /tmp/$USER/es/$modelName/

# Other variables
nbObsPts=$(awk '/OBSERVATION POINTS/{f=1;next} /end/{f=0} f' ${homeDirPath}/$modelName/forgw/gw_tr/*.fed | wc -l) # number of head observation locations
nbOfFluidBudgets=$(grep "^[^\!]" ${homeDirPath}/$modelName/forgw/gw_tr/*.fed | grep "Layer" | wc -l) # number of flowrate measurement "locations" (group of nodes)

# Create ensemble of perturbed observations for each data type and save the perturbations (i.e. both the 'regular' and 'inflated' gaussian noises in order to compute the ES-MDA update)
${homeDirPath}/addInflatedNoiseToObsDataEns.py $modelName h $nbAssimilations $nbObsPts $ensembleSize ${homeDirPath} # perturbing the synthetic head observations
${homeDirPath}/addInflatedNoiseToObsDataEns.py $modelName q $nbAssimilations $nbObsPts $ensembleSize ${homeDirPath} # perturbing the synthetic flowrate observations

while [[ ! -f inflatedObsErrEns_h.txt && ! -f inflatedObsErrEns_q.txt && ! -f inflatedDataEns_h.txt && ! -f inflatedDataEns_q.txt && ! -f regularlyPerturbedDataEns_h.txt && ! -f regularlyPerturbedDataEns_q.txt ]] 
do
    sleep 0.1
done

cp inflatedObsErrEns_h.txt inflatedObsErrEns_q.txt inflatedDataEns_h.txt inflatedDataEns_q.txt regularlyPerturbedDataEns_h.txt regularlyPerturbedDataEns_q.txt ${homeDirPath}

