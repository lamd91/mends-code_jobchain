#!/bin/bash

modelCalibrated=$1
ensembleSize=$2
((lastProcessRank=ensembleSize-1))
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done) # list of member indices for each array task separated by one space
currentIteration=$3
dataTypes=$4

# Make file of ensemble of simulated data and simulated data at current iteration 

paste -d' ' $(printf simHeads_%d".txt " ${memberIndices[@]}) > hSim_ens_${currentIteration}_${ensembleSize}.txt
paste -d' ' $(printf simFlowrates_%d".txt " ${memberIndices[@]}) > qSim_ens_${currentIteration}_${ensembleSize}.txt


