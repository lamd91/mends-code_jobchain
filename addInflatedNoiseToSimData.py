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

elif dataType == "h_ss":
	nbObsLocs = int(sys.argv[5])
	data = np.reshape(np.loadtxt('temp_simHeads_' + rank + '.txt'), (-1, nbObsLocs), 'F')[0, :]
	obsErr = np.loadtxt(homeDirPath + '/inflatedObsErr_ssH_' + rank + '.txt')

elif dataType == "dh":
	data = np.loadtxt('simDeltaHeads_' + rank + '.txt') 
	obsErr = np.loadtxt(homeDirPath + '/inflatedObsErr_dh_' + rank + '.txt')

elif dataType == "vdh":
	data = np.loadtxt('simVertHeadDiffs_' + rank + '.txt') 
	obsErr = np.loadtxt(homeDirPath + '/inflatedObsErr_vdh_' + rank + '.txt')

elif dataType == "q":
	data = np.loadtxt('temp_simFlowrates_' + rank +'.txt') # simulated data
	obsErr = np.loadtxt(homeDirPath + '/inflatedObsErr_q_' + rank + '.txt')

elif dataType == "props":
	data = np.loadtxt('props_' + rank +'.txt') # simulated data
	obsErr = np.loadtxt(homeDirPath + '/inflatedObsErr_props_' + rank + '.txt')

# Add noise to synthetic data
nbOfData = len(data) # size of vector of perturbed observations
perturbedData = data # initialize the vector  of perturbed observation matrix with the calibration data
perturbedData = perturbedData + obsErr

if dataType == "h":
	np.savetxt('simHeadsWithNoise_' + rank + '.txt', perturbedData, fmt='%.8e')
	np.savetxt('simHeads_' + rank + '.txt', data, fmt='%.8e')
elif dataType == "h_ss":
	np.savetxt('simSSHeadWithNoise_' + rank + '.txt', perturbedData, fmt='%.8e')
	np.savetxt('simSSHead_' + rank + '.txt', data, fmt='%.8e')
elif dataType == "dh":
	np.savetxt('simDeltaHeadsWithNoise_' + rank + '.txt', perturbedData, fmt='%.4e')
elif dataType == "vdh":
	np.savetxt('simVertHeadDiffsWithNoise_' + rank + '.txt', perturbedData, fmt='%.4e')
elif dataType == "q":
	np.savetxt('simFlowratesWithNoise_' + rank + '.txt', perturbedData, fmt='%.4e')
elif dataType == "props":
	np.savetxt('simPropsWithNoise_' + rank + '.txt', perturbedData, fmt='%.4e')


