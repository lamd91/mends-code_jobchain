#!/bin/bash

modelName=$1
lastProcessRank=$2
dataTypes=$3
iteration=$4
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done) # list of member indices for each array task separated by one space

## Make file with ensemble of updated transformed pyramid coarsest level parameters in main working directory

paste -d' ' $(printf transformedPyr1_%d".txt " ${memberIndices[@]}) > ens_of_parameters.txt # ensemble of NST of log K parameters

cp ens_of_parameters.txt ens_of_parameters_${iteration}.txt

