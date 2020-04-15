#!/bin/bash

modelName=$1
lastProcessRank=$2
dataTypes=$3
iteration=$4
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done) # list of member indices for each array task separated by one space


## Make file with initial ensemble of transformed log K parameters in main working directory

paste -d' ' $(printf normalScoreOfPyr1_%d".txt " ${memberIndices[@]}) > ens_of_parameters.txt # ensemble of NST of log K parameters

#cp ens_of_parameters.txt ens_of_parameters_beforeUpdate_${iteration}.txt
cp ens_of_parameters.txt iniParEns.txt


