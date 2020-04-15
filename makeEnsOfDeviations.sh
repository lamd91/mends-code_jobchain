#!/bin/bash

ensembleSize=$1
((lastProcessRank=ensembleSize-1))
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done) # list of member indices for each array task separated by one space
 
paste -d' ' $(printf devFromEnsMeanOfSimData_%d".txt " ${memberIndices[@]}) > ensOfSimDataDevFromEnsMean.txt
paste -d' ' $(printf devFromEnsMeanOfSimDataWithNoise_%d".txt " ${memberIndices[@]}) > ensOfSimDataWithNoiseDevFromEnsMean.txt
paste -d' ' $(printf devFromEnsMeanOfPar_%d".txt " ${memberIndices[@]}) > ensOfParDevFromEnsMean.txt

wait



