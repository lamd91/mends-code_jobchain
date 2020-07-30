#!/bin/bash

modelName=$1 

cd ${modelName}

rm -f sampledCells_xCoord.txt sampledCells_yCoord.txt # remove preexisting file with the hard conditioning point indices

if [ ${modelName} == "model9" ]
then
    ../sampleConditioningLocations.py 
elif [ ${modelName} == "model10" ]
then
    ../sampleConditioningLocations_nearObs.py
else
    exit
fi

while [ ! -f sampledCells_xCoord.txt ] || [ ! -f sampledCells_yCoord.txt ]
do
        sleep 0.5
done





