#!/usr/bin/python3

import sys
import myFunctions as myFun
import numpy as np
from numpy.linalg import svd, inv
from scipy.sparse import eye
from scipy.sparse.linalg import svds

### As long as one process is still active

## Set general variables

modelName = sys.argv[1]
nbOfEnsMembers = int(sys.argv[2])  # stores the number of processes
processRank =  sys.argv[3] # string variable corresponding to the rank of the current process
rank = int(processRank)
dataTypes = sys.argv[4]
nbOfElements = int(sys.argv[5])
homeDirPath = sys.argv[6]

parEns = np.loadtxt(homeDirPath + '/ens_of_parameters.txt') # Ensemble Smoother is applied to normal score transformed values of log of parameters (K, S)
par = np.reshape(parEns[:, rank],(-1, 1))	

devFromEnsMeanOfPar = myFun.computeDevFromEnsMean_withoutscaling(nbOfEnsMembers, nbOfElements, par, parEns)
np.savetxt('devFromEnsMeanOfPar_' + processRank + '.txt', devFromEnsMeanOfPar, fmt="%.5e")

## Compute deviation from mean of simulated data

simDataEns = np.loadtxt(homeDirPath + '/ens_of_simulatedData.txt')
simDataEns_withNoise = np.loadtxt(homeDirPath + '/ens_of_simulatedData_withNoise.txt')
nbOfData = simDataEns.shape[0]

simData = np.reshape(simDataEns[:, rank],(nbOfData, 1))
simData_withNoise = np.reshape(simDataEns_withNoise[:, rank],(nbOfData, 1))
devFromEnsMeanOfSimData = myFun.computeDevFromEnsMean_withoutscaling(nbOfEnsMembers, nbOfData, simData, simDataEns)
devFromEnsMeanOfSimData_withNoise = myFun.computeDevFromEnsMean_withoutscaling(nbOfEnsMembers, nbOfData, simData_withNoise, simDataEns_withNoise)
np.savetxt('devFromEnsMeanOfSimData_' + processRank + '.txt', devFromEnsMeanOfSimData, fmt="%.5e")
np.savetxt('devFromEnsMeanOfSimDataWithNoise_' + processRank + '.txt', devFromEnsMeanOfSimData_withNoise, fmt="%.5e")
