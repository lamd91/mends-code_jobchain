#!/bin/bash

modelName=$1
iteration=$2
lastProcessRank=$3
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done) # list of member indices for each array task separated by one space

## Make file with ensemble of updated pyramids

paste -d' ' $(printf pyr_%d".txt " ${memberIndices[@]}) > ens_of_updatedPyr.txt
cp ens_of_updatedPyr.txt ens_of_updatedPyr_${iteration}.txt
cp ens_of_updatedPyr.txt ens_of_updatedPyr_afterKalman_${iteration}.txt
