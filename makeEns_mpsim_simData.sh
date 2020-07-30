#!/bin/bash

modelName=$1
iteration=$2
lastProcessRank=$3
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done) # list of member indices for each array task separated by one space

## Make file with initial ensemble of simulated data in main working directory
paste -d' ' $(printf simData_%d".txt " ${memberIndices[@]}) > ens_of_simulatedData.txt
paste -d' ' $(printf simDataWithNoise_%d".txt " ${memberIndices[@]}) > ens_of_simulatedData_withNoise.txt

## Update file of ensemble of observed data for scaling matrix
paste -d' ' $(printf obsDataWithRegularNoise_%d".txt " ${memberIndices[@]}) > ens_of_origObsData_withRegularNoise.txt # to calculate variance of data


## Make file with ensembles of mp categorical simulations and (initial) pyramids
paste -d' ' $(printf mpsim_%d".txt " ${memberIndices[@]}) > ens_of_MPSim.txt

if [ ${iteration} -eq 0 ]
then
#    cp ens_of_simulatedData.txt iniSimulatedDataEns.txt
    cp ens_of_simulatedData.txt ens_of_simulatedDataEns_0.txt
    cp ens_of_simulatedData_withNoise.txt iniSimulatedDataEnsWithNoise.txt
else
    cp ens_of_MPSim.txt ens_of_MPSim_${iteration}.txt
    paste -d' ' $(printf pyr_%d".txt " ${memberIndices[@]}) > ens_of_updatedPyr.txt
#    paste -d' ' $(printf lev1pyr_%d".txt " ${memberIndices[@]}) > lev1PyrEns.txt
    cp ens_of_updatedPyr.txt ens_of_updatedPyr_${iteration}.txt
    cp ens_of_updatedPyr.txt ens_of_updatedPyr_afterKalman-DS_${iteration}.txt
    cp ens_of_parameters.txt ens_of_parameters_beforeKalman_${iteration}.txt
    
fi
