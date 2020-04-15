#!/bin/bash

lastProcessRank=$1
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done) # list of member indices for each array task separated by one space

## Make file with ensembles of mp categorical simulations and (initial) pyramids
paste -d' ' $(printf mpsim_%d".txt " ${memberIndices[@]}) > ens_of_MPSim.txt
cp ens_of_MPSim.txt iniMPSimEns.txt
cp iniMPSimEns.txt iniMPSimEns_init.txt

paste -d' ' $(printf pyr_%d".txt " ${memberIndices[@]}) > iniOrigPyrEns.txt

