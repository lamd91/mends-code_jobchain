#!/usr/bin/python3

# Load libraries
import sys
import numpy as np

modelName = sys.argv[1]
dataType = sys.argv[2]
rank = sys.argv[3]
nbAssimilations = int(sys.argv[4])
homeDirPath = sys.argv[6]

# Load simulated data file 
if dataType == "h":
    nbObsLocs = int(sys.argv[5])
    data = np.reshape(np.loadtxt('temp_simHeads_' + rank + '.txt'), (-1, nbObsLocs), 'F').flatten('F')
    obsErr = np.loadtxt(homeDirPath + '/inflatedObsErr_h_' + rank + '.txt')

elif dataType == "q":
    data = np.loadtxt('temp_simFlowrates_' + rank +'.txt') # simulated data
    obsErr = np.loadtxt(homeDirPath + '/inflatedObsErr_q_' + rank + '.txt')

# Add noise to synthetic data
nbOfData = len(data) # size of vector of perturbed observations
perturbedData = data # initialize the vector  of perturbed observation matrix with the calibration data
perturbedData = perturbedData + obsErr

if dataType == "h":
    np.savetxt('simHeadsWithNoise_' + rank + '.txt', perturbedData, fmt='%.8e')
    np.savetxt('simHeads_' + rank + '.txt', data, fmt='%.8e')
    
elif dataType == "q":
    np.savetxt('simFlowratesWithNoise_' + rank + '.txt', perturbedData, fmt='%.4e')


